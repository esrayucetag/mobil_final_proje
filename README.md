## TANITIM VİDEOSU 

# Minchir — Haftalık Planlayıcı (Flutter + Firebase)

Minchir, kullanıcıların **seçtikleri bir tarihten başlayan 7 günlük** plan oluşturmasını sağlayan bir haftalık planlayıcı uygulamasıdır.  
Görevler **zorluk katsayısı (1–5)** ile ağırlıklandırılır, hafta sonunda **puan + etiket + değerlendirme** ile kullanıcıya geri bildirim sunulur.

---

## ✨ Özellikler

### ✅ Kimlik Doğrulama (Firebase Auth)
- E-posta/şifre ile **kayıt olma**
- E-posta/şifre ile **giriş yapma**
- **Şifremi unuttum** (mail ile sıfırlama)
- Tüm kayıtlar **kullanıcıya özel (uid bazlı)** saklanır

### ✅ Haftalık Program Oluşturma
- Kullanıcı haftayı **Pazartesiye bağlı olmadan**, seçtiği tarihten başlatır
- 7 gün için görev ekleme (Zorluk: 1–5)
- Haftalık not yazma (üstteki not alanı)
- “Haftayı Başlat” sonrası:
  - Program sabitlenir
  - Görev ekleme **(+ ikonları) kapanır**
- “Haftayı Bitir”:
  - Sonuç ekranına gider
  - Analizlere kaydedilir

### ✅ Puanlama Sistemi (Minchir’in “fark yaratan” kısmı)
- Toplam 7 günlük skor: **0–100**
- Gün ağırlıkları:
  - 1. gün = **30**
  - 2–6. gün = **12**
  - 7. gün = **10**
  - Toplam = **100**
- Gün puanı hesaplama:
  - `(Tamamlanan görevlerin zorluk toplamı / Günün toplam zorluk toplamı) × Gün ağırlığı`

#### ❌ Kaçırma Cezası (ardışık)
Bir gün içinde görev olup da hiçbir görev tamamlanmadıysa “kaçırılmış gün” sayılır.  
Ardışık kaçırışlarda ceza art arda uygulanır:

- 1. kaçırış: **-15**
- 2. kaçırış: **-7**
- 3. kaçırış: **-4**
- 4. kaçırış: **-2**
- 5. kaçırış: **-1**
- 6. kaçırış: **-1**

> Skor asla negatif gösterilmez, taban **0**’dır.

#### 🔁 Geri Dönüş (Recovery)
Kaçırıştan sonraki ilk başarılı gün, moral/geri dönüş ödülü olarak:
- O günün ağırlığı **2 kat** hesaplanır.

### ✅ Sonuç Ekranı + Kendine Not
- Haftayı bitirince skor ve etiket gösterilir
- Kullanıcı “kendine değerlendirme” yazısı yazar ve kaydedebilir

### ✅ Analizler Sayfası
- Kullanıcının haftaları listelenir (uid bazlı)
- Üstte son haftaları özetleyen mini bar grafik
- Her hafta:
  - Puan + etiket + renk bandı
  - Sağdaki **3 nokta menü**:
    - **Görüntüle** → Haftalık not + kendine not gösterilir
    - **Sil** → motivasyonlu onay mesajı ile silinir

---

## 🏷️ Etiketler (Skora göre)
- 0–20: **Başarısız**
- 20–40: **Küçük Adımlar**
- 40–60: **Yoldasın**
- 60–70: **Yeterli**
- 70–80: **İstikrarlı**
- 80–95: **Başarılı**
- 95–100: **Efsanevi**

---

## 🧱 Teknolojiler
- **Flutter** (Material 3)
- **Firebase Core**
- **Firebase Auth**
- **SharedPreferences** (lokal veri)
- **fl_chart** (grafik)

---

## 📁 Proje Yapısı (Önerilen)
lib/
main.dart
firebase_options.dart
services/
storage_keys.dart
pages/
auth_gate.dart
login_page.dart
register_page.dart
home_page.dart
start_date_page.dart
weekly_note_page.dart
week_result_page.dart
statistics_page.dart
about_page.dart

---

## 🔐 Veri Saklama (Kullanıcıya Özel)
Veriler `SharedPreferences` içinde **uid ile ayrıştırılarak** saklanır.

Örnek key’ler:
- `saved_weeks_<uid>`
- `tasks_<uid>_<weekTitle>`
- `note_<uid>_<weekTitle>`
- `self_note_<uid>_<weekTitle>`
- `started_<uid>_<weekTitle>`
- `finished_<uid>_<weekTitle>`

Bu sayede farklı kullanıcılar aynı cihazda giriş yapsa bile **başka kullanıcının analizlerini göremez**.


________________________________________
## 🧪 Notlar / Bilinen Davranışlar
•	“Off day”: O gün hiç görev yoksa skor etkilenmez (ne + ne -).
•	“Haftayı Başlat” sonrası görev ekleme kapalıdır.
•	“Haftayı Bitir” analize kayıt eder ve sonuç ekranını açar.
________________________________________
## eklenebilecek özellikler
•	Etikete göre animasyonlu sonuç ekranları (confetti, geçiş metinleri)
•	Haftalık ilerleme şeridi (checkbox işaretlendikçe dolan progress)
•	Program kilitleme/yeniden açma yönetimi (test sonrası)
•	Logo + branding
________________________________________
## 👩‍💻 Geliştirici Notu
Minchir’in puanlama sistemi, “başlamak ve geri dönmek” davranışlarını ödüllendirirken,
ardışık kopuşları da abartmadan cezalandıracak şekilde tasarlanmıştır.
Amaç: Kullanıcıyı “mükemmeliyet” baskısı yerine ritim ve istikrara yönlendirmek.
