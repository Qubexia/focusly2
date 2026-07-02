// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDone => 'Done';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSkip => 'Skip';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageTile => 'App language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsPremiumActive => 'Active';

  @override
  String get settingsPremiumUpgrade => 'Upgrade';

  @override
  String get settingsCancelSubscription => 'Cancel subscription';

  @override
  String get settingsCancelSubscriptionSubtitle => 'Stop renewal at period end';

  @override
  String get settingsAiNotes => 'AI Notes';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsStudyReminders => 'Study reminders';

  @override
  String get settingsStreakAlerts => 'Streak alerts';

  @override
  String get settingsProductUpdates => 'Product updates';

  @override
  String get settingsNotificationsSaved => 'Notification preferences saved';

  @override
  String get settingsFocusSection => 'Focus';

  @override
  String get settingsFocusMode => 'Focus mode';

  @override
  String get settingsFocusModeSubtitle => 'Reduce non-essential notifications';

  @override
  String get settingsActiveDevices => 'Active devices';

  @override
  String get settingsThisDevice => 'This device';

  @override
  String get settingsOtherDevice => 'Other device';

  @override
  String get settingsDangerZone => 'Danger zone';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'This permanently removes your data. Type DELETE to confirm.';

  @override
  String get homeNavHome => 'Home';

  @override
  String get homeNavSchedule => 'Schedule';

  @override
  String get homeNavFocus => 'Focus';

  @override
  String get homeNavStats => 'Stats';

  @override
  String get homeNavProfile => 'Profile';

  @override
  String get homeNavPlanner => 'Planner';

  @override
  String get homeDefaultName => 'Student';

  @override
  String get homeGreetingMorning => 'Good Morning';

  @override
  String get homeGreetingAfternoon => 'Good Afternoon';

  @override
  String get homeGreetingEvening => 'Good Evening';

  @override
  String homeGreetingName(String name) {
    return 'Hey $name 👋';
  }

  @override
  String get homeSubjectsTitle => 'Your Subjects';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeDashboardLoadErrorTitle => 'Could not load your dashboard';

  @override
  String get homeNoSubjectsTitle => 'No subjects yet';

  @override
  String get homeNoSubjectsSubtitle =>
      'Create your first subject to make the home screen useful and alive.';

  @override
  String get homeCreateSubject => 'Create Subject';

  @override
  String homeSubjectTargetMinutes(int minutes) {
    return '· ${minutes}m target';
  }

  @override
  String get homeStudyOverview => 'Study overview';

  @override
  String get homeOverallProgress => 'Overall progress';

  @override
  String get homeOverviewLoading => 'Pulling your subjects and targets…';

  @override
  String get homeOverviewEmpty => 'Add subjects to start tracking progress.';

  @override
  String homeSubjectsCompleted(int completed, int total) {
    return '$completed of $total subjects completed';
  }

  @override
  String get homeFocusedToday => 'focused today';

  @override
  String homeSessionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sessions',
      one: 'session',
    );
    return '$_temp0';
  }

  @override
  String get homeStartFocus => 'Start Focus';

  @override
  String get homeDayStreak => 'Day streak';

  @override
  String get homeDailyTarget => 'Daily target';

  @override
  String get homeSubjectsStat => 'Subjects';

  @override
  String get homeUpcomingToday => 'Upcoming today';

  @override
  String get homeToday => 'Today';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeQuickFocusLabel => 'Start Focus';

  @override
  String get homeQuickFocusSubtitle => 'Pomodoro timer';

  @override
  String get homeQuickAddTaskLabel => 'Add Task';

  @override
  String get homeQuickAddTaskSubtitle => 'Plan your day';

  @override
  String get homeQuickScheduleLabel => 'Schedule';

  @override
  String get homeQuickScheduleSubtitle => 'Study sessions';

  @override
  String get homeQuickAiNotesLabel => 'AI Notes';

  @override
  String get homeQuickAiNotesSubtitle => 'Smart summaries';

  @override
  String get homePremiumRecommended => 'RECOMMENDED';

  @override
  String get homePremiumUpgradeTitle => 'Upgrade to Zakerly Premium';

  @override
  String get homePremiumBody =>
      'Unlock unlimited subjects, deep weekly & monthly analytics insights, and personalized study targets to build an unbreakable streak.';

  @override
  String get homeViewSubscriptions => 'View Subscriptions';

  @override
  String get onboardingSlide1Title => 'Organize Your\nStudy Life';

  @override
  String get onboardingSlide1Subtitle =>
      'Manage subjects, schedules, tasks, and exams all in one place. Stay on top of every deadline.';

  @override
  String get onboardingSlide2Title => 'Deep Focus\nSessions';

  @override
  String get onboardingSlide2Subtitle =>
      'Use the Pomodoro timer to build laser-sharp focus. Track your study hours and build streaks.';

  @override
  String get onboardingSlide3Title => 'AI-Powered\nStudy Notes';

  @override
  String get onboardingSlide3Subtitle =>
      'Snap your lecture notes and let AI generate summaries, flashcards, and practice questions.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get splashTagline => 'Study smarter. Stay focused.';

  @override
  String get aiNotesTitle => 'AI Notes';

  @override
  String get aiStudyPack => 'Study Pack';

  @override
  String get aiNotesStudio => 'AI Notes Studio';

  @override
  String get aiNotesStudioSubtitle => 'Review and manage your AI study packs';

  @override
  String aiSubjectName(String subject) {
    return 'Subject: $subject';
  }

  @override
  String aiPacksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packs',
      one: '$count pack',
    );
    return '$_temp0';
  }

  @override
  String get aiYourSubject => 'Your subject';

  @override
  String get aiSubjectLabel => 'Subject';

  @override
  String get aiBrowsePacksTitle => 'Browse your study packs';

  @override
  String get aiBrowsePacksSubtitle =>
      'Choose a subject to review AI summaries, flashcards, and quiz questions generated from your materials.';

  @override
  String get aiRecentPacksTitle => 'Recent study packs';

  @override
  String get aiRecentPacksSubtitle =>
      'Open any pack to review the summary, flashcards, and practice questions. Swipe or tap delete to remove one.';

  @override
  String get aiPremiumFeature => 'AI Notes are a Premium feature.';

  @override
  String get aiUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get aiNoSubjectsMessage =>
      'Create a subject first, then generate AI notes for it.';

  @override
  String get aiGoToSubjects => 'Go to Subjects';

  @override
  String get aiNoNotesYet => 'No AI notes yet';

  @override
  String get aiNoNotesYetHint =>
      'Upload a PDF from a subject page to generate your first study pack.';

  @override
  String get aiDeletePackTitle => 'Delete study pack?';

  @override
  String get aiDeletePackMessage =>
      'This will permanently remove the summary, flashcards, and quiz questions for this pack.';

  @override
  String get aiDeletePackTooltip => 'Delete study pack';

  @override
  String aiCardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '$count card',
    );
    return '$_temp0';
  }

  @override
  String aiQuestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '$count question',
    );
    return '$_temp0';
  }

  @override
  String get aiReadyToReview => 'Ready to review';

  @override
  String aiMinRead(int minutes) {
    return '~$minutes min read';
  }

  @override
  String get aiSections => 'Sections';

  @override
  String get aiCards => 'Cards';

  @override
  String get aiQuiz => 'Quiz';

  @override
  String get aiTabSummary => 'Summary';

  @override
  String get aiTabCards => 'Cards';

  @override
  String get aiTabQuiz => 'Quiz';

  @override
  String aiSectionLabel(int number) {
    return 'Section $number';
  }

  @override
  String get aiNoSummaryTitle => 'No summary yet';

  @override
  String get aiNoSummaryMessage =>
      'Your AI summary will appear here once generated.';

  @override
  String get aiNoFlashcardsTitle => 'No flashcards yet';

  @override
  String get aiNoFlashcardsMessage =>
      'Flashcards will show up here once your pack is ready.';

  @override
  String get aiNoQuestionsTitle => 'No quiz questions yet';

  @override
  String get aiNoQuestionsMessage =>
      'Practice questions will appear here once generated.';

  @override
  String aiCardCounter(int current, int total) {
    return 'Card $current of $total';
  }

  @override
  String get aiQuestion => 'Question';

  @override
  String get aiAnswer => 'Answer';

  @override
  String get aiTapToRevealAnswer => 'Tap to reveal answer';

  @override
  String get aiTapToHideAnswer => 'Tap to hide answer';

  @override
  String get aiPrevious => 'Previous';

  @override
  String get aiShowAnswer => 'Show answer';

  @override
  String get aiHideAnswer => 'Hide answer';

  @override
  String get aiNoAnswerAvailable => 'No answer available.';

  @override
  String get analyticsTitle => 'Statistics';

  @override
  String get analyticsFocusTrend => 'Focus Trend';

  @override
  String get analyticsBySubject => 'By Subject';

  @override
  String get analyticsPerformanceScore => 'Performance Score';

  @override
  String get analyticsTotalFocusTime => 'Total Focus Time';

  @override
  String analyticsMinutesTotal(int minutes) {
    return '$minutes minutes total';
  }

  @override
  String get analyticsSessionsLabel => 'sessions';

  @override
  String analyticsDurationHours(int hours) {
    return '${hours}h';
  }

  @override
  String analyticsDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String analyticsDurationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String analyticsMinutesShort(int minutes) {
    return '$minutes m';
  }

  @override
  String analyticsPercent(int percent) {
    return '$percent%';
  }

  @override
  String get analyticsTasksDone => 'Tasks Done';

  @override
  String get analyticsDailyAvg => 'Daily Avg';

  @override
  String get analyticsScore => 'Score';

  @override
  String get analyticsUnlockDeeperInsights => 'Unlock deeper insights';

  @override
  String get analyticsPremiumTrendsSubtitle =>
      'Monthly & yearly trends with premium.';

  @override
  String get analyticsUpgrade => 'Upgrade';

  @override
  String get analyticsUnlockFullInsights => 'Unlock Full Insights';

  @override
  String get analyticsUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get analyticsReturnToCurrentWeek => 'Return to current week';

  @override
  String get analyticsPremiumAnalyticsTitle => 'Premium analytics';

  @override
  String get analyticsPremiumAnalyticsBody =>
      'Month and Year insights are available for premium users only. Upgrade to unlock broader trends and comparisons.';

  @override
  String get analyticsRangeWeek => 'Week';

  @override
  String get analyticsRangeMonth => 'Month';

  @override
  String get analyticsRangeYear => 'Year';

  @override
  String get analyticsPerformance => 'Performance';

  @override
  String get analyticsSessions => 'Sessions';

  @override
  String get analyticsFocusMin => 'Focus min';

  @override
  String get analyticsNoSubjectData => 'No subject data for this range.';

  @override
  String get authLoginTitle => 'Welcome\nBack';

  @override
  String get authLoginSubtitle => 'Login to continue your focus journey.';

  @override
  String get authRegisterTitle => 'Create Account';

  @override
  String get authRegisterSubtitle =>
      'Start your journey to academic excellence';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'your@email.com';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authFullNameLabel => 'Full Name';

  @override
  String get authFullNameHint => 'John Doe';

  @override
  String get authNameRequired => 'Please enter your name';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authConfirmPasswordHint => 'Repeat your password';

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get authForgotPasswordLink => 'Forgot Password?';

  @override
  String get authSignInButton => 'Sign In';

  @override
  String get authNoAccountPrompt => 'Don\'t have an account? ';

  @override
  String get authSignUpLink => 'Sign Up';

  @override
  String get authHaveAccountPrompt => 'Already have an account? ';

  @override
  String get authSignInLink => 'Sign In';

  @override
  String get authCreateAccountButton => 'Create Account';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authOrDivider => 'OR';

  @override
  String get authForgotPasswordTitle => 'Reset\nPassword 🔑';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter the email address associated with your account and we\'ll send you a link to reset your password.';

  @override
  String get authSendResetLinkButton => 'Send Reset Link';

  @override
  String get authCheckEmailTitle => 'Check Your Email';

  @override
  String authResetLinkSentTo(String email) {
    return 'We\'ve sent a password reset link to\n$email';
  }

  @override
  String get authBackToSignInButton => 'Back to Sign In';

  @override
  String get authResetPasswordAppBar => 'Reset password';

  @override
  String get authResetPasswordSubtitle =>
      'Choose a new password for your account.';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authNewPasswordHint => 'At least 8 characters';

  @override
  String get authPasswordMinLength => 'Min 8 characters';

  @override
  String get authUpdatePasswordButton => 'Update password';

  @override
  String get authPasswordUpdated => 'Password updated. You can sign in now.';

  @override
  String get authResetLinkInvalid => 'Invalid or expired reset link.';

  @override
  String get authVerifyEmailAppBar => 'Verify email';

  @override
  String get authEmailVerifiedSuccess => 'Email verified successfully!';

  @override
  String get authContinueToLoginButton => 'Continue to login';

  @override
  String get authVerifyFailed => 'Verification link is invalid or expired.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsDeleteAllShown => 'Delete all shown';

  @override
  String get notificationsEmptyTitle => 'Your inbox is empty';

  @override
  String get notificationsEmptySubtitle =>
      'We will notify you about your study progress.';

  @override
  String get notificationsDeleteAllTitle => 'Delete all notifications?';

  @override
  String get notificationsDeleteAllMessage =>
      'Each notification will be removed from your inbox.';

  @override
  String get notificationsDeleteAllConfirm => 'Delete all';

  @override
  String get plannerTitle => 'Daily Planner';

  @override
  String get plannerTabTasks => 'Tasks';

  @override
  String get plannerTabRevisions => 'Revisions';

  @override
  String get plannerTabLectures => 'Lectures';

  @override
  String get plannerTabExams => 'Exams';

  @override
  String get plannerEmptyTasks => 'No tasks for this day.';

  @override
  String get plannerEmptyRevisions => 'No revisions for this day.';

  @override
  String get plannerEmptyLectures => 'No lectures for this day.';

  @override
  String get plannerEmptyExams => 'No exams for this day.';

  @override
  String get plannerAddNewPlan => 'Add New Plan';

  @override
  String get plannerCategory => 'Category';

  @override
  String get plannerDetails => 'Details';

  @override
  String get plannerTitleLabel => 'Title';

  @override
  String get plannerTitleHint => 'e.g., Mathematics Chapter 3';

  @override
  String get plannerTitleRequired => 'Required';

  @override
  String get plannerNotesLabel => 'Notes (Optional)';

  @override
  String get plannerNotesHint => 'Brief description...';

  @override
  String get plannerTime => 'Time';

  @override
  String get plannerSetTime => 'Set Time';

  @override
  String get plannerSubject => 'Subject';

  @override
  String get plannerSubjectSelect => 'Select';

  @override
  String get plannerSubjectGeneral => 'General';

  @override
  String get plannerSavePlan => 'Save Plan';

  @override
  String get plannerReminder => 'Reminder';

  @override
  String get plannerReminderOff => 'No reminder';

  @override
  String get plannerReminderAtTime => 'At time of event';

  @override
  String plannerReminderMinutesBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String get plannerReminderHourBefore => '1 hour before';

  @override
  String get plannerReminderDayBefore => '1 day before';

  @override
  String plannerReminderNotificationTitle(String title) {
    return '⏰ Reminder: $title';
  }

  @override
  String plannerReminderNotificationBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Starts in $minutes minutes — get ready!',
      one: 'Starts in 1 minute — get ready!',
    );
    return '$_temp0';
  }

  @override
  String plannerDueNotificationTitle(String title) {
    return '📚 $title';
  }

  @override
  String get plannerDueNotificationBody => 'It\'s study time — let\'s go! ✨';

  @override
  String get plannerTypeTask => 'Task';

  @override
  String get plannerTypeRevision => 'Revision';

  @override
  String get plannerTypeLecture => 'Lecture';

  @override
  String get plannerTypeExam => 'Exam';

  @override
  String get pomodoroFocusTimer => 'Focus Timer';

  @override
  String get pomodoroPhaseFocus => 'FOCUS';

  @override
  String get pomodoroPhaseBreak => 'BREAK';

  @override
  String get pomodoroPhaseReady => 'READY';

  @override
  String get pomodoroGeneralFocus => 'General Focus';

  @override
  String get pomodoroGeneral => 'General';

  @override
  String get pomodoroFocus => 'Focus';

  @override
  String get pomodoroBreak => 'Break';

  @override
  String get pomodoroBreakModeLabel => 'Break style';

  @override
  String get pomodoroBreakModeCycles => 'Repeating cycles';

  @override
  String get pomodoroBreakModeMiddle => 'Break in the middle';

  @override
  String get pomodoroBreakModeMiddleHint =>
      'One break in the middle of the session; the rest is split into two study blocks.';

  @override
  String pomodoroMinutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String pomodoroMinutesUnit(int minutes) {
    return '$minutes min';
  }

  @override
  String get pomodoroStartSession => 'Start Session';

  @override
  String get pomodoroStop => 'Stop';

  @override
  String get pomodoroResume => 'Resume';

  @override
  String get pomodoroPause => 'Pause';

  @override
  String get pomodoroSessionSetup => 'Session Setup';

  @override
  String get pomodoroSessionLength => 'Session';

  @override
  String pomodoroSessionProgress(int done, int total) {
    return '$done/$total min';
  }

  @override
  String get pomodoroBreakStartTitle => 'Break time';

  @override
  String get pomodoroBreakStartBody => 'Step away and recharge.';

  @override
  String get pomodoroFocusStartTitle => 'Back to focus';

  @override
  String get pomodoroFocusStartBody => 'Break\'s over — keep studying.';

  @override
  String get pomodoroSessionDoneTitle => 'Session complete!';

  @override
  String get pomodoroSessionDoneBody => 'You finished your full focus session.';

  @override
  String get pomodoroLocked => 'Locked';

  @override
  String get pomodoroSubject => 'Subject';

  @override
  String get pomodoroFocusTime => 'Focus Time';

  @override
  String get pomodoroSessions => 'Sessions';

  @override
  String get pomodoroTodaysSessions => 'Today\'s Sessions';

  @override
  String pomodoroSessionsTotal(int count) {
    return '$count total';
  }

  @override
  String get pomodoroNoSessionsToday => 'No sessions yet today';

  @override
  String pomodoroSessionMinutesStatus(int minutes, String status) {
    return '$minutes min · $status';
  }

  @override
  String get pomodoroStatusCompleted => 'Completed';

  @override
  String get pomodoroStatusAborted => 'Aborted';

  @override
  String get pomodoroStatusPaused => 'Paused';

  @override
  String get pomodoroStatusActive => 'Active';

  @override
  String get pomodoroHistoryTitle => 'Focus History';

  @override
  String get pomodoroHistoryLoadError => 'Could not load session history.';

  @override
  String get pomodoroHistoryEmpty => 'No focus sessions in the last 30 days.';

  @override
  String pomodoroMinutesFocus(int minutes) {
    return '$minutes min focus';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSettingsSubtitle =>
      'Manage account actions and preferences.';

  @override
  String get profileOverviewTitle => 'Overview';

  @override
  String get profileOverviewSubtitle =>
      'A quick snapshot of your account and study pace.';

  @override
  String get profileTotalPoints => 'Total Points';

  @override
  String get profileCurrentStreak => 'Current Streak';

  @override
  String profileStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get profileFocusSessions => 'Focus Sessions';

  @override
  String get profilePlanStatus => 'Plan Status';

  @override
  String get profilePremium => 'Premium';

  @override
  String get profileFree => 'Free';

  @override
  String get profileAccountTitle => 'Account';

  @override
  String get profileAccountSubtitle =>
      'Email, verification, subscription, and sign out.';

  @override
  String get profileEmailAddress => 'Email Address';

  @override
  String get profileNoEmail => 'No email available';

  @override
  String get profileCurrentPlan => 'Current Plan';

  @override
  String get profileDailyPlanner => 'Daily Planner';

  @override
  String get profileDailyPlannerSubtitle =>
      'Tasks, revisions, lectures, and exams.';

  @override
  String get profileAiNotes => 'AI Notes';

  @override
  String get profileAiNotesSubtitle => 'Generate summaries and flashcards.';

  @override
  String get profileCancelSubscription => 'Cancel subscription';

  @override
  String get profileCancelSubscriptionSubtitle =>
      'Stop renewal at the end of the billing period';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileLogoutSubtitle => 'Sign out from this device.';

  @override
  String get profileLogoutTitle => 'Log out?';

  @override
  String get profileLogoutMessage =>
      'You will need to sign in again to access your study dashboard.';

  @override
  String get profileFreePlan => 'Free plan';

  @override
  String get profilePremiumPlan => 'Premium plan';

  @override
  String get profileDefaultName => 'Zakerly Student';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileUnverified => 'Unverified';

  @override
  String get profileHeroDescription =>
      'Your account is ready for focused sessions, structured planning, and long-term progress tracking.';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileEditProfileSubtitle =>
      'Update your profile image, name, and security access.';

  @override
  String get profileVerification => 'Verification';

  @override
  String get profileVerificationPending =>
      'Pending — verify to secure your account.';

  @override
  String get profileResend => 'Resend';

  @override
  String get profileVerificationEmailSent =>
      'Verification email sent. Check your inbox.';

  @override
  String get profileVerificationEmailError =>
      'Could not send the email. Please try again.';

  @override
  String get profilePhotoAccessBlocked =>
      'Photo access is blocked. Please enable it from app settings.';

  @override
  String get profilePhotoAccessRequired =>
      'Photo access is required to choose an avatar.';

  @override
  String get profilePhotoLibraryError =>
      'Could not open your photo library right now.';

  @override
  String get profilePasswordResetSent =>
      'Password reset link sent to your email.';

  @override
  String get profilePasswordResetError =>
      'Could not send reset link right now.';

  @override
  String get profileChangePhoto => 'Change Photo';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileDisplayNameHint => 'Enter your full name';

  @override
  String get profileNameRequired => 'Name is required';

  @override
  String get profileNameTooShort => 'Name is too short';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileEmailChangeUnavailable =>
      'Email change is not available yet.';

  @override
  String get profileSendPasswordReset => 'Send Password Reset Link';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get schedulesTitle => 'Study Schedule';

  @override
  String get schedulesEmptyMessage => 'No study sessions scheduled for today.';

  @override
  String get schedulesEmptyAddFirst => 'Add your first session';

  @override
  String get schedulesActionsTooltip => 'Schedule actions';

  @override
  String get schedulesDeleteDialogTitle => 'Delete schedule?';

  @override
  String schedulesDeleteDialogMessage(String title) {
    return '“$title” will be removed from your study schedule.';
  }

  @override
  String get schedulesCreateBlockTitle => 'Create Study Block';

  @override
  String get schedulesEditBlockTitle => 'Edit Study Block';

  @override
  String get schedulesSubjectLabel => 'Subject';

  @override
  String get schedulesSelectSubjectHint => 'Select Subject';

  @override
  String get schedulesFieldRequired => 'Required';

  @override
  String get schedulesBlockTitleLabel => 'Block Title';

  @override
  String get schedulesBlockTitleHint => 'e.g., Deep Work Session';

  @override
  String get schedulesSelectedDayLabel => 'Selected Day';

  @override
  String get schedulesTimeRangeLabel => 'Time Range';

  @override
  String schedulesStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String schedulesEndsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get schedulesStartTimePastError =>
      'You cannot choose a start time before the current time.';

  @override
  String get schedulesEndAfterStartError =>
      'End time must be after start time.';

  @override
  String get schedulesDaysOfWeekLabel => 'Days of Week';

  @override
  String get schedulesRemindersLabel => 'Reminders';

  @override
  String get schedulesReminderAtStart => 'At start time';

  @override
  String schedulesReminderMinutesBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String get schedulesCreateButton => 'Create Schedule';

  @override
  String get schedulesPastDayError =>
      'You cannot create a schedule for a past day.';

  @override
  String streaksDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '$count day streak',
      zero: '$count day streak',
    );
    return '$_temp0';
  }

  @override
  String streaksBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
      zero: '$count days',
    );
    return 'Best: $_temp0';
  }

  @override
  String get streaksTotalPoints => 'Total points';

  @override
  String get streaksLastActive => 'Last active';

  @override
  String get streaksMilestones => 'Milestones';

  @override
  String streaksMilestoneDays(int days) {
    return '${days}d';
  }

  @override
  String get subjectsTitle => 'Subjects';

  @override
  String get subjectsNewSubject => 'New Subject';

  @override
  String get subjectsHeroTitle => 'Build your study map';

  @override
  String get subjectsHeroSubtitle =>
      'Organize each subject with its own color, icon, and daily target.';

  @override
  String subjectsActiveCount(int count) {
    return '$count active subjects';
  }

  @override
  String subjectsFreeCount(int count) {
    return '$count/3 free subjects';
  }

  @override
  String get subjectsLoadErrorTitle => 'Could not load subjects';

  @override
  String get subjectsEmptyTitle => 'No subjects yet';

  @override
  String get subjectsEmptyDescription =>
      'Create your first subject to start tracking study progress and daily goals.';

  @override
  String get subjectsCreateSubject => 'Create Subject';

  @override
  String get subjectsEditSubject => 'Edit Subject';

  @override
  String get subjectsEditorSubtitle =>
      'Choose a subject name, a distinct icon, and a realistic daily goal.';

  @override
  String get subjectsEditSubjectSubtitle =>
      'Update the subject identity, color, icon, and daily target.';

  @override
  String get subjectsSubjectNameLabel => 'Subject Name';

  @override
  String get subjectsSubjectNameHint => 'Physics 101';

  @override
  String get subjectsNameRequired => 'Please enter a subject name';

  @override
  String get subjectsNameTooShort => 'Subject name is too short';

  @override
  String get subjectsColorLabel => 'Color';

  @override
  String get subjectsIconLabel => 'Icon';

  @override
  String get subjectsDailyTarget => 'Daily Target';

  @override
  String get subjectsGoalTypeLabel => 'Goal type';

  @override
  String get subjectsGoalDaily => 'Daily';

  @override
  String get subjectsGoalWeekly => 'Weekly';

  @override
  String get subjectsGoalTarget => 'Target';

  @override
  String get subjectsGoalDaysLabel => 'Goal days (optional)';

  @override
  String get subjectsGoalDaysHint => 'Leave empty to count every day.';

  @override
  String subjectsDailyTargetLabel(int minutes) {
    return '$minutes min daily target';
  }

  @override
  String subjectsMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String subjectsMinutesPlannedDaily(int minutes) {
    return '$minutes minutes planned every day';
  }

  @override
  String get subjectsProgressLabel => 'Progress';

  @override
  String subjectsPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get subjectsSaveChanges => 'Save Changes';

  @override
  String get subjectsArchive => 'Archive';

  @override
  String get subjectsArchiveTitle => 'Archive subject?';

  @override
  String subjectsArchiveMessage(String name) {
    return '“$name” will be removed from the active subjects list.';
  }

  @override
  String get subjectsFreeLimitTitle => 'Free plan limit reached';

  @override
  String get subjectsDetailTitle => 'Subject Detail';

  @override
  String get subjectsAddChapter => 'Add Chapter';

  @override
  String get subjectsChaptersHeader => 'Chapters';

  @override
  String get subjectsChaptersSubtitle =>
      'Track the units you have finished and keep momentum visible.';

  @override
  String get subjectsChaptersDone => 'Chapters Done';

  @override
  String get subjectsEditChapter => 'Edit Chapter';

  @override
  String get subjectsChapterTitleLabel => 'Chapter title';

  @override
  String get subjectsFieldRequired => 'This field is required';

  @override
  String get subjectsNoChaptersTitle => 'No chapters yet';

  @override
  String get subjectsNoChaptersDescription =>
      'Break the subject into clear chapters so progress becomes easier to track.';

  @override
  String get subjectsAddFirstChapter => 'Add First Chapter';

  @override
  String get subjectsAnalyzingPdf => 'Analyzing PDF…';

  @override
  String get subjectsChapterCompleted => 'Completed';

  @override
  String get subjectsChapterInProgress => 'In progress';

  @override
  String get subjectsAiStudyMaterialsTooltip => 'AI study materials';

  @override
  String get subjectsAiCardTitle => 'AI Study Materials';

  @override
  String get subjectsAiCardSubtitle =>
      'Upload a PDF and let AI build a summary, flashcards, and quiz.';

  @override
  String get subjectsAnalyzing => 'Analyzing…';

  @override
  String get subjectsUploadPdf => 'Upload PDF';

  @override
  String get subjectsView => 'View';

  @override
  String get subjectsAttachPdfHint => 'Attach a PDF (optional) for AI analysis';

  @override
  String get subjectsLanguageLabel => 'Language';

  @override
  String get subjectsSummaryLengthLabel => 'Summary length';

  @override
  String get subjectsAnalyzePdfTitle => 'Analyze PDF';

  @override
  String get subjectsAnalyzeWithAi => 'Analyze with AI';

  @override
  String get subjectsNoMaterials =>
      'No AI materials yet. Upload a PDF to generate them.';

  @override
  String get subscriptionAppBarTitle => 'Zakerly Premium';

  @override
  String get subscriptionRefreshStatus => 'Refresh status';

  @override
  String get subscriptionHeroTitlePremium => 'You are Premium';

  @override
  String get subscriptionHeroTitleUpgrade => 'Upgrade your study flow';

  @override
  String get subscriptionHeroSubtitlePremium =>
      'All premium features are unlocked on your account.';

  @override
  String get subscriptionHeroSubtitleUpgrade =>
      'Remove limits and unlock AI notes, analytics, and more.';

  @override
  String get subscriptionFeatureUnlimitedSubjects => 'Unlimited subjects';

  @override
  String get subscriptionFeatureFullAnalytics => 'Full analytics';

  @override
  String get subscriptionFeatureAiNotes => 'AI study notes';

  @override
  String get subscriptionFeaturePriorityReminders => 'Priority reminders';

  @override
  String get subscriptionChoosePaymentMethod => 'Pay with card';

  @override
  String get subscriptionPayPaymobMonthly => 'Pay with card — Monthly (EGP)';

  @override
  String get subscriptionPayPaymobYearly => 'Pay with card — Yearly (EGP)';

  @override
  String get subscriptionPaymobNote =>
      'Enter your card details to complete the payment securely.';

  @override
  String get subscriptionPayStripe => 'International card (Stripe)';

  @override
  String get subscriptionPremiumActiveTitle => 'Premium active';

  @override
  String get subscriptionPremiumCanceling => 'Premium (canceling)';

  @override
  String subscriptionStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String subscriptionProviderLabel(String provider) {
    return 'Provider: $provider';
  }

  @override
  String subscriptionAccessUntil(String date) {
    return 'Access until: $date';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'Renews: $date';
  }

  @override
  String get subscriptionCancelAction => 'Cancel subscription';

  @override
  String subscriptionRenewalCanceledUntil(String date) {
    return 'Renewal canceled. Premium access until $date.';
  }

  @override
  String get subscriptionRenewalCanceledPeriod =>
      'Renewal canceled. Premium access remains for this period.';

  @override
  String get subscriptionCancelDialogTitle => 'Cancel subscription?';

  @override
  String get subscriptionCancelDialogContent =>
      'Your subscription will stop renewing. You keep Premium access until the end of the current billing period.';

  @override
  String get subscriptionKeepPremium => 'Keep Premium';

  @override
  String get subscriptionCanceled => 'Subscription canceled.';

  @override
  String get subscriptionCancelError => 'Could not cancel subscription.';

  @override
  String get subscriptionPaymentNotCompleted => 'Payment was not completed.';

  @override
  String get subscriptionPremiumActive =>
      'Premium is active. Enjoy your upgraded study flow.';

  @override
  String get subscriptionPaymentReceived =>
      'Payment received. Premium may take a moment to activate.';

  @override
  String get aiLoadSubjectsFailed => 'Failed to load subjects.';

  @override
  String get aiStudyPackDeleted => 'Study pack deleted.';

  @override
  String get aiDeleteStudyPackFailed => 'Failed to delete study pack.';

  @override
  String get aiRateLimitReached => 'AI rate limit reached. Try again later.';

  @override
  String get analyticsLoadFailed => 'Failed to load analytics data.';

  @override
  String get authGoogleTokenFailed =>
      'Failed to get Google sign-in token. Please try again.';

  @override
  String get authGoogleSignInFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get authServerUnreachable =>
      'Cannot reach the server. Please check your internet connection and try again.';

  @override
  String get authGenericRetry => 'Something went wrong. Please try again.';

  @override
  String get homeLoadFailed => 'Failed to load home data.';

  @override
  String get notificationsLoadFailed => 'Failed to load notifications';

  @override
  String get plannerLoadFailed => 'Failed to load items for this date.';

  @override
  String get plannerCreateSuccess => 'Item created successfully!';

  @override
  String get plannerCreateFailed => 'Failed to create item.';

  @override
  String get plannerCompleteSuccess => 'Item completed! Points earned';

  @override
  String get plannerCompleteFailed => 'Failed to complete item.';

  @override
  String get plannerDeleteSuccess => 'Item deleted successfully.';

  @override
  String get plannerDeleteFailed => 'Failed to delete item.';

  @override
  String get pomodoroLoadFailed => 'Failed to load focus data.';

  @override
  String get pomodoroSessionStarted => 'Focus session started.';

  @override
  String get pomodoroSessionRestored => 'An active focus session was restored.';

  @override
  String get pomodoroStartFailed => 'Failed to start session.';

  @override
  String get pomodoroSessionPaused => 'Session paused.';

  @override
  String get pomodoroSessionResumed => 'Session resumed.';

  @override
  String get pomodoroSessionCompleted => 'Session completed successfully.';

  @override
  String get pomodoroSessionStopped => 'Session stopped.';

  @override
  String get pomodoroTimeUpTitle => 'Time is up!';

  @override
  String get pomodoroBreakOverBody => 'Great job! Take a well-deserved break.';

  @override
  String get schedulesLoadFailed => 'Failed to load schedules.';

  @override
  String get schedulesCreateSuccess => 'Schedule created successfully!';

  @override
  String get schedulesCreateFailed => 'Failed to create schedule.';

  @override
  String get schedulesEditSuccess => 'Schedule updated successfully!';

  @override
  String get schedulesUpdateFailed => 'Failed to update schedule.';

  @override
  String get schedulesCreateInvalidData =>
      'Failed to create schedule. Please check the selected data.';

  @override
  String get schedulesDeleteSuccess => 'Schedule deleted.';

  @override
  String get schedulesDeleteFailed => 'Failed to delete schedule.';

  @override
  String schedulesReminderNotificationTitle(String title) {
    return 'Study Reminder: $title';
  }

  @override
  String schedulesReminderNotificationBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Your study session starts in $minutes minutes.',
      one: 'Your study session starts in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get streaksLoadFailed => 'Failed to load streak.';

  @override
  String get subjectsLoadFailed => 'Failed to load subjects.';

  @override
  String get subjectsCreateSuccess => 'Subject created successfully.';

  @override
  String get subjectsCreateFailed => 'Failed to create subject.';

  @override
  String get subjectsUpdateSuccess => 'Subject updated successfully.';

  @override
  String get subjectsUpdateFailed => 'Failed to update subject.';

  @override
  String get subjectsArchiveSuccess => 'Subject archived successfully.';

  @override
  String get subjectsArchiveFailed => 'Failed to archive subject.';

  @override
  String get subjectsDetailLoadFailed => 'Failed to load subject details';

  @override
  String get subjectsChapterAddedAnalyzing =>
      'Chapter added. Analyzing the PDF…';

  @override
  String get subjectsChapterAddedSuccess => 'Chapter added successfully.';

  @override
  String get subjectsChapterAddFailed => 'Failed to add chapter';

  @override
  String get subjectsChapterMaterialsReady =>
      'AI study materials are ready for this chapter.';

  @override
  String get subjectsMaterialsReady =>
      'AI study materials are ready for this subject.';

  @override
  String get subjectsAiJobFailed => 'AI job failed.';

  @override
  String get subjectsAiAnalysisTimedOut => 'AI analysis timed out.';

  @override
  String get subjectsChapterUpdateSuccess => 'Chapter updated successfully.';

  @override
  String get subjectsChapterUpdateFailed => 'Failed to update chapter';

  @override
  String get subjectsChapterUpdateFailedShort => 'Failed to update chapter.';

  @override
  String get subjectsAnalyzePdfFailed => 'Failed to analyze the PDF.';

  @override
  String get subscriptionLoadFailed => 'Could not load subscription info.';

  @override
  String get subscriptionPaymobSessionIncomplete =>
      'Paymob session data is incomplete. Please try again.';

  @override
  String get subscriptionPaymobUnavailable =>
      'Paymob payments are temporarily unavailable. Please try another method or try again later.';

  @override
  String get subscriptionPaymentCompleted => 'Payment completed successfully.';

  @override
  String get subscriptionPaymentPending =>
      'Payment submitted and is pending confirmation.';

  @override
  String get subscriptionPaymentRejected => 'Payment was rejected.';

  @override
  String get subscriptionPaymentFailed => 'Could not complete the payment.';

  @override
  String get subscriptionCheckoutFailed => 'Could not start Paymob checkout.';

  @override
  String get subscriptionStripeUnavailable =>
      'Card payments are temporarily unavailable. Please try another method or try again later.';

  @override
  String get subscriptionStripeBrowserPrompt =>
      'Complete payment in the browser, then return and tap Refresh.';

  @override
  String get subscriptionPaymentPageFailed =>
      'Could not open the payment page.';

  @override
  String get subscriptionCardCheckoutFailed => 'Could not start card checkout.';

  @override
  String get subscriptionCanceledEnded =>
      'Subscription canceled. Premium access has ended.';
}
