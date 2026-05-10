/// FEAT-3 — On-device auto-categorization.
/// Pure Dart keyword matcher. No external API, no ML.
///
/// Usage:
///   final hint = AutoCategory.suggest(name);
///   if (hint != null) { categoryCtl.text = hint.category; icon = hint.icon; }
class CategoryHint {
  final String category;
  final String icon;
  const CategoryHint(this.category, this.icon);
}

class AutoCategory {
  /// Lowercase keyword → (category, icon).
  /// Order matters — first match wins; put more specific keys before generic ones.
  static const Map<String, CategoryHint> _map = {
    // Streaming / entertainment
    'netflix':       CategoryHint('বিনোদন',     '🎬'),
    'youtube':       CategoryHint('বিনোদন',     '▶️'),
    'prime video':   CategoryHint('বিনোদন',     '📺'),
    'amazon prime':  CategoryHint('বিনোদন',     '📺'),
    'hotstar':       CategoryHint('বিনোদন',     '🎬'),
    'disney':        CategoryHint('বিনোদন',     '🏰'),
    'hbo':           CategoryHint('বিনোদন',     '🎬'),

    // Music
    'spotify':       CategoryHint('সংগীত',      '🎵'),
    'apple music':   CategoryHint('সংগীত',      '🎵'),
    'gaana':         CategoryHint('সংগীত',      '🎵'),

    // VPN / security
    'nordvpn':       CategoryHint('নিরাপত্তা',  '🛡️'),
    'expressvpn':    CategoryHint('নিরাপত্তা',  '🛡️'),
    'vpn':           CategoryHint('নিরাপত্তা',  '🛡️'),
    '1password':     CategoryHint('নিরাপত্তা',  '🔐'),
    'lastpass':      CategoryHint('নিরাপত্তা',  '🔐'),

    // Health / fitness
    'gym':           CategoryHint('স্বাস্থ্য',  '🏋️'),
    'fitness':       CategoryHint('স্বাস্থ্য',  '💪'),
    'medicine':      CategoryHint('স্বাস্থ্য',  '💊'),
    'ঔষধ':           CategoryHint('স্বাস্থ্য',  '💊'),
    'doctor':        CategoryHint('স্বাস্থ্য',  '🩺'),

    // Household utilities
    'gas':           CategoryHint('গৃহস্থালি',  '🔥'),
    'গ্যাস':          CategoryHint('গৃহস্থালি',  '🔥'),
    'cylinder':      CategoryHint('গৃহস্থালি',  '🛢️'),
    'electric':      CategoryHint('গৃহস্থালি',  '⚡'),
    'বিদ্যুৎ':        CategoryHint('গৃহস্থালি',  '⚡'),
    'water':         CategoryHint('গৃহস্থালি',  '💧'),
    'পানি':          CategoryHint('গৃহস্থালি',  '💧'),

    // Internet / telecom
    'internet':      CategoryHint('ইন্টারনেট',  '🌐'),
    'wifi':          CategoryHint('ইন্টারনেট',  '📶'),
    'broadband':     CategoryHint('ইন্টারনেট',  '🌐'),
    'mobile':        CategoryHint('টেলিকম',     '📱'),
    'sim':           CategoryHint('টেলিকম',     '📱'),
    'recharge':      CategoryHint('টেলিকম',     '📱'),
    'minute':        CategoryHint('টেলিকম',     '📞'),
    'data pack':     CategoryHint('টেলিকম',     '📡'),

    // Work / SaaS
    'canva':         CategoryHint('কাজ',        '🎨'),
    'adobe':         CategoryHint('কাজ',        '🖌️'),
    'figma':         CategoryHint('কাজ',        '🎨'),
    'github':        CategoryHint('কাজ',        '💻'),
    'jetbrains':     CategoryHint('কাজ',        '⌨️'),
    'office 365':    CategoryHint('কাজ',        '🖥️'),
    'microsoft':     CategoryHint('কাজ',        '🖥️'),
    'google one':    CategoryHint('কাজ',        '☁️'),
    'cloud':         CategoryHint('কাজ',        '☁️'),
    'icloud':        CategoryHint('কাজ',        '☁️'),
    'chatgpt':       CategoryHint('কাজ',        '🤖'),
    'claude':        CategoryHint('কাজ',        '🤖'),

    // Food / groceries
    'rice':          CategoryHint('খাবার',      '🍚'),
    'চাল':           CategoryHint('খাবার',      '🍚'),
    'oil':           CategoryHint('খাবার',      '🛢️'),
    'তেল':           CategoryHint('খাবার',      '🛢️'),
    'sugar':         CategoryHint('খাবার',      '🍬'),
    'চিনি':          CategoryHint('খাবার',      '🍬'),

    // Transport
    'fuel':          CategoryHint('যানবাহন',    '⛽'),
    'petrol':        CategoryHint('যানবাহন',    '⛽'),
    'octane':        CategoryHint('যানবাহন',    '⛽'),
    'cng':           CategoryHint('যানবাহন',    '🚗'),
    'uber':          CategoryHint('যানবাহন',    '🚕'),
    'pathao':        CategoryHint('যানবাহন',    '🛵'),

    // Education
    'course':        CategoryHint('শিক্ষা',     '📚'),
    'tuition':       CategoryHint('শিক্ষা',     '📚'),
    'টিউশন':         CategoryHint('শিক্ষা',     '📚'),
    'school':        CategoryHint('শিক্ষা',     '🏫'),
    'udemy':         CategoryHint('শিক্ষা',     '🎓'),
    'coursera':      CategoryHint('শিক্ষা',     '🎓'),
  };

  /// Returns null if no keyword matches.
  /// Match is case-insensitive substring containment.
  static CategoryHint? suggest(String name) {
    if (name.trim().isEmpty) return null;
    final lower = name.toLowerCase();
    for (final entry in _map.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
