class AppDateUtils {
  static String formatElapsed(Duration d) {
    if (d.inDays > 0) return '${d.inDays} দিন ${d.inHours % 24} ঘণ্টা';
    if (d.inHours > 0) return '${d.inHours} ঘণ্টা ${d.inMinutes % 60} মিনিট';
    return '${d.inMinutes} মিনিট';
  }

  static String formatRemaining(Duration d) {
    if (d.isNegative) return 'মেয়াদ শেষ';
    if (d.inDays > 0) {
      return '${d.inDays} দিন ${d.inHours % 24} ঘণ্টা ${d.inMinutes % 60} মিনিট বাকি';
    }
    if (d.inHours > 0) return '${d.inHours} ঘণ্টা ${d.inMinutes % 60} মিনিট বাকি';
    return '${d.inMinutes} মিনিট বাকি';
  }

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String monthName(int month) {
    const names = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    return names[month - 1];
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    return '${diff.inDays} দিন আগে';
  }
}
