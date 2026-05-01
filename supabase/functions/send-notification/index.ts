import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const RESEND_KEY  = Deno.env.get("RESEND_API_KEY")!
const SUPA_URL    = Deno.env.get("SUPABASE_URL")!
const SUPA_SVCKEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

function chunkArray<T>(arr: T[], size: number): T[][] {
  return Array.from(
    { length: Math.ceil(arr.length / size) },
    (_, i) => arr.slice(i * size, i * size + size)
  )
}

async function processOneAsset(asset: any, supabase: any): Promise<void> {
  const { data: existing } = await supabase
    .from("notification_log")
    .select("id")
    .eq("asset_id", asset.id)
    .eq("notif_type", "warning_3d")
    .gte("sent_at", new Date(Date.now() - 86400000).toISOString())

  if (existing?.length > 0) return

  const { data: { users } } = await supabase.auth.admin.listUsers()
  const user = users.find((u: any) => u.id === asset.user_id)
  if (!user?.email) return

  const daysLeft = Math.ceil(
    (new Date(asset.end_date).getTime() - Date.now()) / 86400000
  )

  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "AssetPulse <noreply@assetpulse.app>",
      to: user.email,
      subject: `⚠️ ${asset.name} — মাত্র ${daysLeft} দিন বাকি`,
      html: `
        <div style="font-family:sans-serif;max-width:500px;margin:0 auto;
                    background:#0A0C10;color:#F1F5F9;padding:24px;border-radius:12px">
          <h2 style="color:#F5C542">⚠️ মেয়াদ শেষ হওয়ার সতর্কতা</h2>
          <p>আপনার <strong>${asset.name}</strong> এর মেয়াদ
             <strong style="color:#EF4444">${daysLeft} দিন</strong> পরে শেষ হবে।</p>
          <p>শেষ তারিখ: <strong>${asset.end_date}</strong></p>
          <p>মাসিক খরচ: <strong>৳${asset.cost}</strong></p>
          <a href="https://assetpulse.app"
             style="display:inline-block;margin-top:16px;padding:12px 28px;
                    background:#6366F1;color:white;border-radius:8px;
                    text-decoration:none;font-weight:700">
            অ্যাপ খুলুন →
          </a>
        </div>
      `,
    }),
  })

  await supabase.from("notification_log").insert({
    user_id:    asset.user_id,
    asset_id:   asset.id,
    notif_type: "warning_3d",
    channel:    "email",
    title:      `${asset.name} — ${daysLeft} দিন বাকি`,
  })
}

serve(async (_req) => {
  const supabase = createClient(SUPA_URL, SUPA_SVCKEY)

  const { data: assets } = await supabase
    .from("assets")
    .select("*")
    .in("status", ["warning", "critical"])
    .is("suspended_at", null)

  if (!assets?.length) {
    return new Response(JSON.stringify({ processed: 0 }), { status: 200 })
  }

  let success = 0, failed = 0
  for (const batch of chunkArray(assets, 10)) {
    const results = await Promise.allSettled(
      batch.map(a => processOneAsset(a, supabase))
    )
    results.forEach(r => r.status === "fulfilled" ? success++ : failed++)
  }

  return new Response(
    JSON.stringify({ success, failed, total: assets.length }),
    { headers: { "Content-Type": "application/json" } }
  )
})
