import 'package:flutter/material.dart';

import 'package:smartbunda/models/app_user.dart';
import 'package:smartbunda/models/pregnancy.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  bool get isMalay => locale.languageCode == 'ms';

  String t(String english) {
    if (!isMalay) return english;
    return _ms[english] ?? english;
  }

  String hi(String name) => isMalay ? 'Hai, $name' : 'Hi, $name';

  String roleLabel(UserRole role) {
    if (!isMalay) return role.label;
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.doctor:
        return 'Doktor';
      case UserRole.nurse:
        return 'Jururawat';
      case UserRole.patient:
        return 'Pesakit';
      case UserRole.dietitian:
        return 'Pakar Diet';
    }
  }

  String trimesterLabel(Trimester trimester) {
    if (!isMalay) {
      switch (trimester) {
        case Trimester.first:
          return 'First';
        case Trimester.second:
          return 'Second';
        case Trimester.third:
          return 'Third';
      }
    }
    switch (trimester) {
      case Trimester.first:
        return 'Pertama';
      case Trimester.second:
        return 'Kedua';
      case Trimester.third:
        return 'Ketiga';
    }
  }

  String get logoutTooltip => isMalay ? 'Log keluar' : 'Logout';
  String get logoutTitle => isMalay ? 'Log keluar?' : 'Log out?';
  String get logoutMessage => isMalay
      ? 'Adakah anda pasti mahu log keluar?'
      : 'Are you sure you want to log out?';
  String get no => isMalay ? 'Tidak' : 'No';
  String get yesLogOut => isMalay ? 'Ya, log keluar' : 'Yes, log out';
  String get educationTooltip => isMalay ? 'Pendidikan' : 'Education';

  String get navOverview => isMalay ? 'Ringkasan' : 'Overview';
  String get navLog => 'Log';
  String get navAppointments => isMalay ? 'Temu janji' : 'Appointments';
  String get navReports => isMalay ? 'Laporan' : 'Reports';
  String get navProfile => isMalay ? 'Profil' : 'Profile';
  String get navPatients => isMalay ? 'Pesakit' : 'Patients';
  String get navAnalysis => isMalay ? 'Analisis' : 'Analysis';
  String get navPlans => isMalay ? 'Pelan' : 'Plans';
  String get navMonitoring => isMalay ? 'Pemantauan' : 'Monitoring';
  String get navAdmin => 'Admin';
  String get navData => 'Data';
  String get navReport => isMalay ? 'Laporan' : 'Report';
  String get navModules => isMalay ? 'Modul' : 'Modules';

  String get profileTitle => isMalay ? 'Profil' : 'Profile';
  String get profileSubtitle => isMalay
      ? 'Semak status anda dan kemas kini butiran bila perlu.'
      : 'Review your outcomes and update details when needed.';
  String get edit => isMalay ? 'Kemas kini' : 'Edit';
  String get editProfile => isMalay ? 'Kemas kini profil' : 'Edit profile';
  String get noProfileYet =>
      isMalay ? 'Profil belum tersedia' : 'No profile yet';
  String get noProfileMessage => isMalay
      ? 'Lengkapkan profil anda untuk dapatkan sasaran diperibadikan.'
      : 'Complete your profile to unlock personalized targets.';
  String get outcomes => isMalay ? 'Status' : 'Outcomes';
  String get details => isMalay ? 'Butiran' : 'Details';
  String get medicalConditions =>
      isMalay ? 'Keadaan perubatan' : 'Medical conditions';
  String get pregnancy => isMalay ? 'Kehamilan' : 'Pregnancy';
  String get pregnancyNotSet => isMalay
      ? 'Maklumat kehamilan belum ditetapkan.'
      : 'Pregnancy details not set yet.';
  String get gestationalWeek =>
      isMalay ? 'Minggu kehamilan' : 'Gestational week';
  String get trimester => isMalay ? 'Trimester' : 'Trimester';
  String get week => isMalay ? 'Minggu' : 'Week';
  String get edd => isMalay ? 'Tarikh jangka lahir' : 'EDD';
  String get riskLevel => isMalay ? 'Tahap risiko' : 'Risk level';
  String get dateOfBirth => isMalay ? 'Tarikh lahir' : 'Date of birth';
  String get height => isMalay ? 'Tinggi' : 'Height';
  String get weight => isMalay ? 'Berat' : 'Weight';
  String get hemoglobin => isMalay ? 'Hemoglobin' : 'Hemoglobin';
  String get abdominalCircumference =>
      isMalay ? 'Lilitan abdomen' : 'Abdominal circumference';
  String get bloodType => isMalay ? 'Jenis darah' : 'Blood type';
  String get noneReported => isMalay ? 'Tiada dilaporkan' : 'None reported';

  String get accountTitle => isMalay ? 'Akaun' : 'Account';
  String get accountSubtitle => isMalay
      ? 'Urus butiran profil dan tetapan peranan anda.'
      : 'Manage your profile details and role settings.';
  String get accountReviewSubtitle => isMalay
      ? 'Semak butiran akaun dan peranan anda.'
      : 'Review your account details and role.';
  String get signInToViewProfile => isMalay
      ? 'Sila log masuk untuk melihat profil anda.'
      : 'Please sign in to view your profile.';
  String get signInToEditProfile => isMalay
      ? 'Sila log masuk untuk kemas kini profil anda.'
      : 'Please sign in to edit your profile.';
  String get patientProfileTitle =>
      isMalay ? 'Profil pesakit' : 'Patient profile';
  String get patientProfileSubtitle => isMalay
      ? 'Lengkapkan butiran anda untuk peribadikan sasaran pemakanan.'
      : 'Complete your details to personalize nutrition targets.';
  String get dobLabel =>
      isMalay ? 'Tarikh lahir (YYYY-MM-DD)' : 'Date of birth (YYYY-MM-DD)';
  String get heightLabel => isMalay ? 'Tinggi (cm)' : 'Height (cm)';
  String get weightLabel => isMalay ? 'Berat (kg)' : 'Weight (kg)';
  String get hemoglobinLabel =>
      isMalay ? 'Hemoglobin (g/dL)' : 'Hemoglobin (g/dL)';
  String get abdominalCircumferenceLabel =>
      isMalay ? 'Lilitan abdomen (cm)' : 'Abdominal circumference (cm)';
  String get bmiLabel => 'BMI';
  String get bloodTypeLabel => isMalay ? 'Jenis darah' : 'Blood type';
  String get anemiaLabel => 'Anemia';
  String get gdmLabel => isMalay ? 'Diabetes gestasi' : 'Gestational diabetes';
  String get pregnancyModuleNote => isMalay
      ? 'Profil kehamilan pesakit diurus melalui modul profil pesakit.'
      : 'Patient pregnancy profiles are managed on the patient profile module.';
  String get pregnancySectionTitle => isMalay ? 'Kehamilan' : 'Pregnancy';
  String get gestationalWeekLabel =>
      isMalay ? 'Minggu kehamilan' : 'Gestational week';
  String get lmpLabel => isMalay
      ? 'Hari pertama haid terakhir (HPHT)'
      : 'First day of last period (LMP)';
  String get lmpHelper => isMalay
      ? 'Minggu kehamilan & tarikh jangka lahir dikira secara automatik.'
      : 'Gestational week & due date are calculated automatically.';
  String get lmpFutureError => isMalay
      ? 'Tarikh tidak boleh pada masa hadapan.'
      : 'The date cannot be in the future.';
  String weeksValue(int weeks) =>
      isMalay ? '$weeks minggu' : '$weeks weeks';
  String get trimesterLabelText => isMalay ? 'Trimester' : 'Trimester';
  String get trimester1 => 'Trimester 1';
  String get trimester2 => 'Trimester 2';
  String get trimester3 => 'Trimester 3';
  String get eddLabel =>
      isMalay ? 'Tarikh jangka lahir (YYYY-MM-DD)' : 'EDD (YYYY-MM-DD)';
  String get pickDateTooltip => isMalay ? 'Pilih tarikh' : 'Pick date';
  String get riskLevelLabel => isMalay ? 'Tahap risiko' : 'Risk level';
  String get saveProfile => isMalay ? 'Simpan profil' : 'Save profile';
  String get profileSaved => isMalay ? 'Profil disimpan' : 'Profile saved';
  String saveFailed(String message) =>
      isMalay ? 'Simpan gagal: $message' : 'Save failed: $message';
  String unableToAccessMedia(String message) => isMalay
      ? 'Tidak dapat akses media: $message'
      : 'Unable to access media: $message';
  String errorLoadingContent(String message) => isMalay
      ? 'Ralat memuat kandungan: $message'
      : 'Error loading content: $message';
  String errorLoadingReports(String message) => isMalay
      ? 'Ralat memuat laporan: $message'
      : 'Error loading reports: $message';
  String savedAtLabel(DateTime date) =>
      isMalay ? 'Disimpan ${date.toLocal()}' : 'Saved ${date.toLocal()}';
  String reportFor(String name) => isMalay ? 'Laporan: $name' : 'Report: $name';
  String entriesLogged(int count) =>
      isMalay ? 'Log direkod: $count' : 'Entries logged: $count';
  String totalCaloriesLogged(int total) => isMalay
      ? 'Jumlah kalori direkod: $total'
      : 'Total calories logged: $total';
  String targetsSummary(int calories, int protein) => isMalay
      ? 'Sasaran: $calories kcal, $protein g'
      : 'Targets: $calories kcal, $protein g';
  String complianceLast7Days(String percent) => isMalay
      ? '$percent% pematuhan (7 hari terakhir)'
      : '$percent% compliance (last 7 days)';
  String dateLabel(String date) => isMalay ? 'Tarikh: $date' : 'Date: $date';
  String withProvider(String role, String name) =>
      isMalay ? '$role dengan $name' : '$role with $name';
  String patientLabel(String name) =>
      isMalay ? 'Pesakit: $name' : 'Patient: $name';
  String appointmentScheduled(String date, String provider) => isMalay
      ? 'Temu janji dijadualkan pada $date bersama $provider.'
      : 'Appointment scheduled on $date with $provider.';
  String get noMealsLoggedToday => isMalay
      ? 'Tiada makanan direkod hari ini. Tambah pengambilan untuk penjejakan tepat.'
      : 'No meals logged today. Add your intake for accurate tracking.';
  String caloriesBelowMinimum(int min) => isMalay
      ? 'Kalori hari ini di bawah sasaran minimum ($min kcal).'
      : 'Today\'s calories are below the minimum target ($min kcal).';
  String caloriesAboveMaximum(int max) => isMalay
      ? 'Kalori hari ini melebihi sasaran maksimum ($max kcal).'
      : 'Today\'s calories exceed the max target ($max kcal).';
  String proteinBelowTarget(int min) => isMalay
      ? 'Protein di bawah sasaran ($min g).'
      : 'Protein is below the target ($min g).';
  String ironBelowTarget(int min) => isMalay
      ? 'Pengambilan zat besi di bawah $min mg.'
      : 'Iron intake is below $min mg.';
  String folateBelowTarget(int min) => isMalay
      ? 'Pengambilan folat di bawah $min mcg.'
      : 'Folate intake is below $min mcg.';
  String upcomingAppointment(String date, String time) => isMalay
      ? 'Temu janji akan datang pada $date jam $time.'
      : 'Upcoming appointment on $date at $time.';
  String todayWithDate(String date) =>
      isMalay ? 'Hari ini $date' : 'Today $date';
  String notificationsCount(int count) =>
      isMalay ? '$count notifikasi' : '$count notifications';
  String ratingValue(int rating) =>
      isMalay ? 'Penilaian: $rating/5' : 'Rating: $rating/5';
  String fromUser(String name) => isMalay ? 'Daripada: $name' : 'From: $name';
  String get heightWeightNumberError => isMalay
      ? 'Tinggi dan berat mestilah nombor.'
      : 'Height and weight must be numbers.';
  String get weekNumberError => isMalay
      ? 'Minggu kehamilan mestilah nombor.'
      : 'Gestational week must be a number.';
  String get eddInvalidError => isMalay
      ? 'Tarikh jangka lahir mesti tarikh sah (YYYY-MM-DD).'
      : 'EDD must be a valid date (YYYY-MM-DD).';
  String get weekRangeError =>
      isMalay ? 'Minggu mestilah 1 hingga 42' : 'Week must be 1 to 42';
  String get useYmd => isMalay ? 'Gunakan YYYY-MM-DD' : 'Use YYYY-MM-DD';
  String get invalidDate => isMalay ? 'Tarikh tidak sah' : 'Invalid date';
  String get requiredField => isMalay ? 'Wajib' : 'Required';
  String get numberField => isMalay ? 'Nombor' : 'Number';

  String get languageTitle => isMalay ? 'Bahasa' : 'Language';
  String get languageLabel => isMalay ? 'Bahasa aplikasi' : 'App language';
  String get englishLabel => isMalay ? 'Bahasa Inggeris' : 'English';
  String get malayLabel => 'Bahasa Melayu';

  String viewingDay(String dayLabel) =>
      isMalay ? 'Lihat: $dayLabel' : 'Viewing: $dayLabel';
  String daysAgo(int days) => isMalay ? '$days hari lepas' : '$days days ago';
  String entriesForDay(String dayLabel) =>
      isMalay ? 'Rekod ($dayLabel)' : 'Entries ($dayLabel)';
  String basedOnTrimester(String conditionNote) => isMalay
      ? 'Berdasarkan trimester anda$conditionNote.'
      : 'Based on your trimester$conditionNote.';
  String conditionsLabel(String labels) =>
      isMalay ? ' (keadaan: $labels)' : ' (conditions: $labels)';
  String logsCount(int count) => isMalay ? '$count log' : '$count logs';
  String pregnancySummary(Trimester trimester, int week) {
    final trimesterLabel = this.trimesterLabel(trimester);
    return isMalay
        ? 'Trimester $trimesterLabel - Minggu $week'
        : '$trimesterLabel trimester - Week $week';
  }

  static const Map<String, String> _ms = {
    'Overview': 'Ringkasan',
    'Log': 'Log',
    'Appointments': 'Temu janji',
    'Feedback': 'Maklum balas',
    'Please sign in to send feedback.':
        'Sila log masuk untuk menghantar maklum balas.',
    'Feedback sent': 'Maklum balas dihantar',
    'Feedback monitor': 'Pemantau maklum balas',
    'Review comments and ratings from users.':
        'Semak komen dan penilaian daripada pengguna.',
    'Share how the app is working for you.':
        'Kongsi bagaimana aplikasi ini berfungsi untuk anda.',
    'Share your feedback': 'Kongsi maklum balas anda',
    'Message': 'Mesej',
    'Rating': 'Penilaian',
    'Send feedback': 'Hantar maklum balas',
    'All feedback': 'Semua maklum balas',
    'Your feedback': 'Maklum balas anda',
    'No feedback yet': 'Belum ada maklum balas',
    'Feedback will show up here once it is submitted.':
        'Maklum balas akan dipaparkan di sini selepas dihantar.',
    'Please sign in.': 'Sila log masuk.',
    'Schedule and track upcoming clinic visits.':
        'Jadualkan dan jejak lawatan klinik yang akan datang.',
    'New': 'Baharu',
    'No appointments scheduled': 'Tiada temu janji dijadualkan',
    'Create a new appointment to reserve a time slot.':
        'Cipta temu janji baru untuk menempah slot masa.',
    'Your upcoming appointments will appear here.':
        'Temu janji akan datang akan dipaparkan di sini.',
    'Schedule appointment': 'Jadualkan temu janji',
    'Mark complete': 'Tandakan selesai',
    'Patient': 'Pesakit',
    'Select a patient': 'Pilih pesakit',
    'Provider': 'Penyedia',
    'Select a provider': 'Pilih penyedia',
    'Type': 'Jenis',
    'Pick': 'Pilih',
    'No available slots for this date.':
        'Tiada slot tersedia untuk tarikh ini.',
    'Time slot': 'Slot masa',
    'Select a time slot': 'Pilih slot masa',
    'Send reminder to patient': 'Hantar peringatan kepada pesakit',
    'Reminder message (optional)': 'Mesej peringatan (pilihan)',
    'Only doctors, dietitians, and nurses can schedule.':
        'Hanya doktor, pakar diet, dan jururawat boleh menjadualkan.',
    'No patients available yet.': 'Belum ada pesakit tersedia.',
    'No doctors or dietitians available yet.':
        'Belum ada doktor atau pakar diet tersedia.',
    'Nutrition Consultation': 'Konsultasi pemakanan',
    'Reports': 'Laporan',
    'Please sign in to view reports.': 'Sila log masuk untuk melihat laporan.',
    'Weekly report': 'Laporan mingguan',
    'Track your average intake and progress over the last 7 days.':
        'Jejak purata pengambilan dan kemajuan anda selama 7 hari terakhir.',
    'Average intake': 'Purata pengambilan',
    'Target adherence': 'Pematuhan sasaran',
    'Export report': 'Eksport laporan',
    'Saved reports': 'Laporan disimpan',
    'No saved reports yet.': 'Belum ada laporan disimpan.',
    'Report copied to clipboard': 'Laporan disalin ke papan klip',
    'Saved report': 'Laporan disimpan',
    'Medical report': 'Laporan perubatan',
    'Nutrition report': 'Laporan pemakanan',
    'Reports overview': 'Ringkasan laporan',
    'Tap a patient to review their last 7 days of intake.':
        'Ketik pesakit untuk semak pengambilan 7 hari terakhir.',
    'No patient reports yet': 'Belum ada laporan pesakit',
    'Reports will appear once patients start logging meals.':
        'Laporan akan muncul selepas pesakit mula log makanan.',
    'Analytics': 'Analitik',
    'System usage': 'Penggunaan sistem',
    'High-level metrics across all users.':
        'Metrik ringkas untuk semua pengguna.',
    'Total users': 'Jumlah pengguna',
    'Active accounts': 'Akaun aktif',
    'Inactive accounts': 'Akaun tidak aktif',
    'Total logins': 'Jumlah log masuk',
    'Report': 'Laporan',
    'Profile': 'Profil',
    'Patients': 'Pesakit',
    'Analysis': 'Analisis',
    'Plans': 'Pelan',
    'Monitoring': 'Pemantauan',
    'Monitoring & alerts': 'Pemantauan & amaran',
    'Please sign in to view monitoring alerts.':
        'Sila log masuk untuk melihat amaran pemantauan.',
    'Review alerts and reminders based on your recent logs.':
        'Semak amaran dan peringatan berdasarkan log terkini.',
    'Refresh': 'Muat semula',
    'Alerts': 'Amaran',
    'No alerts': 'Tiada amaran',
    'You are all caught up for now.': 'Tiada amaran buat masa ini.',
    'Mark read': 'Tandakan dibaca',
    'Notifications': 'Notifikasi',
    'No notifications yet.': 'Belum ada notifikasi.',
    'No critical alerts': 'Tiada amaran kritikal',
    'All patients look stable right now.':
        'Semua pesakit kelihatan stabil buat masa ini.',
    'Review alerts for patients who need attention.':
        'Semak amaran untuk pesakit yang memerlukan perhatian.',
    'Modules': 'Modul',
    'Admin': 'Admin',
    'Data': 'Data',
    'Education': 'Pendidikan',
    'Education & content': 'Pendidikan & kandungan',
    'Please sign in to view education content.':
        'Sila log masuk untuk melihat kandungan pendidikan.',
    'Browse guides, tips, and trimester content.':
        'Teroka panduan, tip, dan kandungan trimester.',
    'From database': 'Dari pangkalan data',
    'Tap to view details.': 'Ketik untuk lihat butiran.',
    'Trimester nutrition guide': 'Panduan pemakanan trimester',
    'Recommended targets based on gestation stage.':
        'Sasaran yang disyorkan berdasarkan tahap kehamilan.',
    'Perinatal care manual': 'Manual penjagaan perinatal',
    'Pre-pregnancy risk checks, care workflow, counselling, and antenatal visits.':
        'Semakan risiko pra-kehamilan, aliran penjagaan, kaunseling, dan lawatan antenatal.',
    'Structured guidance from pages 29-79 for pre-pregnancy and early antenatal care.':
        'Panduan berstruktur daripada halaman 29-79 untuk penjagaan pra-kehamilan dan antenatal awal.',
    'Antenatal visit schedule': 'Jadual lawatan antenatal',
    'Use this as care-team reference material, not as a replacement for clinician judgement.':
        'Gunakan ini sebagai rujukan pasukan penjagaan, bukan pengganti pertimbangan klinisian.',
    'Healthy meal suggestions': 'Cadangan hidangan sihat',
    'Balanced meal ideas and snack tips.':
        'Idea hidangan seimbang dan tip snek.',
    'Curated meal ideas for each trimester.':
        'Idea hidangan pilihan untuk setiap trimester.',
    'Iron-rich meals with leafy greens and lean proteins':
        'Hidangan kaya zat besi dengan sayur berdaun dan protein tanpa lemak.',
    'Calcium-forward snacks and dairy alternatives':
        'Snek tinggi kalsium dan alternatif tenusu.',
    'Balanced plates with complex carbs and fiber':
        'Pinggan seimbang dengan karbohidrat kompleks dan serat.',
    'Personalize recommendations with your care team.':
        'Peribadikan cadangan bersama pasukan penjagaan anda.',
    'Pregnancy nutrition FAQs': 'Soalan Lazim pemakanan kehamilan',
    'Quick guidance and common questions.': 'Panduan ringkas dan soalan biasa.',
    'Common questions answered in one place.':
        'Soalan biasa dijawab di satu tempat.',
    'How much water should I drink daily?':
        'Berapa banyak air perlu saya minum setiap hari?',
    'What foods support healthy iron levels?':
        'Makanan apa yang menyokong paras zat besi yang sihat?',
    'Safe caffeine limits during pregnancy':
        'Had kafein yang selamat semasa kehamilan',
    'Always consult your clinician for medical advice.':
        'Sentiasa rujuk klinisian anda untuk nasihat perubatan.',
    'AI nutrition assistant': 'Pembantu pemakanan AI',
    'Ask about pregnancy nutrition and the content above.':
        'Tanya tentang pemakanan kehamilan dan kandungan di atas.',
    'Ask a nutrition question': 'Tanya soalan pemakanan',
    'Send': 'Hantar',
    'Thanks for the question. This is a demo chat box. Connect an AI service to provide tailored answers.':
        'Terima kasih atas soalan. Ini kotak sembang demo. Sambungkan servis AI untuk jawapan yang disesuaikan.',
    'Try to spread water intake across the day, aim for steady sips, and follow any target from your care team.':
        'Cuba agihkan pengambilan air sepanjang hari, minum sedikit tetapi kerap, dan ikut sasaran daripada pasukan penjagaan.',
    'Pair iron sources with vitamin C and include leafy greens, beans, or lean meats.':
        'Gandingkan sumber zat besi dengan vitamin C dan ambil sayur berdaun, kekacang, atau daging tanpa lemak.',
    'During pregnancy, keep caffeine moderate and check with your clinician if unsure.':
        'Semasa kehamilan, hadkan kafein dan semak dengan klinisian jika tidak pasti.',
    'What you can do': 'Apa yang boleh anda lakukan',
    'Account': 'Akaun',
    'Edit': 'Kemas kini',
    'Save': 'Simpan',
    'Cancel': 'Batal',
    'Create': 'Cipta',
    'Delete': 'Padam',
    'Restore': 'Pulihkan',
    'View': 'Lihat',
    'Search': 'Cari',
    'Filter': 'Tapis',
    'Submit': 'Hantar',
    'Continue': 'Teruskan',
    'Close': 'Tutup',
    'Clear': 'Kosongkan',
    'Login': 'Log masuk',
    'Create account': 'Cipta akaun',
    'Back to website': 'Kembali ke laman web',
    'Pregnancy nutrition platform': 'Platform pemakanan kehamilan',
    'Admin dashboard + mobile app': 'Papan pemuka admin + aplikasi mudah alih',
    'Pregnancy nutrition care, coordinated.':
        'Penjagaan pemakanan kehamilan yang terselaras.',
    'One nutrition platform for the clinic and the mother.':
        'Satu platform pemakanan untuk klinik dan ibu.',
    'Smartbunda connects admin operations, care-team visibility, and daily mobile tracking in one coordinated workflow.':
        'Smartbunda menghubungkan operasi admin, keterlihatan pasukan penjagaan, dan penjejakan mudah alih harian dalam satu aliran kerja terselaras.',
    'Open platform': 'Buka platform',
    'Admin approvals and reporting': 'Kelulusan admin dan pelaporan',
    'Mobile food and hydration logs': 'Log makanan dan hidrasi mudah alih',
    'Shared patient care context': 'Konteks penjagaan pesakit yang dikongsi',
    'Two connected surfaces': 'Dua permukaan yang saling terhubung',
    'Admin control for the clinic. Simple tracking for the patient.':
        'Kawalan admin untuk klinik. Penjejakan ringkas untuk pesakit.',
    'Smartbunda gives administrators a professional control layer while keeping the mobile experience focused on daily habits and care follow-up.':
        'Smartbunda memberi pentadbir lapisan kawalan profesional sambil mengekalkan pengalaman mudah alih yang fokus pada tabiat harian dan susulan penjagaan.',
    'Designed for staff approvals, access control, reporting, and system oversight.':
        'Direka untuk kelulusan staf, kawalan akses, pelaporan, dan pemantauan sistem.',
    'Built for mothers to log meals, hydration, appointments, and nutrition progress quickly.':
        'Dibina untuk ibu merekod makanan, hidrasi, temu janji, dan kemajuan pemakanan dengan cepat.',
    'User approvals and role management':
        'Kelulusan pengguna dan pengurusan peranan',
    'Operational filters, sorting, and review queues':
        'Penapis operasi, pengisihan, dan barisan semakan',
    'Reporting, analytics, and system health':
        'Pelaporan, analitik, dan kesihatan sistem',
    'Meal logging and image-based food scan':
        'Log makanan dan imbasan makanan berasaskan imej',
    'Hydration and appointment tracking': 'Penjejakan hidrasi dan temu janji',
    'Simple summaries and care-team visibility':
        'Ringkasan mudah dan keterlihatan pasukan penjagaan',
    'Shared workflow': 'Aliran kerja dikongsi',
    'From patient action to admin visibility in one loop.':
        'Daripada tindakan pesakit kepada keterlihatan admin dalam satu aliran.',
    'Daily intake and patient activity stay visible to the clinic, while admin teams keep access, approvals, and reporting organized.':
        'Pengambilan harian dan aktiviti pesakit kekal kelihatan kepada klinik, manakala pasukan admin mengekalkan akses, kelulusan, dan pelaporan secara teratur.',
    'Patient logs meals': 'Pesakit merekod makanan',
    'The mobile app captures food, hydration, and appointment activity.':
        'Aplikasi mudah alih menangkap aktiviti makanan, hidrasi, dan temu janji.',
    'Care data becomes visible': 'Data penjagaan menjadi kelihatan',
    'Nutrition and monitoring workflows share a consistent patient record.':
        'Aliran kerja pemakanan dan pemantauan berkongsi rekod pesakit yang konsisten.',
    'Admin teams stay in control': 'Pasukan admin kekal mengawal',
    'Approvals, user policies, and reports remain manageable from the dashboard.':
        'Kelulusan, polisi pengguna, dan laporan kekal mudah diurus dari papan pemuka.',
    'Platform coverage': 'Liputan platform',
    'Built for real clinic operations and daily mobile use.':
        'Dibina untuk operasi klinik sebenar dan penggunaan mudah alih harian.',
    'The web-style admin experience gives staff a broader operational view, while the mobile flow stays quick enough for repeat daily logging.':
        'Pengalaman admin gaya web memberi staf pandangan operasi yang lebih luas, manakala aliran mudah alih kekal cukup pantas untuk log harian berulang.',
    'Admin operations': 'Operasi admin',
    'Approvals, account control, patient directory review, and reporting.':
        'Kelulusan, kawalan akaun, semakan direktori pesakit, dan pelaporan.',
    'Mobile tracking': 'Penjejakan mudah alih',
    'Meal scan, hydration logging, appointments, and daily summaries.':
        'Imbasan makanan, log hidrasi, temu janji, dan ringkasan harian.',
    'Launch the dashboard. Keep the mobile experience close.':
        'Lancarkan papan pemuka. Kekalkan pengalaman mudah alih dekat.',
    'Use one Smartbunda workspace to coordinate admin teams, care teams, and patient habits.':
        'Gunakan satu ruang kerja Smartbunda untuk menyelaras pasukan admin, pasukan penjagaan, dan tabiat pesakit.',
    'Track meals, hydration, appointments, and care team recommendations in one secure workspace.':
        'Jejak makanan, hidrasi, temu janji, dan cadangan pasukan penjagaan dalam satu ruang kerja selamat.',
    'Start tracking': 'Mula menjejak',
    'Role-based access': 'Akses mengikut peranan',
    'Patient progress reports': 'Laporan kemajuan pesakit',
    'Clinic follow-up tools': 'Alat susulan klinik',
    'One platform': 'Satu platform',
    'Clear workspaces for every user.':
        'Ruang kerja jelas untuk setiap pengguna.',
    'Mothers, nurses, doctors, dietitians, and administrators each get the tools that match their responsibility.':
        'Ibu, jururawat, doktor, pakar diet, dan pentadbir menerima alat yang sepadan dengan tanggungjawab masing-masing.',
    'Mothers': 'Ibu',
    'Daily meals, hydration, appointments, and progress.':
        'Makanan harian, hidrasi, temu janji, dan kemajuan.',
    'Care teams': 'Pasukan penjagaan',
    'Patient profiles, nutrition analysis, and care plans.':
        'Profil pesakit, analisis pemakanan, dan pelan penjagaan.',
    'Administrators': 'Pentadbir',
    'User approvals, system health, content, and reporting.':
        'Kelulusan pengguna, kesihatan sistem, kandungan, dan pelaporan.',
    'Clinical follow-up': 'Susulan klinikal',
    'Keep nutrition decisions connected to real logs.':
        'Hubungkan keputusan pemakanan dengan log sebenar.',
    'Smartbunda turns daily intake into practical context for appointments, recommendations, and reports.':
        'Smartbunda menukar pengambilan harian kepada konteks praktikal untuk temu janji, cadangan, dan laporan.',
    'Nutrition targets by pregnancy stage':
        'Sasaran pemakanan mengikut tahap kehamilan',
    'Alerts for gaps in iron, folate, and protein':
        'Amaran untuk jurang zat besi, folat, dan protein',
    'Reports ready for care conversations':
        'Laporan tersedia untuk perbincangan penjagaan',
    'Start with your next meal.': 'Mulakan dengan hidangan seterusnya.',
    'Build a clearer nutrition record for every visit.':
        'Bina rekod pemakanan yang lebih jelas untuk setiap lawatan.',
    'Join Smartbunda to personalize nutrition tracking and care.':
        'Sertai Smartbunda untuk memperibadikan penjejakan pemakanan dan penjagaan.',
    'Back to login': 'Kembali ke log masuk',
    'New here?': 'Baharu di sini?',
    'Already have an account?': 'Sudah ada akaun?',
    'Sign in': 'Log masuk',
    'Welcome back': 'Selamat kembali',
    'or': 'atau',
    'Forgot password?': 'Lupa kata laluan?',
    'Reset password': 'Tetapkan semula kata laluan',
    'Send reset link': 'Hantar pautan set semula',
    'The reset link has been sent to your email.':
        'Pautan set semula telah dihantar ke emel anda.',
    'Confirm your email': 'Sahkan emel anda',
    'Enter a valid email': 'Masukkan emel yang sah',
    'Min 6 characters': 'Minimum 6 aksara',
    'Password must include uppercase, lowercase, number, and symbol (min 6 characters).':
        'Kata laluan mesti mengandungi huruf besar, huruf kecil, nombor, dan simbol (minimum 6 aksara).',
    'Passwordless sign-in': 'Log masuk tanpa kata laluan',
    'Send sign-in link': 'Hantar pautan log masuk',
    'Email link sent. Check your inbox.':
        'Pautan emel dihantar. Sila semak peti masuk.',
    'Enter a valid email for email link sign-in.':
        'Masukkan emel yang sah untuk log masuk melalui pautan emel.',
    'A calm way to track pregnancy nutrition and stay in sync with care.':
        'Cara tenang untuk menjejak pemakanan kehamilan dan kekal seiring penjagaan.',
    'Sign in to review your plan, logs, and recommendations.':
        'Log masuk untuk semak pelan, log, dan cadangan anda.',
    'We will email a secure link. Use it on this device to finish signing in.':
        'Kami akan emel pautan selamat. Gunakannya pada peranti ini untuk selesai log masuk.',
    'Pregnancy nutrition, simplified.': 'Pemakanan kehamilan, dipermudahkan.',
    'Set up your profile': 'Sediakan profil anda',
    'Choose your role so we can match the right tools and permissions.':
        'Pilih peranan anda supaya kami boleh padankan alat dan kebenaran yang sesuai.',
    'Role': 'Peranan',
    'License details': 'Butiran lesen',
    'MMC number': 'Nombor MMC',
    'JLM number': 'Nombor JLM',
    'Required': 'Wajib',
    'Number': 'Nombor',
    'Required for this role': 'Wajib untuk peranan ini',
    'Dietitian / Nutritionist': 'Pakar Diet / Pakar Pemakanan',
    'Admin approval is required before staff accounts can sign in.':
        'Kelulusan admin diperlukan sebelum akaun staf boleh log masuk.',
    'Confirm': 'Sahkan',
    'Email': 'Emel',
    'Password': 'Kata laluan',
    'Name': 'Nama',
    'Yes': 'Ya',
    'No': 'Tidak',
    'Logout': 'Log keluar',
    'Today': 'Hari ini',
    'Daily summary': 'Ringkasan harian',
    'Nutrition facts': 'Fakta pemakanan',
    'Please sign in to view nutrition facts.':
        'Sila log masuk untuk melihat fakta pemakanan.',
    'These are general targets for pregnancy. Consult your care team for personal guidance.':
        'Ini sasaran umum untuk kehamilan. Rujuk pasukan penjagaan anda untuk panduan peribadi.',
    'Water': 'Air',
    'GDM': 'GDM',
    'anemia': 'anemia',
    'Patient profiles': 'Profil pesakit',
    'Please sign in to view patient profiles.':
        'Sila log masuk untuk melihat profil pesakit.',
    'No patients yet': 'Belum ada pesakit',
    'Patients will appear here after registration.':
        'Pesakit akan muncul di sini selepas pendaftaran.',
    'Open a patient to review their profile and logs.':
        'Buka pesakit untuk semak profil dan log mereka.',
    'Profile missing': 'Profil tiada',
    'Pregnancy not set': 'Kehamilan belum ditetapkan',
    'Food logging': 'Log makanan',
    'Food catalog': 'Katalog makanan',
    'Food logging & nutrition': 'Log makanan & pemakanan',
    'Log meals and hydration to keep recommendations accurate.':
        'Log makanan dan hidrasi untuk pastikan cadangan tepat.',
    'Choose how you want to log': 'Pilih cara untuk log',
    'Meal log': 'Log makanan',
    'Log meals to keep your summary and recommendations accurate.':
        'Log makanan untuk memastikan ringkasan dan cadangan tepat.',
    'No meals logged yet': 'Belum ada makanan direkodkan',
    'Add your first meal to start tracking nutrition.':
        'Tambah makanan pertama anda untuk mula menjejak pemakanan.',
    'Log a meal': 'Log makanan',
    'Manual entry': 'Input manual',
    'Pick from Malaysian food DB': 'Pilih dari DB makanan Malaysia',
    'Food DB': 'DB makanan',
    'Add meals from the food database or meal scanner.':
        'Tambah makanan daripada pangkalan data makanan atau pengimbas.',
    'Tip: scan when you have a clear food photo, or use manual entry when the dish is mixed.':
        'Tip: imbas apabila foto makanan jelas, atau gunakan input manual apabila hidangan bercampur.',
    'Type the meal and nutrients yourself.':
        'Taip makanan dan nutrien sendiri.',
    'Search saved foods and portions.':
        'Cari makanan dan saiz hidangan yang disimpan.',
    'Take a fresh photo for AI food detection.':
        'Ambil foto baharu untuk pengesanan AI makanan.',
    'Choose an existing photo from your gallery.':
        'Pilih foto sedia ada daripada galeri anda.',
    'Scan with camera': 'Imbas dengan kamera',
    'Upload image': 'Muat naik imej',
    'Meal scanner': 'Pengimbas makanan',
    'Scan meal': 'Imbas makanan',
    'Use your camera or gallery to detect a meal and save it faster.':
        'Gunakan kamera atau galeri anda untuk mengesan makanan dan simpan dengan lebih pantas.',
    'Use your camera or gallery to detect a Malaysian dish and add it to your meal log.':
        'Gunakan kamera atau galeri anda untuk mengesan hidangan Malaysia dan menambahkannya ke log makanan anda.',
    'Scan and save meals faster':
        'Imbas dan simpan makanan dengan lebih pantas',
    'Smartbunda analyzes the image with AI, matches the result to your food database, then lets you confirm the detected meal before saving.':
        'Smartbunda menganalisis imej dengan AI, memadankan hasilnya dengan pangkalan data makanan anda, kemudian membolehkan anda mengesahkan makanan yang dikesan sebelum disimpan.',
    'How it works': 'Cara ia berfungsi',
    'Take a photo or choose one from your gallery.':
        'Ambil foto atau pilih satu daripada galeri anda.',
    'Review the detected food suggestions and pick the best match.':
        'Semak cadangan makanan yang dikesan dan pilih padanan terbaik.',
    'Confirm meal time and quantity, then save the log entry.':
        'Sahkan waktu makan dan kuantiti, kemudian simpan entri log.',
    'Scanner requirements': 'Keperluan pengimbas',
    'AI scanner': 'Pengimbas AI',
    'The AI scanner sends the photo to a vision model for food identification.':
        'Pengimbas AI menghantar foto ke model penglihatan untuk pengenalpastian makanan.',
    'Use a bright, clear image with one main dish for better suggestions.':
        'Gunakan imej terang dan jelas dengan satu hidangan utama untuk cadangan yang lebih baik.',
    'Analyzing image...': 'Menganalisis imej...',
    'Choose detected food': 'Pilih makanan yang dikesan',
    'Pick the closest match before saving to your meal log.':
        'Pilih padanan paling hampir sebelum simpan ke log makanan anda.',
    'Nutrition details needed': 'Butiran nutrisi diperlukan',
    'Confidence': 'Keyakinan',
    'Could not read selected image.': 'Tidak dapat membaca imej yang dipilih.',
    'No matching food found in the food database for this image.':
        'Tiada makanan sepadan ditemui dalam pangkalan data untuk imej ini.',
    'Meal saved from image scan.': 'Makanan disimpan daripada imbasan imej.',
    'Meal name': 'Nama hidangan',
    'Meal time': 'Waktu makan',
    'Quantity': 'Kuantiti',
    'Protein (g)': 'Protein (g)',
    'Carbs (g)': 'Karbohidrat (g)',
    'Fat (g)': 'Lemak (g)',
    'Iron (mg)': 'Zat besi (mg)',
    'Folate (mcg)': 'Folat (mcg)',
    'Meal saved.': 'Makanan disimpan.',
    'Search Malaysian foods': 'Cari makanan Malaysia',
    'Food database is empty.': 'Pangkalan data makanan kosong.',
    'Log daily food and beverage intake.':
        'Log pengambilan makanan dan minuman harian.',
    'Hydration log': 'Log hidrasi',
    'Track water intake and reminders.':
        'Jejak pengambilan air dan peringatan.',
    'Hydration': 'Hidrasi',
    'Log water throughout the day to hit your daily target.':
        'Log air sepanjang hari untuk capai sasaran harian.',
    'Quick add': 'Tambah cepat',
    'Custom amount (ml)': 'Jumlah tersuai (ml)',
    'Enter a valid amount in ml': 'Masukkan jumlah ml yang sah',
    'Add': 'Tambah',
    'Today log': 'Log hari ini',
    'No water logged yet': 'Belum ada air yang direkodkan',
    'Use the quick add buttons to log your first drink.':
        'Gunakan butang tambah cepat untuk log minuman pertama anda.',
    'Last 7 days': '7 hari terakhir',
    'Please sign in to track hydration.': 'Sila log masuk untuk jejak hidrasi.',
    'Appointments & reminders': 'Temu janji & peringatan',
    'System administration': 'Pentadbiran sistem',
    'System health': 'Kesihatan sistem',
    'Settings': 'Tetapan',
    'Language': 'Bahasa',
    'App language': 'Bahasa aplikasi',
    'Summary': 'Ringkasan',
    'Please sign in to view your summary.':
        'Sila log masuk untuk melihat ringkasan anda.',
    'Review nutrition progress and recommendations by day.':
        'Semak kemajuan pemakanan dan cadangan mengikut hari.',
    'Pick date': 'Pilih tarikh',
    'Complete your profile to tailor targets':
        'Lengkapkan profil anda untuk sesuaikan sasaran',
    'Recommendations': 'Cadangan',
    'On track. Keep logging meals.': 'Anda di landasan. Teruskan log makanan.',
    'Nothing logged for this day.': 'Tiada log untuk hari ini.',
    'Nutrient progress mix': 'Campuran kemajuan nutrien',
    'No nutrients logged yet.': 'Belum ada nutrien yang direkodkan.',
    'Progress by target': 'Kemajuan mengikut sasaran',
    'Calories': 'Kalori',
    'Protein': 'Protein',
    'Carbs': 'Karbohidrat',
    'Fat': 'Lemak',
    'Iron': 'Zat besi',
    'Folate': 'Folat',
    'avg': 'purata',
    'Breakfast': 'Sarapan',
    'Lunch': 'Makan tengah hari',
    'Dinner': 'Makan malam',
    'Supper': 'Makan lewat',
    'Meal': 'Hidangan',
    'Add spinach, legumes, and lean meat for iron support.':
        'Tambah bayam, kekacang, dan daging tanpa lemak untuk sokongan zat besi.',
    'Add leafy greens or beans to raise folate intake.':
        'Tambah sayur berdaun atau kekacang untuk tingkatkan folat.',
    'For anemia: pair iron sources with vitamin C to improve absorption.':
        'Untuk anemia: gabungkan sumber zat besi dengan vitamin C untuk serapan lebih baik.',
  };
}
