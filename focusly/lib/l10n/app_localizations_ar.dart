// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get languageName => 'العربية';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonDone => 'تم';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonError => 'حدث خطأ ما';

  @override
  String get commonSearch => 'بحث';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonYes => 'نعم';

  @override
  String get commonNo => 'لا';

  @override
  String get commonOk => 'حسناً';

  @override
  String get commonSkip => 'تخطّي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguageSection => 'اللغة';

  @override
  String get settingsLanguageTile => 'لغة التطبيق';

  @override
  String get languageSystemDefault => 'حسب الجهاز';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsAccountSection => 'الحساب';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get settingsPremium => 'بريميوم';

  @override
  String get settingsPremiumActive => 'مفعّل';

  @override
  String get settingsPremiumUpgrade => 'ترقية';

  @override
  String get settingsCancelSubscription => 'إلغاء الاشتراك';

  @override
  String get settingsCancelSubscriptionSubtitle =>
      'إيقاف التجديد في نهاية الفترة';

  @override
  String get settingsAiNotes => 'ملاحظات الذكاء الاصطناعي';

  @override
  String get settingsNotificationsSection => 'الإشعارات';

  @override
  String get settingsStudyReminders => 'تذكيرات المذاكرة';

  @override
  String get settingsStreakAlerts => 'تنبيهات التتابع';

  @override
  String get settingsProductUpdates => 'تحديثات التطبيق';

  @override
  String get settingsNotificationsSaved => 'تم حفظ تفضيلات الإشعارات';

  @override
  String get settingsFocusSection => 'التركيز';

  @override
  String get settingsFocusMode => 'وضع التركيز';

  @override
  String get settingsFocusModeSubtitle => 'تقليل الإشعارات غير الضرورية';

  @override
  String get settingsActiveDevices => 'الأجهزة النشطة';

  @override
  String get settingsThisDevice => 'هذا الجهاز';

  @override
  String get settingsOtherDevice => 'جهاز آخر';

  @override
  String get settingsDangerZone => 'منطقة الخطر';

  @override
  String get settingsLogOut => 'تسجيل الخروج';

  @override
  String get settingsDeleteAccount => 'حذف الحساب';

  @override
  String get settingsDeleteAccountConfirmTitle => 'حذف الحساب؟';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'سيؤدي هذا إلى حذف بياناتك نهائياً. اكتب DELETE للتأكيد.';

  @override
  String get homeNavHome => 'الرئيسية';

  @override
  String get homeNavSchedule => 'الجدول';

  @override
  String get homeNavFocus => 'التركيز';

  @override
  String get homeNavStats => 'الإحصائيات';

  @override
  String get homeNavProfile => 'الملف الشخصي';

  @override
  String get homeNavPlanner => 'المخطط';

  @override
  String get homeDefaultName => 'طالب';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'مساء الخير';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String homeGreetingName(String name) {
    return 'أهلاً $name 👋';
  }

  @override
  String get homeSubjectsTitle => 'موادك الدراسية';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeDashboardLoadErrorTitle => 'تعذّر تحميل لوحتك';

  @override
  String get homeNoSubjectsTitle => 'لا توجد مواد بعد';

  @override
  String get homeNoSubjectsSubtitle =>
      'أضف أول مادة لك لتجعل الشاشة الرئيسية مفيدة ونابضة بالحياة.';

  @override
  String get homeCreateSubject => 'إنشاء مادة';

  @override
  String homeSubjectTargetMinutes(int minutes) {
    return '· هدف $minutes د';
  }

  @override
  String get homeStudyOverview => 'نظرة عامة على الدراسة';

  @override
  String get homeOverallProgress => 'التقدّم الإجمالي';

  @override
  String get homeOverviewLoading => 'جارٍ جلب موادك وأهدافك…';

  @override
  String get homeOverviewEmpty => 'أضف موادًا لبدء تتبّع تقدّمك.';

  @override
  String homeSubjectsCompleted(int completed, int total) {
    return 'اكتملت $completed من $total مادة';
  }

  @override
  String get homeFocusedToday => 'ركّزت اليوم';

  @override
  String homeSessionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جلسة',
      many: 'جلسة',
      few: 'جلسات',
      two: 'جلستان',
      one: 'جلسة',
      zero: 'جلسة',
    );
    return '$_temp0';
  }

  @override
  String get homeStartFocus => 'ابدأ التركيز';

  @override
  String get homeDayStreak => 'أيام متتالية';

  @override
  String get homeDailyTarget => 'الهدف اليومي';

  @override
  String get homeSubjectsStat => 'المواد';

  @override
  String get homeUpcomingToday => 'قادم اليوم';

  @override
  String get homeToday => 'اليوم';

  @override
  String get homeQuickActions => 'إجراءات سريعة';

  @override
  String get homeQuickFocusLabel => 'ابدأ التركيز';

  @override
  String get homeQuickFocusSubtitle => 'مؤقّت بومودورو';

  @override
  String get homeQuickAddTaskLabel => 'إضافة مهمة';

  @override
  String get homeQuickAddTaskSubtitle => 'خطّط ليومك';

  @override
  String get homeQuickScheduleLabel => 'الجدول';

  @override
  String get homeQuickScheduleSubtitle => 'جلسات الدراسة';

  @override
  String get homeQuickAiNotesLabel => 'ملاحظات الذكاء الاصطناعي';

  @override
  String get homeQuickAiNotesSubtitle => 'ملخّصات ذكية';

  @override
  String get homePremiumRecommended => 'موصى به';

  @override
  String get homePremiumUpgradeTitle => 'الترقية إلى Zakerly Premium';

  @override
  String get homePremiumBody =>
      'افتح موادًا غير محدودة، ورؤى تحليلية أسبوعية وشهرية معمّقة، وأهداف دراسية مخصّصة لبناء سلسلة إنجاز لا تنكسر.';

  @override
  String get homeViewSubscriptions => 'عرض الاشتراكات';

  @override
  String get onboardingSlide1Title => 'نظّم\nحياتك الدراسية';

  @override
  String get onboardingSlide1Subtitle =>
      'أدِر المواد والجداول والمهام والامتحانات في مكان واحد، وكن دائمًا على اطلاع بكل موعد نهائي.';

  @override
  String get onboardingSlide2Title => 'جلسات\nتركيز عميق';

  @override
  String get onboardingSlide2Subtitle =>
      'استخدم مؤقت بومودورو لبناء تركيز حاد، وتابع ساعات مذاكرتك وحافظ على سلسلة إنجازاتك.';

  @override
  String get onboardingSlide3Title => 'ملاحظات دراسية\nبالذكاء الاصطناعي';

  @override
  String get onboardingSlide3Subtitle =>
      'صوّر ملاحظات محاضراتك ودع الذكاء الاصطناعي ينشئ ملخصات وبطاقات مراجعة وأسئلة تدريبية.';

  @override
  String get onboardingGetStarted => 'لنبدأ';

  @override
  String get splashTagline => 'ذاكِر بذكاء. وابقَ مُركّزًا.';

  @override
  String get aiNotesTitle => 'ملاحظات الذكاء الاصطناعي';

  @override
  String get aiStudyPack => 'حزمة المراجعة';

  @override
  String get aiNotesStudio => 'استوديو ملاحظات الذكاء الاصطناعي';

  @override
  String get aiNotesStudioSubtitle =>
      'راجِع وأدِر حزم المراجعة المولّدة بالذكاء الاصطناعي';

  @override
  String aiSubjectName(String subject) {
    return 'المادة: $subject';
  }

  @override
  String aiPacksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حزمة',
      many: '$count حزمة',
      few: '$count حزم',
      two: 'حزمتان',
      one: 'حزمة واحدة',
      zero: 'لا حزم',
    );
    return '$_temp0';
  }

  @override
  String get aiYourSubject => 'مادتك';

  @override
  String get aiSubjectLabel => 'المادة';

  @override
  String get aiBrowsePacksTitle => 'تصفّح حزم المراجعة';

  @override
  String get aiBrowsePacksSubtitle =>
      'اختر مادة لمراجعة الملخصات والبطاقات وأسئلة الاختبار المولّدة من موادك بالذكاء الاصطناعي.';

  @override
  String get aiRecentPacksTitle => 'حزم المراجعة الأخيرة';

  @override
  String get aiRecentPacksSubtitle =>
      'افتح أي حزمة لمراجعة الملخص والبطاقات وأسئلة التدريب. اسحب أو اضغط حذف لإزالة واحدة.';

  @override
  String get aiPremiumFeature => 'ملاحظات الذكاء الاصطناعي ميزة مميّزة.';

  @override
  String get aiUpgradeToPremium => 'الترقية إلى Premium';

  @override
  String get aiNoSubjectsMessage =>
      'أنشئ مادة أولاً، ثم ولّد ملاحظات الذكاء الاصطناعي لها.';

  @override
  String get aiGoToSubjects => 'الذهاب إلى المواد';

  @override
  String get aiNoNotesYet => 'لا توجد ملاحظات ذكاء اصطناعي بعد';

  @override
  String get aiNoNotesYetHint =>
      'ارفع ملف PDF من صفحة المادة لتوليد أول حزمة مراجعة لك.';

  @override
  String get aiDeletePackTitle => 'حذف حزمة المراجعة؟';

  @override
  String get aiDeletePackMessage =>
      'سيؤدي هذا إلى إزالة الملخص والبطاقات وأسئلة الاختبار لهذه الحزمة نهائيًا.';

  @override
  String get aiDeletePackTooltip => 'حذف حزمة المراجعة';

  @override
  String aiCardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return '$_temp0';
  }

  @override
  String aiQuestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سؤال',
      many: '$count سؤالًا',
      few: '$count أسئلة',
      two: 'سؤالان',
      one: 'سؤال واحد',
      zero: 'لا أسئلة',
    );
    return '$_temp0';
  }

  @override
  String get aiReadyToReview => 'محتوى جاهز للمراجعة';

  @override
  String aiMinRead(int minutes) {
    return '$minutes د قراءة تقريبية';
  }

  @override
  String get aiSections => 'أقسام';

  @override
  String get aiCards => 'بطاقات';

  @override
  String get aiQuiz => 'أسئلة';

  @override
  String get aiTabSummary => 'ملخص';

  @override
  String get aiTabCards => 'بطاقات';

  @override
  String get aiTabQuiz => 'اختبار';

  @override
  String aiSectionLabel(int number) {
    return 'قسم $number';
  }

  @override
  String get aiNoSummaryTitle => 'لا يوجد ملخص';

  @override
  String get aiNoSummaryMessage => 'سيظهر الملخص هنا بعد توليد حزمة المراجعة.';

  @override
  String get aiNoFlashcardsTitle => 'لا توجد بطاقات';

  @override
  String get aiNoFlashcardsMessage => 'ستظهر بطاقات المراجعة هنا بعد التوليد.';

  @override
  String get aiNoQuestionsTitle => 'لا توجد أسئلة';

  @override
  String get aiNoQuestionsMessage => 'ستظهر أسئلة التدريب هنا بعد التوليد.';

  @override
  String aiCardCounter(int current, int total) {
    return 'بطاقة $current من $total';
  }

  @override
  String get aiQuestion => 'السؤال';

  @override
  String get aiAnswer => 'الإجابة';

  @override
  String get aiTapToRevealAnswer => 'اضغط لإظهار الإجابة';

  @override
  String get aiTapToHideAnswer => 'اضغط للعودة';

  @override
  String get aiPrevious => 'السابق';

  @override
  String get aiShowAnswer => 'إظهار الإجابة';

  @override
  String get aiHideAnswer => 'إخفاء الإجابة';

  @override
  String get aiNoAnswerAvailable => 'لا توجد إجابة.';

  @override
  String get analyticsTitle => 'الإحصائيات';

  @override
  String get analyticsFocusTrend => 'اتجاه التركيز';

  @override
  String get analyticsBySubject => 'حسب المادة';

  @override
  String get analyticsPerformanceScore => 'درجة الأداء';

  @override
  String get analyticsTotalFocusTime => 'إجمالي وقت التركيز';

  @override
  String analyticsMinutesTotal(int minutes) {
    return '$minutes دقيقة إجمالاً';
  }

  @override
  String get analyticsSessionsLabel => 'جلسات';

  @override
  String analyticsDurationHours(int hours) {
    return '$hours س';
  }

  @override
  String analyticsDurationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String analyticsDurationMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String analyticsMinutesShort(int minutes) {
    return '$minutes د';
  }

  @override
  String analyticsPercent(int percent) {
    return '$percent٪';
  }

  @override
  String get analyticsTasksDone => 'المهام المنجزة';

  @override
  String get analyticsDailyAvg => 'المعدل اليومي';

  @override
  String get analyticsScore => 'الدرجة';

  @override
  String get analyticsUnlockDeeperInsights => 'افتح رؤى أعمق';

  @override
  String get analyticsPremiumTrendsSubtitle =>
      'اتجاهات شهرية وسنوية مع الاشتراك المميّز.';

  @override
  String get analyticsUpgrade => 'ترقية';

  @override
  String get analyticsUnlockFullInsights => 'افتح الرؤى الكاملة';

  @override
  String get analyticsUpgradeToPremium => 'الترقية إلى المميّز';

  @override
  String get analyticsReturnToCurrentWeek => 'العودة إلى الأسبوع الحالي';

  @override
  String get analyticsPremiumAnalyticsTitle => 'التحليلات المميّزة';

  @override
  String get analyticsPremiumAnalyticsBody =>
      'رؤى الشهر والسنة متاحة لمستخدمي الاشتراك المميّز فقط. قم بالترقية لفتح اتجاهات ومقارنات أوسع.';

  @override
  String get analyticsRangeWeek => 'أسبوع';

  @override
  String get analyticsRangeMonth => 'شهر';

  @override
  String get analyticsRangeYear => 'سنة';

  @override
  String get analyticsPerformance => 'الأداء';

  @override
  String get analyticsSessions => 'الجلسات';

  @override
  String get analyticsFocusMin => 'دقائق التركيز';

  @override
  String get analyticsNoSubjectData => 'لا توجد بيانات مواد لهذه الفترة.';

  @override
  String get authLoginTitle => 'مرحبًا\nبعودتك';

  @override
  String get authLoginSubtitle => 'سجّل الدخول لتكمل رحلة تركيزك.';

  @override
  String get authRegisterTitle => 'إنشاء حساب';

  @override
  String get authRegisterSubtitle => 'ابدأ رحلتك نحو التفوق الدراسي';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authEmailHint => 'your@email.com';

  @override
  String get authEmailRequired => 'من فضلك أدخل بريدك الإلكتروني';

  @override
  String get authEmailInvalid => 'من فضلك أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authPasswordRequired => 'من فضلك أدخل كلمة المرور';

  @override
  String get authPasswordTooShort =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get authFullNameLabel => 'الاسم الكامل';

  @override
  String get authFullNameHint => 'محمد أحمد';

  @override
  String get authNameRequired => 'من فضلك أدخل اسمك';

  @override
  String get authConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get authConfirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get authPasswordsMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authForgotPasswordLink => 'هل نسيت كلمة المرور؟';

  @override
  String get authSignInButton => 'تسجيل الدخول';

  @override
  String get authNoAccountPrompt => 'ليس لديك حساب؟ ';

  @override
  String get authSignUpLink => 'إنشاء حساب';

  @override
  String get authHaveAccountPrompt => 'لديك حساب بالفعل؟ ';

  @override
  String get authSignInLink => 'تسجيل الدخول';

  @override
  String get authCreateAccountButton => 'إنشاء حساب';

  @override
  String get authContinueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get authOrDivider => 'أو';

  @override
  String get authForgotPasswordTitle => 'إعادة تعيين\nكلمة المرور 🔑';

  @override
  String get authForgotPasswordSubtitle =>
      'أدخل البريد الإلكتروني المرتبط بحسابك وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

  @override
  String get authSendResetLinkButton => 'إرسال رابط إعادة التعيين';

  @override
  String get authCheckEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String authResetLinkSentTo(String email) {
    return 'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى\n$email';
  }

  @override
  String get authBackToSignInButton => 'العودة إلى تسجيل الدخول';

  @override
  String get authResetPasswordAppBar => 'إعادة تعيين كلمة المرور';

  @override
  String get authResetPasswordSubtitle => 'اختر كلمة مرور جديدة لحسابك.';

  @override
  String get authNewPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get authNewPasswordHint => '8 أحرف على الأقل';

  @override
  String get authPasswordMinLength => '8 أحرف كحد أدنى';

  @override
  String get authUpdatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get authPasswordUpdated =>
      'تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن.';

  @override
  String get authResetLinkInvalid =>
      'رابط إعادة التعيين غير صالح أو منتهي الصلاحية.';

  @override
  String get authVerifyEmailAppBar => 'تأكيد البريد الإلكتروني';

  @override
  String get authEmailVerifiedSuccess => 'تم تأكيد البريد الإلكتروني بنجاح!';

  @override
  String get authContinueToLoginButton => 'المتابعة إلى تسجيل الدخول';

  @override
  String get authVerifyFailed => 'رابط التأكيد غير صالح أو منتهي الصلاحية.';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationsDeleteAllShown => 'حذف كل المعروض';

  @override
  String get notificationsEmptyTitle => 'صندوق الإشعارات فارغ';

  @override
  String get notificationsEmptySubtitle => 'سنُعلمك بتقدّمك في الدراسة.';

  @override
  String get notificationsDeleteAllTitle => 'حذف كل الإشعارات؟';

  @override
  String get notificationsDeleteAllMessage =>
      'سيُحذف كل إشعار من صندوق الإشعارات.';

  @override
  String get notificationsDeleteAllConfirm => 'حذف الكل';

  @override
  String get plannerTitle => 'المخطط اليومي';

  @override
  String get plannerTabTasks => 'المهام';

  @override
  String get plannerTabRevisions => 'المراجعات';

  @override
  String get plannerTabLectures => 'المحاضرات';

  @override
  String get plannerTabExams => 'الاختبارات';

  @override
  String get plannerEmptyTasks => 'لا توجد مهام لهذا اليوم.';

  @override
  String get plannerEmptyRevisions => 'لا توجد مراجعات لهذا اليوم.';

  @override
  String get plannerEmptyLectures => 'لا توجد محاضرات لهذا اليوم.';

  @override
  String get plannerEmptyExams => 'لا توجد اختبارات لهذا اليوم.';

  @override
  String get plannerAddNewPlan => 'إضافة خطة جديدة';

  @override
  String get plannerCategory => 'الفئة';

  @override
  String get plannerDetails => 'التفاصيل';

  @override
  String get plannerTitleLabel => 'العنوان';

  @override
  String get plannerTitleHint => 'مثال: الرياضيات الفصل الثالث';

  @override
  String get plannerTitleRequired => 'مطلوب';

  @override
  String get plannerNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get plannerNotesHint => 'وصف مختصر...';

  @override
  String get plannerTime => 'الوقت';

  @override
  String get plannerSetTime => 'تحديد الوقت';

  @override
  String get plannerSubject => 'المادة';

  @override
  String get plannerSubjectSelect => 'اختيار';

  @override
  String get plannerSubjectGeneral => 'عام';

  @override
  String get plannerSavePlan => 'حفظ الخطة';

  @override
  String get plannerReminder => 'تذكير';

  @override
  String get plannerReminderOff => 'بدون تذكير';

  @override
  String get plannerReminderAtTime => 'في وقت الحدث';

  @override
  String plannerReminderMinutesBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'قبل $minutes دقيقة',
      many: 'قبل $minutes دقيقة',
      few: 'قبل $minutes دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get plannerReminderHourBefore => 'قبل ساعة واحدة';

  @override
  String get plannerReminderDayBefore => 'قبل يوم واحد';

  @override
  String plannerReminderNotificationTitle(String title) {
    return 'تذكير: $title';
  }

  @override
  String plannerReminderNotificationBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'مستحق خلال $minutes دقيقة.',
      many: 'مستحق خلال $minutes دقيقة.',
      few: 'مستحق خلال $minutes دقائق.',
      two: 'مستحق خلال دقيقتين.',
      one: 'مستحق خلال دقيقة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String plannerDueNotificationTitle(String title) {
    return 'مستحق الآن: $title';
  }

  @override
  String get plannerDueNotificationBody => 'هذا مستحق الآن. لا تنسَ!';

  @override
  String get plannerTypeTask => 'مهمة';

  @override
  String get plannerTypeRevision => 'مراجعة';

  @override
  String get plannerTypeLecture => 'محاضرة';

  @override
  String get plannerTypeExam => 'اختبار';

  @override
  String get pomodoroFocusTimer => 'مؤقّت التركيز';

  @override
  String get pomodoroPhaseFocus => 'تركيز';

  @override
  String get pomodoroPhaseBreak => 'استراحة';

  @override
  String get pomodoroPhaseReady => 'جاهز';

  @override
  String get pomodoroGeneralFocus => 'تركيز عام';

  @override
  String get pomodoroGeneral => 'عام';

  @override
  String get pomodoroFocus => 'تركيز';

  @override
  String get pomodoroBreak => 'استراحة';

  @override
  String get pomodoroBreakModeLabel => 'نمط الاستراحة';

  @override
  String get pomodoroBreakModeCycles => 'جلسات متكررة';

  @override
  String get pomodoroBreakModeMiddle => 'استراحة في المنتصف';

  @override
  String get pomodoroBreakModeMiddleHint =>
      'استراحة واحدة في منتصف الجلسة، وباقي الوقت يُقسَّم إلى فترتي مذاكرة.';

  @override
  String pomodoroMinutesShort(int minutes) {
    return '$minutes د';
  }

  @override
  String pomodoroMinutesUnit(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get pomodoroStartSession => 'ابدأ الجلسة';

  @override
  String get pomodoroStop => 'إيقاف';

  @override
  String get pomodoroResume => 'استئناف';

  @override
  String get pomodoroPause => 'إيقاف مؤقت';

  @override
  String get pomodoroSessionSetup => 'إعداد الجلسة';

  @override
  String get pomodoroSessionLength => 'مدة الجلسة';

  @override
  String pomodoroSessionProgress(int done, int total) {
    return '$done/$total د';
  }

  @override
  String get pomodoroBreakStartTitle => 'وقت الراحة';

  @override
  String get pomodoroBreakStartBody => 'خد نفسك وارجع بتركيز أعلى.';

  @override
  String get pomodoroFocusStartTitle => 'نرجع نذاكر';

  @override
  String get pomodoroFocusStartBody => 'خلصت الراحة، يلا نكمّل مذاكرة.';

  @override
  String get pomodoroSessionDoneTitle => 'خلصت الجلسة!';

  @override
  String get pomodoroSessionDoneBody => 'أنهيت جلسة التركيز كاملة. أحسنت!';

  @override
  String get pomodoroLocked => 'مقفل';

  @override
  String get pomodoroSubject => 'المادة';

  @override
  String get pomodoroFocusTime => 'وقت التركيز';

  @override
  String get pomodoroSessions => 'الجلسات';

  @override
  String get pomodoroTodaysSessions => 'جلسات اليوم';

  @override
  String pomodoroSessionsTotal(int count) {
    return '$count بالإجمالي';
  }

  @override
  String get pomodoroNoSessionsToday => 'لا توجد جلسات اليوم بعد';

  @override
  String pomodoroSessionMinutesStatus(int minutes, String status) {
    return '$minutes دقيقة · $status';
  }

  @override
  String get pomodoroStatusCompleted => 'مكتملة';

  @override
  String get pomodoroStatusAborted => 'ملغاة';

  @override
  String get pomodoroStatusPaused => 'متوقفة مؤقتًا';

  @override
  String get pomodoroStatusActive => 'نشطة';

  @override
  String get pomodoroHistoryTitle => 'سجل التركيز';

  @override
  String get pomodoroHistoryLoadError => 'تعذّر تحميل سجل الجلسات.';

  @override
  String get pomodoroHistoryEmpty => 'لا توجد جلسات تركيز خلال آخر 30 يومًا.';

  @override
  String pomodoroMinutesFocus(int minutes) {
    return '$minutes دقيقة تركيز';
  }

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileSettings => 'الإعدادات';

  @override
  String get profileSettingsSubtitle => 'إدارة إجراءات الحساب والتفضيلات.';

  @override
  String get profileOverviewTitle => 'نظرة عامة';

  @override
  String get profileOverviewSubtitle => 'لمحة سريعة عن حسابك ووتيرة دراستك.';

  @override
  String get profileTotalPoints => 'إجمالي النقاط';

  @override
  String get profileCurrentStreak => 'السلسلة الحالية';

  @override
  String profileStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$count يوم',
    );
    return '$_temp0';
  }

  @override
  String get profileFocusSessions => 'جلسات التركيز';

  @override
  String get profilePlanStatus => 'حالة الخطة';

  @override
  String get profilePremium => 'بريميوم';

  @override
  String get profileFree => 'مجاني';

  @override
  String get profileAccountTitle => 'الحساب';

  @override
  String get profileAccountSubtitle =>
      'البريد الإلكتروني والتحقق والاشتراك وتسجيل الخروج.';

  @override
  String get profileEmailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get profileNoEmail => 'لا يوجد بريد إلكتروني متاح';

  @override
  String get profileCurrentPlan => 'الخطة الحالية';

  @override
  String get profileDailyPlanner => 'المخطط اليومي';

  @override
  String get profileDailyPlannerSubtitle =>
      'المهام والمراجعات والمحاضرات والامتحانات.';

  @override
  String get profileAiNotes => 'ملاحظات الذكاء الاصطناعي';

  @override
  String get profileAiNotesSubtitle => 'إنشاء الملخّصات والبطاقات التعليمية.';

  @override
  String get profileCancelSubscription => 'إلغاء الاشتراك';

  @override
  String get profileCancelSubscriptionSubtitle =>
      'إيقاف التجديد في نهاية فترة الفوترة';

  @override
  String get profileLogout => 'تسجيل الخروج';

  @override
  String get profileLogoutSubtitle => 'تسجيل الخروج من هذا الجهاز.';

  @override
  String get profileLogoutTitle => 'تسجيل الخروج؟';

  @override
  String get profileLogoutMessage =>
      'ستحتاج إلى تسجيل الدخول مرة أخرى للوصول إلى لوحة دراستك.';

  @override
  String get profileFreePlan => 'الخطة المجانية';

  @override
  String get profilePremiumPlan => 'الخطة المميّزة';

  @override
  String get profileDefaultName => 'طالب Zakerly';

  @override
  String get profileVerified => 'موثّق';

  @override
  String get profileUnverified => 'غير موثّق';

  @override
  String get profileHeroDescription =>
      'حسابك جاهز لجلسات تركيز، وتخطيط منظّم، وتتبّع تقدّمك على المدى الطويل.';

  @override
  String get profileEditProfile => 'تعديل الملف الشخصي';

  @override
  String get profileEditProfileSubtitle =>
      'حدّث صورة ملفك الشخصي واسمك وإعدادات الأمان.';

  @override
  String get profileVerification => 'التحقق';

  @override
  String get profileVerificationPending => 'قيد الانتظار — وثّق حسابك لحمايته.';

  @override
  String get profileResend => 'إعادة الإرسال';

  @override
  String get profileVerificationEmailSent =>
      'تم إرسال بريد التحقق. تحقّق من صندوق الوارد.';

  @override
  String get profileVerificationEmailError =>
      'تعذّر إرسال البريد الإلكتروني. يرجى المحاولة مرة أخرى.';

  @override
  String get profilePhotoAccessBlocked =>
      'الوصول إلى الصور محظور. يرجى تفعيله من إعدادات التطبيق.';

  @override
  String get profilePhotoAccessRequired =>
      'الوصول إلى الصور مطلوب لاختيار صورة شخصية.';

  @override
  String get profilePhotoLibraryError => 'تعذّر فتح مكتبة الصور الآن.';

  @override
  String get profilePasswordResetSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';

  @override
  String get profilePasswordResetError =>
      'تعذّر إرسال رابط إعادة التعيين الآن.';

  @override
  String get profileChangePhoto => 'تغيير الصورة';

  @override
  String get profileDisplayName => 'الاسم الظاهر';

  @override
  String get profileDisplayNameHint => 'أدخل اسمك الكامل';

  @override
  String get profileNameRequired => 'الاسم مطلوب';

  @override
  String get profileNameTooShort => 'الاسم قصير جدًا';

  @override
  String get profileEmail => 'البريد الإلكتروني';

  @override
  String get profileEmailChangeUnavailable =>
      'تغيير البريد الإلكتروني غير متاح بعد.';

  @override
  String get profileSendPasswordReset => 'إرسال رابط إعادة تعيين كلمة المرور';

  @override
  String get profileSaveChanges => 'حفظ التغييرات';

  @override
  String get schedulesTitle => 'جدول المذاكرة';

  @override
  String get schedulesEmptyMessage => 'لا توجد جلسات مذاكرة مجدولة لهذا اليوم.';

  @override
  String get schedulesEmptyAddFirst => 'أضف أول جلسة لك';

  @override
  String get schedulesActionsTooltip => 'إجراءات الجدول';

  @override
  String get schedulesDeleteDialogTitle => 'حذف الجدول؟';

  @override
  String schedulesDeleteDialogMessage(String title) {
    return 'ستتم إزالة «$title» من جدول مذاكرتك.';
  }

  @override
  String get schedulesCreateBlockTitle => 'إنشاء فترة مذاكرة';

  @override
  String get schedulesEditBlockTitle => 'تعديل فترة المذاكرة';

  @override
  String get schedulesSubjectLabel => 'المادة';

  @override
  String get schedulesSelectSubjectHint => 'اختر المادة';

  @override
  String get schedulesFieldRequired => 'مطلوب';

  @override
  String get schedulesBlockTitleLabel => 'عنوان الفترة';

  @override
  String get schedulesBlockTitleHint => 'مثال: جلسة تركيز عميق';

  @override
  String get schedulesSelectedDayLabel => 'اليوم المحدّد';

  @override
  String get schedulesTimeRangeLabel => 'النطاق الزمني';

  @override
  String schedulesStartsAt(String time) {
    return 'يبدأ في $time';
  }

  @override
  String schedulesEndsAt(String time) {
    return 'ينتهي في $time';
  }

  @override
  String get schedulesStartTimePastError =>
      'لا يمكنك اختيار وقت بدء قبل الوقت الحالي.';

  @override
  String get schedulesEndAfterStartError =>
      'يجب أن يكون وقت الانتهاء بعد وقت البدء.';

  @override
  String get schedulesDaysOfWeekLabel => 'أيام الأسبوع';

  @override
  String get schedulesRemindersLabel => 'التذكيرات';

  @override
  String get schedulesReminderAtStart => 'عند وقت البدء';

  @override
  String schedulesReminderMinutesBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'قبل $minutes دقيقة',
      many: 'قبل $minutes دقيقة',
      few: 'قبل $minutes دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get schedulesCreateButton => 'إنشاء الجدول';

  @override
  String get schedulesPastDayError => 'لا يمكنك إنشاء جدول ليوم مضى.';

  @override
  String streaksDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم متتالٍ',
      many: '$count يومًا متتاليًا',
      few: '$count أيام متتالية',
      two: 'يومان متتاليان',
      one: 'يوم واحد متتالٍ',
      zero: '$count يوم متتالٍ',
    );
    return '$_temp0';
  }

  @override
  String streaksBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$count يوم',
    );
    return 'الأفضل: $_temp0';
  }

  @override
  String get streaksTotalPoints => 'إجمالي النقاط';

  @override
  String get streaksLastActive => 'آخر نشاط';

  @override
  String get streaksMilestones => 'الإنجازات';

  @override
  String streaksMilestoneDays(int days) {
    return '$days يوم';
  }

  @override
  String get subjectsTitle => 'المواد';

  @override
  String get subjectsNewSubject => 'مادة جديدة';

  @override
  String get subjectsHeroTitle => 'ابنِ خريطة دراستك';

  @override
  String get subjectsHeroSubtitle =>
      'نظّم كل مادة بلونها وأيقونتها وهدفها اليومي الخاص.';

  @override
  String subjectsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مادة نشطة',
      many: '$count مادة نشطة',
      few: '$count مواد نشطة',
      two: 'مادتان نشطتان',
      one: 'مادة نشطة واحدة',
      zero: 'لا مواد نشطة',
    );
    return '$_temp0';
  }

  @override
  String subjectsFreeCount(int count) {
    return '$count/3 مواد مجانية';
  }

  @override
  String get subjectsLoadErrorTitle => 'تعذّر تحميل المواد';

  @override
  String get subjectsEmptyTitle => 'لا توجد مواد بعد';

  @override
  String get subjectsEmptyDescription =>
      'أنشئ أول مادة لك لتبدأ تتبّع تقدّمك الدراسي وأهدافك اليومية.';

  @override
  String get subjectsCreateSubject => 'إنشاء مادة';

  @override
  String get subjectsEditSubject => 'تعديل المادة';

  @override
  String get subjectsEditorSubtitle =>
      'اختر اسمًا للمادة وأيقونة مميّزة وهدفًا يوميًا واقعيًا.';

  @override
  String get subjectsEditSubjectSubtitle =>
      'حدّث هوية المادة ولونها وأيقونتها وهدفها اليومي.';

  @override
  String get subjectsSubjectNameLabel => 'اسم المادة';

  @override
  String get subjectsSubjectNameHint => 'الفيزياء 101';

  @override
  String get subjectsNameRequired => 'يرجى إدخال اسم المادة';

  @override
  String get subjectsNameTooShort => 'اسم المادة قصير جدًا';

  @override
  String get subjectsColorLabel => 'اللون';

  @override
  String get subjectsIconLabel => 'الأيقونة';

  @override
  String get subjectsDailyTarget => 'الهدف اليومي';

  @override
  String get subjectsGoalTypeLabel => 'نوع الهدف';

  @override
  String get subjectsGoalDaily => 'يومي';

  @override
  String get subjectsGoalWeekly => 'أسبوعي';

  @override
  String get subjectsGoalTarget => 'الهدف';

  @override
  String get subjectsGoalDaysLabel => 'أيام الهدف (اختياري)';

  @override
  String get subjectsGoalDaysHint => 'اتركها فارغة لاحتساب كل الأيام.';

  @override
  String subjectsDailyTargetLabel(int minutes) {
    return 'هدف يومي $minutes دقيقة';
  }

  @override
  String subjectsMinutesValue(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String subjectsMinutesPlannedDaily(int minutes) {
    return '$minutes دقيقة مخطّطة كل يوم';
  }

  @override
  String get subjectsProgressLabel => 'التقدّم';

  @override
  String subjectsPercentValue(int percent) {
    return '$percent٪';
  }

  @override
  String get subjectsSaveChanges => 'حفظ التغييرات';

  @override
  String get subjectsArchive => 'أرشفة';

  @override
  String get subjectsArchiveTitle => 'أرشفة المادة؟';

  @override
  String subjectsArchiveMessage(String name) {
    return 'ستتم إزالة «$name» من قائمة المواد النشطة.';
  }

  @override
  String get subjectsFreeLimitTitle => 'تم بلوغ حد الخطة المجانية';

  @override
  String get subjectsDetailTitle => 'تفاصيل المادة';

  @override
  String get subjectsAddChapter => 'إضافة فصل';

  @override
  String get subjectsChaptersHeader => 'الفصول';

  @override
  String get subjectsChaptersSubtitle =>
      'تتبّع الوحدات التي أنهيتها وأبقِ تقدّمك واضحًا.';

  @override
  String get subjectsChaptersDone => 'الفصول المنجزة';

  @override
  String get subjectsEditChapter => 'تعديل الفصل';

  @override
  String get subjectsChapterTitleLabel => 'عنوان الفصل';

  @override
  String get subjectsFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get subjectsNoChaptersTitle => 'لا توجد فصول بعد';

  @override
  String get subjectsNoChaptersDescription =>
      'قسّم المادة إلى فصول واضحة ليصبح تتبّع التقدّم أسهل.';

  @override
  String get subjectsAddFirstChapter => 'إضافة أول فصل';

  @override
  String get subjectsAnalyzingPdf => 'جارٍ تحليل ملف PDF…';

  @override
  String get subjectsChapterCompleted => 'مكتمل';

  @override
  String get subjectsChapterInProgress => 'قيد التقدّم';

  @override
  String get subjectsAiStudyMaterialsTooltip => 'مواد دراسية بالذكاء الاصطناعي';

  @override
  String get subjectsAiCardTitle => 'مواد دراسية بالذكاء الاصطناعي';

  @override
  String get subjectsAiCardSubtitle =>
      'ارفع ملف PDF ودع الذكاء الاصطناعي يبني ملخّصًا وبطاقات تعليمية واختبارًا.';

  @override
  String get subjectsAnalyzing => 'جارٍ التحليل…';

  @override
  String get subjectsUploadPdf => 'رفع ملف PDF';

  @override
  String get subjectsView => 'عرض';

  @override
  String get subjectsAttachPdfHint =>
      'أرفِق ملف PDF (اختياري) للتحليل بالذكاء الاصطناعي';

  @override
  String get subjectsLanguageLabel => 'اللغة';

  @override
  String get subjectsSummaryLengthLabel => 'طول الملخّص';

  @override
  String get subjectsAnalyzePdfTitle => 'تحليل ملف PDF';

  @override
  String get subjectsAnalyzeWithAi => 'تحليل بالذكاء الاصطناعي';

  @override
  String get subjectsNoMaterials =>
      'لا توجد مواد بالذكاء الاصطناعي بعد. ارفع ملف PDF لإنشائها.';

  @override
  String get subscriptionAppBarTitle => 'Zakerly بريميوم';

  @override
  String get subscriptionRefreshStatus => 'تحديث الحالة';

  @override
  String get subscriptionHeroTitlePremium => 'أنت مشترك في بريميوم';

  @override
  String get subscriptionHeroTitleUpgrade => 'طوّر مسار دراستك';

  @override
  String get subscriptionHeroSubtitlePremium =>
      'جميع مزايا بريميوم مفعّلة في حسابك.';

  @override
  String get subscriptionHeroSubtitleUpgrade =>
      'أزل الحدود وافتح ملاحظات الذكاء الاصطناعي والتحليلات والمزيد.';

  @override
  String get subscriptionFeatureUnlimitedSubjects => 'مواد غير محدودة';

  @override
  String get subscriptionFeatureFullAnalytics => 'تحليلات كاملة';

  @override
  String get subscriptionFeatureAiNotes => 'ملاحظات دراسية بالذكاء الاصطناعي';

  @override
  String get subscriptionFeaturePriorityReminders => 'تذكيرات ذات أولوية';

  @override
  String get subscriptionChoosePaymentMethod => 'ادفع بالبطاقة';

  @override
  String get subscriptionPayPaymobMonthly => 'ادفع بالبطاقة — شهري (ج.م)';

  @override
  String get subscriptionPayPaymobYearly => 'ادفع بالبطاقة — سنوي (ج.م)';

  @override
  String get subscriptionPaymobNote => 'أدخل بيانات بطاقتك لإتمام الدفع بأمان.';

  @override
  String get subscriptionPayStripe => 'بطاقة دولية (Stripe)';

  @override
  String get subscriptionPremiumActiveTitle => 'بريميوم مفعّل';

  @override
  String get subscriptionPremiumCanceling => 'بريميوم (قيد الإلغاء)';

  @override
  String subscriptionStatusLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String subscriptionProviderLabel(String provider) {
    return 'مزوّد الخدمة: $provider';
  }

  @override
  String subscriptionAccessUntil(String date) {
    return 'الوصول حتى: $date';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'يتجدّد في: $date';
  }

  @override
  String get subscriptionCancelAction => 'إلغاء الاشتراك';

  @override
  String subscriptionRenewalCanceledUntil(String date) {
    return 'تم إلغاء التجديد. يستمر وصول بريميوم حتى $date.';
  }

  @override
  String get subscriptionRenewalCanceledPeriod =>
      'تم إلغاء التجديد. يبقى وصول بريميوم خلال هذه الفترة.';

  @override
  String get subscriptionCancelDialogTitle => 'إلغاء الاشتراك؟';

  @override
  String get subscriptionCancelDialogContent =>
      'سيتوقف اشتراكك عن التجديد. تحتفظ بوصول بريميوم حتى نهاية فترة الفوترة الحالية.';

  @override
  String get subscriptionKeepPremium => 'الاحتفاظ ببريميوم';

  @override
  String get subscriptionCanceled => 'تم إلغاء الاشتراك.';

  @override
  String get subscriptionCancelError => 'تعذّر إلغاء الاشتراك.';

  @override
  String get subscriptionPaymentNotCompleted => 'لم يكتمل الدفع.';

  @override
  String get subscriptionPremiumActive =>
      'بريميوم مفعّل الآن. استمتع بمسار دراستك المطوّر.';

  @override
  String get subscriptionPaymentReceived =>
      'تم استلام الدفع. قد يستغرق تفعيل بريميوم لحظات.';

  @override
  String get aiLoadSubjectsFailed => 'تعذّر تحميل المواد.';

  @override
  String get aiStudyPackDeleted => 'تم حذف حزمة المذاكرة.';

  @override
  String get aiDeleteStudyPackFailed => 'تعذّر حذف حزمة المذاكرة.';

  @override
  String get aiRateLimitReached =>
      'تم بلوغ الحد الأقصى لاستخدام الذكاء الاصطناعي. حاول لاحقًا.';

  @override
  String get analyticsLoadFailed => 'تعذّر تحميل بيانات الإحصائيات.';

  @override
  String get authGoogleTokenFailed =>
      'تعذّر الحصول على رمز تسجيل الدخول عبر Google. حاول مرة أخرى.';

  @override
  String get authGoogleSignInFailed =>
      'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';

  @override
  String get authServerUnreachable =>
      'تعذّر الوصول إلى الخادم. تحقّق من اتصالك بالإنترنت ثم حاول مرة أخرى.';

  @override
  String get authGenericRetry => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get homeLoadFailed => 'تعذّر تحميل بيانات الرئيسية.';

  @override
  String get notificationsLoadFailed => 'تعذّر تحميل الإشعارات';

  @override
  String get plannerLoadFailed => 'تعذّر تحميل العناصر لهذا اليوم.';

  @override
  String get plannerCreateSuccess => 'تم إنشاء العنصر بنجاح!';

  @override
  String get plannerCreateFailed => 'تعذّر إنشاء العنصر.';

  @override
  String get plannerCompleteSuccess => 'تم إكمال العنصر! حصلت على نقاط';

  @override
  String get plannerCompleteFailed => 'تعذّر إكمال العنصر.';

  @override
  String get plannerDeleteSuccess => 'تم حذف العنصر بنجاح.';

  @override
  String get plannerDeleteFailed => 'تعذّر حذف العنصر.';

  @override
  String get pomodoroLoadFailed => 'تعذّر تحميل بيانات التركيز.';

  @override
  String get pomodoroSessionStarted => 'بدأت جلسة التركيز.';

  @override
  String get pomodoroSessionRestored => 'تمت استعادة جلسة تركيز نشطة.';

  @override
  String get pomodoroStartFailed => 'تعذّر بدء الجلسة.';

  @override
  String get pomodoroSessionPaused => 'تم إيقاف الجلسة مؤقتًا.';

  @override
  String get pomodoroSessionResumed => 'تم استئناف الجلسة.';

  @override
  String get pomodoroSessionCompleted => 'اكتملت الجلسة بنجاح.';

  @override
  String get pomodoroSessionStopped => 'تم إيقاف الجلسة.';

  @override
  String get pomodoroTimeUpTitle => 'انتهى الوقت!';

  @override
  String get pomodoroBreakOverBody => 'أحسنت! خذ قسطًا من الراحة تستحقه.';

  @override
  String get schedulesLoadFailed => 'تعذّر تحميل الجداول.';

  @override
  String get schedulesCreateSuccess => 'تم إنشاء الجدول بنجاح!';

  @override
  String get schedulesCreateFailed => 'تعذّر إنشاء الجدول.';

  @override
  String get schedulesEditSuccess => 'تم تحديث الجدول بنجاح!';

  @override
  String get schedulesUpdateFailed => 'تعذّر تحديث الجدول.';

  @override
  String get schedulesCreateInvalidData =>
      'تعذّر إنشاء الجدول. يرجى التحقق من البيانات المحددة.';

  @override
  String get schedulesDeleteSuccess => 'تم حذف الجدول.';

  @override
  String get schedulesDeleteFailed => 'تعذّر حذف الجدول.';

  @override
  String schedulesReminderNotificationTitle(String title) {
    return 'تذكير بالمذاكرة: $title';
  }

  @override
  String schedulesReminderNotificationBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'تبدأ جلسة مذاكرتك بعد $minutes دقيقة.',
      many: 'تبدأ جلسة مذاكرتك بعد $minutes دقيقة.',
      few: 'تبدأ جلسة مذاكرتك بعد $minutes دقائق.',
      two: 'تبدأ جلسة مذاكرتك بعد دقيقتين.',
      one: 'تبدأ جلسة مذاكرتك بعد دقيقة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get streaksLoadFailed => 'تعذّر تحميل سلسلة الإنجاز.';

  @override
  String get subjectsLoadFailed => 'تعذّر تحميل المواد.';

  @override
  String get subjectsCreateSuccess => 'تم إنشاء المادة بنجاح.';

  @override
  String get subjectsCreateFailed => 'تعذّر إنشاء المادة.';

  @override
  String get subjectsUpdateSuccess => 'تم تحديث المادة بنجاح.';

  @override
  String get subjectsUpdateFailed => 'تعذّر تحديث المادة.';

  @override
  String get subjectsArchiveSuccess => 'تمت أرشفة المادة بنجاح.';

  @override
  String get subjectsArchiveFailed => 'تعذّر أرشفة المادة.';

  @override
  String get subjectsDetailLoadFailed => 'تعذّر تحميل تفاصيل المادة';

  @override
  String get subjectsChapterAddedAnalyzing =>
      'تمت إضافة الفصل. جارٍ تحليل ملف PDF…';

  @override
  String get subjectsChapterAddedSuccess => 'تمت إضافة الفصل بنجاح.';

  @override
  String get subjectsChapterAddFailed => 'تعذّر إضافة الفصل';

  @override
  String get subjectsChapterMaterialsReady =>
      'المواد الدراسية بالذكاء الاصطناعي جاهزة لهذا الفصل.';

  @override
  String get subjectsMaterialsReady =>
      'المواد الدراسية بالذكاء الاصطناعي جاهزة لهذه المادة.';

  @override
  String get subjectsAiJobFailed => 'فشلت مهمة الذكاء الاصطناعي.';

  @override
  String get subjectsAiAnalysisTimedOut => 'انتهت مهلة تحليل الذكاء الاصطناعي.';

  @override
  String get subjectsChapterUpdateSuccess => 'تم تحديث الفصل بنجاح.';

  @override
  String get subjectsChapterUpdateFailed => 'تعذّر تحديث الفصل';

  @override
  String get subjectsChapterUpdateFailedShort => 'تعذّر تحديث الفصل.';

  @override
  String get subjectsAnalyzePdfFailed => 'تعذّر تحليل ملف PDF.';

  @override
  String get subscriptionLoadFailed => 'تعذّر تحميل معلومات الاشتراك.';

  @override
  String get subscriptionPaymobSessionIncomplete =>
      'بيانات جلسة Paymob غير مكتملة. حاول مرة أخرى.';

  @override
  String get subscriptionPaymobUnavailable =>
      'خدمة الدفع عبر Paymob غير متاحة مؤقتاً. جرّب طريقة أخرى أو حاول لاحقاً.';

  @override
  String get subscriptionPaymentCompleted => 'تم الدفع بنجاح.';

  @override
  String get subscriptionPaymentPending => 'تم إرسال الدفع وهو قيد التأكيد.';

  @override
  String get subscriptionPaymentRejected => 'تم رفض الدفع.';

  @override
  String get subscriptionPaymentFailed => 'تعذّر إتمام الدفع.';

  @override
  String get subscriptionCheckoutFailed => 'تعذّر بدء الدفع عبر Paymob.';

  @override
  String get subscriptionStripeUnavailable =>
      'الدفع بالبطاقة غير متاح مؤقتاً. جرّب طريقة أخرى أو حاول لاحقاً.';

  @override
  String get subscriptionStripeBrowserPrompt =>
      'أكمل الدفع في المتصفح، ثم عُد واضغط على تحديث.';

  @override
  String get subscriptionPaymentPageFailed => 'تعذّر فتح صفحة الدفع.';

  @override
  String get subscriptionCardCheckoutFailed => 'تعذّر بدء الدفع بالبطاقة.';

  @override
  String get subscriptionCanceledEnded =>
      'تم إلغاء الاشتراك. انتهى وصول بريميوم.';
}
