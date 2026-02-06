class StorageKeys {
  // Kullanıcıya özel listeler
  static String savedWeeks(String uid) => 'saved_weeks_$uid';
  static String interruptedWeeks(String uid) => 'interrupted_weeks_$uid';
  static String finishedWeeks(String uid) => 'finished_weeks_$uid';

  // Aktif hafta (tek değer)
  static String activeWeek(String uid) => 'active_week_$uid';

  // Haftaya özel veriler
  static String tasks(String uid, String weekTitle) =>
      'tasks_${uid}_$weekTitle';
  static String weeklyNote(String uid, String weekTitle) =>
      'note_${uid}_$weekTitle'; // üstteki not
  static String selfNote(String uid, String weekTitle) =>
      'self_note_${uid}_$weekTitle'; // kendine not
  static String started(String uid, String weekTitle) =>
      'started_${uid}_$weekTitle';

  // Bitiş / analiz
  static String finished(String uid, String weekTitle) =>
      'finished_${uid}_$weekTitle';
  static String finalScore(String uid, String weekTitle) =>
      'final_score_${uid}_$weekTitle';
  static String finalLabel(String uid, String weekTitle) =>
      'final_label_${uid}_$weekTitle';
}
