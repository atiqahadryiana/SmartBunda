import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/pregnancy.dart';

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
  String get logoutMessage =>
      isMalay ? 'Adakah anda pasti mahu log keluar?' : 'Are you sure you want to log out?';
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
  String get noProfileYet => isMalay ? 'Profil belum tersedia' : 'No profile yet';
  String get noProfileMessage => isMalay
      ? 'Lengkapkan profil anda untuk dapatkan sasaran diperibadikan.'
      : 'Complete your profile to unlock personalized targets.';
  String get outcomes => isMalay ? 'Status' : 'Outcomes';
  String get details => isMalay ? 'Butiran' : 'Details';
  String get medicalConditions => isMalay ? 'Keadaan perubatan' : 'Medical conditions';
  String get pregnancy => isMalay ? 'Kehamilan' : 'Pregnancy';
  String get pregnancyNotSet =>
      isMalay ? 'Maklumat kehamilan belum ditetapkan.' : 'Pregnancy details not set yet.';
  String get gestationalWeek => isMalay ? 'Minggu kehamilan' : 'Gestational week';
  String get trimester => isMalay ? 'Trimester' : 'Trimester';
  String get week => isMalay ? 'Minggu' : 'Week';
  String get edd => isMalay ? 'Tarikh jangka lahir' : 'EDD';
  String get riskLevel => isMalay ? 'Tahap risiko' : 'Risk level';
  String get dateOfBirth => isMalay ? 'Tarikh lahir' : 'Date of birth';
  String get height => isMalay ? 'Tinggi' : 'Height';
  String get weight => isMalay ? 'Berat' : 'Weight';
  String get bloodType => isMalay ? 'Jenis darah' : 'Blood type';
  String get noneReported => isMalay ? 'Tiada dilaporkan' : 'None reported';

  String get accountTitle => isMalay ? 'Akaun' : 'Account';
  String get accountSubtitle =>
      isMalay ? 'Urus butiran profil dan tetapan peranan anda.' : 'Manage your profile details and role settings.';
  String get accountReviewSubtitle => isMalay
      ? 'Semak butiran akaun dan peranan anda.'
      : 'Review your account details and role.';
  String get signInToViewProfile =>
      isMalay ? 'Sila log masuk untuk melihat profil anda.' : 'Please sign in to view your profile.';
  String get signInToEditProfile =>
      isMalay ? 'Sila log masuk untuk kemas kini profil anda.' : 'Please sign in to edit your profile.';
  String get patientProfileTitle => isMalay ? 'Profil pesakit' : 'Patient profile';
  String get patientProfileSubtitle => isMalay
      ? 'Lengkapkan butiran anda untuk peribadikan sasaran pemakanan.'
      : 'Complete your details to personalize nutrition targets.';
  String get dobLabel =>
      isMalay ? 'Tarikh lahir (YYYY-MM-DD)' : 'Date of birth (YYYY-MM-DD)';
  String get heightLabel => isMalay ? 'Tinggi (cm)' : 'Height (cm)';
  String get weightLabel => isMalay ? 'Berat (kg)' : 'Weight (kg)';
  String get bmiLabel => 'BMI';
  String get bloodTypeLabel => isMalay ? 'Jenis darah' : 'Blood type';
  String get anemiaLabel => 'Anemia';
  String get gdmLabel => isMalay ? 'Diabetes gestasi' : 'Gestational diabetes';
  String get pregnancyModuleNote => isMalay
      ? 'Profil kehamilan pesakit diurus melalui modul profil pesakit.'
      : 'Patient pregnancy profiles are managed on the patient profile module.';
  String get pregnancySectionTitle => isMalay ? 'Kehamilan' : 'Pregnancy';
  String get gestationalWeekLabel => isMalay ? 'Minggu kehamilan' : 'Gestational week';
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
  String unableToAccessMedia(String message) =>
      isMalay ? 'Tidak dapat akses media: $message' : 'Unable to access media: $message';
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
  String totalCaloriesLogged(int total) =>
      isMalay ? 'Jumlah kalori direkod: $total' : 'Total calories logged: $total';
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
  String fromUser(String name) =>
      isMalay ? 'Daripada: $name' : 'From: $name';
  String get heightWeightNumberError =>
      isMalay ? 'Tinggi dan berat mestilah nombor.' : 'Height and weight must be numbers.';
  String get weekNumberError =>
      isMalay ? 'Minggu kehamilan mestilah nombor.' : 'Gestational week must be a number.';
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
  String logsCount(int count) =>
      isMalay ? '$count log' : '$count logs';
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
    'Please sign in to send feedback.': 'Sila log masuk untuk menghantar maklum balas.',
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
    'No available slots for this date.': 'Tiada slot tersedia untuk tarikh ini.',
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
    'Reports overview': 'Ringkasan laporan',
    'Tap a patient to review their last 7 days of intake.':
        'Ketik pesakit untuk semak pengambilan 7 hari terakhir.',
    'No patient reports yet': 'Belum ada laporan pesakit',
    'Reports will appear once patients start logging meals.':
        'Laporan akan muncul selepas pesakit mula log makanan.',
    'Analytics': 'Analitik',
    'System usage': 'Penggunaan sistem',
    'High-level metrics across all users.': 'Metrik ringkas untuk semua pengguna.',
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
    'Healthy meal suggestions': 'Cadangan hidangan sihat',
    'Balanced meal ideas and snack tips.': 'Idea hidangan seimbang dan tip snek.',
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
    'Common questions answered in one place.': 'Soalan biasa dijawab di satu tempat.',
    'How much water should I drink daily?':
        'Berapa banyak air perlu saya minum setiap hari?',
    'What foods support healthy iron levels?':
        'Makanan apa yang menyokong paras zat besi yang sihat?',
    'Safe caffeine limits during pregnancy':
        'Had kafein yang selamat semasa kehamilan',
    'Always consult your clinician for medical advice.':
        'Sentiasa rujuk klinisian anda untuk nasihat perubatan.',
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
    'The reset link has been sent to your email.': 'Pautan set semula telah dihantar ke emel anda.',
    'Confirm your email': 'Sahkan emel anda',
    'Enter a valid email': 'Masukkan emel yang sah',
    'Min 6 characters': 'Minimum 6 aksara',
    'Passwordless sign-in': 'Log masuk tanpa kata laluan',
    'Send sign-in link': 'Hantar pautan log masuk',
    'Email link sent. Check your inbox.': 'Pautan emel dihantar. Sila semak peti masuk.',
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
    'Meal log': 'Log makanan',
    'Log meals to keep your summary and recommendations accurate.':
        'Log makanan untuk memastikan ringkasan dan cadangan tepat.',
    'No meals logged yet': 'Belum ada makanan direkodkan',
    'Add your first meal to start tracking nutrition.':
        'Tambah makanan pertama anda untuk mula menjejak pemakanan.',
    'Log a meal': 'Log makanan',
    'Manual entry': 'Input manual',
    'Pick from Malaysian food DB': 'Pilih dari DB makanan Malaysia',
    'Scan with camera': 'Imbas dengan kamera',
    'Upload image': 'Muat naik imej',
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
    'Log daily food and beverage intake.': 'Log pengambilan makanan dan minuman harian.',
    'Hydration log': 'Log hidrasi',
    'Track water intake and reminders.': 'Jejak pengambilan air dan peringatan.',
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
    'Please sign in to view your summary.': 'Sila log masuk untuk melihat ringkasan anda.',
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
