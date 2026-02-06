class StorageKeys {
  // Haftaların listeleri (kullanıcıya özel)
  static String savedWeeks(String uid) => 'saved_weeks_$uid';
  static String interruptedWeeks(String uid) => 'interrupted_weeks_$uid';

  // Haftaya özel veriler (kullanıcıya özel)
  static String tasks(String uid, String weekTitle) => 'tasks_${uid}_$weekTitle';
  static String note(String uid, String weekTitle) => 'note_${uid}_$weekTitle'; // üstteki haftalık not
  static String selfNote(String uid, String weekTitle) => 'self_note_${uid}_$weekTitle'; // kendine not
  static String started(String uid, String weekTitle) => 'started_${uid}_$weekTitle';
  static String finished(String uid, String weekTitle) => 'finished_${uid}_$weekTitle';

  // Analiz snapshot (hafta bitince kaydedilir)
  static String resultScore(String uid, String weekTitle) => 'result_score_${uid}_$weekTitle';
  static String resultLabel(String uid, String weekTitle) => 'result_label_${uid}_$weekTitle';
  static String finishedAt(String uid, String weekTitle) => 'finished_at_${uid}_$weekTitle';

  // Hafta sonu değerlendirme yazısı (result sayfasında)
  static String review(String uid, String weekTitle) => 'review_${uid}_$weekTitle';
}
