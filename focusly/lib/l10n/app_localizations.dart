import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Native name of this locale, shown in the language picker
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageTile.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageTile;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get settingsPremium;

  /// No description provided for @settingsPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsPremiumActive;

  /// No description provided for @settingsPremiumUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsPremiumUpgrade;

  /// No description provided for @settingsCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get settingsCancelSubscription;

  /// No description provided for @settingsCancelSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop renewal at period end'**
  String get settingsCancelSubscriptionSubtitle;

  /// No description provided for @settingsAiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI Notes'**
  String get settingsAiNotes;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsStudyReminders.
  ///
  /// In en, this message translates to:
  /// **'Study reminders'**
  String get settingsStudyReminders;

  /// No description provided for @settingsStreakAlerts.
  ///
  /// In en, this message translates to:
  /// **'Streak alerts'**
  String get settingsStreakAlerts;

  /// No description provided for @settingsProductUpdates.
  ///
  /// In en, this message translates to:
  /// **'Product updates'**
  String get settingsProductUpdates;

  /// No description provided for @settingsNotificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences saved'**
  String get settingsNotificationsSaved;

  /// No description provided for @settingsFocusSection.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get settingsFocusSection;

  /// No description provided for @settingsFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get settingsFocusMode;

  /// No description provided for @settingsFocusModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce non-essential notifications'**
  String get settingsFocusModeSubtitle;

  /// No description provided for @settingsActiveDevices.
  ///
  /// In en, this message translates to:
  /// **'Active devices'**
  String get settingsActiveDevices;

  /// No description provided for @settingsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsThisDevice;

  /// No description provided for @settingsOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Other device'**
  String get settingsOtherDevice;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountConfirmTitle;

  /// No description provided for @settingsDeleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your data. Type DELETE to confirm.'**
  String get settingsDeleteAccountConfirmBody;

  /// No description provided for @homeNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavHome;

  /// No description provided for @homeNavSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get homeNavSchedule;

  /// No description provided for @homeNavFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get homeNavFocus;

  /// No description provided for @homeNavStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get homeNavStats;

  /// No description provided for @homeNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeNavProfile;

  /// No description provided for @homeNavPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get homeNavPlanner;

  /// No description provided for @homeDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get homeDefaultName;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingName.
  ///
  /// In en, this message translates to:
  /// **'Hey {name} 👋'**
  String homeGreetingName(String name);

  /// No description provided for @homeSubjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Subjects'**
  String get homeSubjectsTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeDashboardLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load your dashboard'**
  String get homeDashboardLoadErrorTitle;

  /// No description provided for @homeNoSubjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'No subjects yet'**
  String get homeNoSubjectsTitle;

  /// No description provided for @homeNoSubjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first subject to make the home screen useful and alive.'**
  String get homeNoSubjectsSubtitle;

  /// No description provided for @homeCreateSubject.
  ///
  /// In en, this message translates to:
  /// **'Create Subject'**
  String get homeCreateSubject;

  /// No description provided for @homeSubjectTargetMinutes.
  ///
  /// In en, this message translates to:
  /// **'· {minutes}m target'**
  String homeSubjectTargetMinutes(int minutes);

  /// No description provided for @homeStudyOverview.
  ///
  /// In en, this message translates to:
  /// **'Study overview'**
  String get homeStudyOverview;

  /// No description provided for @homeOverallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get homeOverallProgress;

  /// No description provided for @homeOverviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Pulling your subjects and targets…'**
  String get homeOverviewLoading;

  /// No description provided for @homeOverviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add subjects to start tracking progress.'**
  String get homeOverviewEmpty;

  /// No description provided for @homeSubjectsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} subjects completed'**
  String homeSubjectsCompleted(int completed, int total);

  /// No description provided for @homeFocusedToday.
  ///
  /// In en, this message translates to:
  /// **'focused today'**
  String get homeFocusedToday;

  /// No description provided for @homeSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{session} other{sessions}}'**
  String homeSessionsLabel(int count);

  /// No description provided for @homeStartFocus.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get homeStartFocus;

  /// No description provided for @homeDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get homeDayStreak;

  /// No description provided for @homeDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get homeDailyTarget;

  /// No description provided for @homeSubjectsStat.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get homeSubjectsStat;

  /// No description provided for @homeUpcomingToday.
  ///
  /// In en, this message translates to:
  /// **'Upcoming today'**
  String get homeUpcomingToday;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeQuickFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Focus'**
  String get homeQuickFocusLabel;

  /// No description provided for @homeQuickFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro timer'**
  String get homeQuickFocusSubtitle;

  /// No description provided for @homeQuickAddTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get homeQuickAddTaskLabel;

  /// No description provided for @homeQuickAddTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get homeQuickAddTaskSubtitle;

  /// No description provided for @homeQuickScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get homeQuickScheduleLabel;

  /// No description provided for @homeQuickScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Study sessions'**
  String get homeQuickScheduleSubtitle;

  /// No description provided for @homeQuickAiNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Notes'**
  String get homeQuickAiNotesLabel;

  /// No description provided for @homeQuickAiNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart summaries'**
  String get homeQuickAiNotesSubtitle;

  /// No description provided for @homePremiumRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get homePremiumRecommended;

  /// No description provided for @homePremiumUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Zakerly Premium'**
  String get homePremiumUpgradeTitle;

  /// No description provided for @homePremiumBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited subjects, deep weekly & monthly analytics insights, and personalized study targets to build an unbreakable streak.'**
  String get homePremiumBody;

  /// No description provided for @homeViewSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'View Subscriptions'**
  String get homeViewSubscriptions;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Organize Your\nStudy Life'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage subjects, schedules, tasks, and exams all in one place. Stay on top of every deadline.'**
  String get onboardingSlide1Subtitle;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Deep Focus\nSessions'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the Pomodoro timer to build laser-sharp focus. Track your study hours and build streaks.'**
  String get onboardingSlide2Subtitle;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered\nStudy Notes'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap your lecture notes and let AI generate summaries, flashcards, and practice questions.'**
  String get onboardingSlide3Subtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Study smarter. Stay focused.'**
  String get splashTagline;

  /// No description provided for @aiNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Notes'**
  String get aiNotesTitle;

  /// No description provided for @aiStudyPack.
  ///
  /// In en, this message translates to:
  /// **'Study Pack'**
  String get aiStudyPack;

  /// No description provided for @aiNotesStudio.
  ///
  /// In en, this message translates to:
  /// **'AI Notes Studio'**
  String get aiNotesStudio;

  /// No description provided for @aiNotesStudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage your AI study packs'**
  String get aiNotesStudioSubtitle;

  /// No description provided for @aiSubjectName.
  ///
  /// In en, this message translates to:
  /// **'Subject: {subject}'**
  String aiSubjectName(String subject);

  /// No description provided for @aiPacksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} pack} other{{count} packs}}'**
  String aiPacksCount(int count);

  /// No description provided for @aiYourSubject.
  ///
  /// In en, this message translates to:
  /// **'Your subject'**
  String get aiYourSubject;

  /// No description provided for @aiSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get aiSubjectLabel;

  /// No description provided for @aiBrowsePacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse your study packs'**
  String get aiBrowsePacksTitle;

  /// No description provided for @aiBrowsePacksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject to review AI summaries, flashcards, and quiz questions generated from your materials.'**
  String get aiBrowsePacksSubtitle;

  /// No description provided for @aiRecentPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent study packs'**
  String get aiRecentPacksTitle;

  /// No description provided for @aiRecentPacksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open any pack to review the summary, flashcards, and practice questions. Swipe or tap delete to remove one.'**
  String get aiRecentPacksSubtitle;

  /// No description provided for @aiPremiumFeature.
  ///
  /// In en, this message translates to:
  /// **'AI Notes are a Premium feature.'**
  String get aiPremiumFeature;

  /// No description provided for @aiUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get aiUpgradeToPremium;

  /// No description provided for @aiNoSubjectsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a subject first, then generate AI notes for it.'**
  String get aiNoSubjectsMessage;

  /// No description provided for @aiGoToSubjects.
  ///
  /// In en, this message translates to:
  /// **'Go to Subjects'**
  String get aiGoToSubjects;

  /// No description provided for @aiNoNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No AI notes yet'**
  String get aiNoNotesYet;

  /// No description provided for @aiNoNotesYetHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF from a subject page to generate your first study pack.'**
  String get aiNoNotesYetHint;

  /// No description provided for @aiDeletePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete study pack?'**
  String get aiDeletePackTitle;

  /// No description provided for @aiDeletePackMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the summary, flashcards, and quiz questions for this pack.'**
  String get aiDeletePackMessage;

  /// No description provided for @aiDeletePackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete study pack'**
  String get aiDeletePackTooltip;

  /// No description provided for @aiCardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} card} other{{count} cards}}'**
  String aiCardsCount(int count);

  /// No description provided for @aiQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} question} other{{count} questions}}'**
  String aiQuestionsCount(int count);

  /// No description provided for @aiReadyToReview.
  ///
  /// In en, this message translates to:
  /// **'Ready to review'**
  String get aiReadyToReview;

  /// No description provided for @aiMinRead.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min read'**
  String aiMinRead(int minutes);

  /// No description provided for @aiSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get aiSections;

  /// No description provided for @aiCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get aiCards;

  /// No description provided for @aiQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get aiQuiz;

  /// No description provided for @aiTabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get aiTabSummary;

  /// No description provided for @aiTabCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get aiTabCards;

  /// No description provided for @aiTabQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get aiTabQuiz;

  /// No description provided for @aiSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Section {number}'**
  String aiSectionLabel(int number);

  /// No description provided for @aiNoSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'No summary yet'**
  String get aiNoSummaryTitle;

  /// No description provided for @aiNoSummaryMessage.
  ///
  /// In en, this message translates to:
  /// **'Your AI summary will appear here once generated.'**
  String get aiNoSummaryMessage;

  /// No description provided for @aiNoFlashcardsTitle.
  ///
  /// In en, this message translates to:
  /// **'No flashcards yet'**
  String get aiNoFlashcardsTitle;

  /// No description provided for @aiNoFlashcardsMessage.
  ///
  /// In en, this message translates to:
  /// **'Flashcards will show up here once your pack is ready.'**
  String get aiNoFlashcardsMessage;

  /// No description provided for @aiNoQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No quiz questions yet'**
  String get aiNoQuestionsTitle;

  /// No description provided for @aiNoQuestionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Practice questions will appear here once generated.'**
  String get aiNoQuestionsMessage;

  /// No description provided for @aiCardCounter.
  ///
  /// In en, this message translates to:
  /// **'Card {current} of {total}'**
  String aiCardCounter(int current, int total);

  /// No description provided for @aiQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get aiQuestion;

  /// No description provided for @aiAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get aiAnswer;

  /// No description provided for @aiTapToRevealAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal answer'**
  String get aiTapToRevealAnswer;

  /// No description provided for @aiTapToHideAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap to hide answer'**
  String get aiTapToHideAnswer;

  /// No description provided for @aiPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get aiPrevious;

  /// No description provided for @aiShowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get aiShowAnswer;

  /// No description provided for @aiHideAnswer.
  ///
  /// In en, this message translates to:
  /// **'Hide answer'**
  String get aiHideAnswer;

  /// No description provided for @aiNoAnswerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No answer available.'**
  String get aiNoAnswerAvailable;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get analyticsTitle;

  /// No description provided for @analyticsFocusTrend.
  ///
  /// In en, this message translates to:
  /// **'Focus Trend'**
  String get analyticsFocusTrend;

  /// No description provided for @analyticsBySubject.
  ///
  /// In en, this message translates to:
  /// **'By Subject'**
  String get analyticsBySubject;

  /// No description provided for @analyticsPerformanceScore.
  ///
  /// In en, this message translates to:
  /// **'Performance Score'**
  String get analyticsPerformanceScore;

  /// No description provided for @analyticsTotalFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Total Focus Time'**
  String get analyticsTotalFocusTime;

  /// No description provided for @analyticsMinutesTotal.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes total'**
  String analyticsMinutesTotal(int minutes);

  /// No description provided for @analyticsSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get analyticsSessionsLabel;

  /// No description provided for @analyticsDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String analyticsDurationHours(int hours);

  /// No description provided for @analyticsDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String analyticsDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @analyticsDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String analyticsDurationMinutes(int minutes);

  /// No description provided for @analyticsMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} m'**
  String analyticsMinutesShort(int minutes);

  /// No description provided for @analyticsPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String analyticsPercent(int percent);

  /// No description provided for @analyticsTasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks Done'**
  String get analyticsTasksDone;

  /// No description provided for @analyticsDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily Avg'**
  String get analyticsDailyAvg;

  /// No description provided for @analyticsScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get analyticsScore;

  /// No description provided for @analyticsUnlockDeeperInsights.
  ///
  /// In en, this message translates to:
  /// **'Unlock deeper insights'**
  String get analyticsUnlockDeeperInsights;

  /// No description provided for @analyticsPremiumTrendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly & yearly trends with premium.'**
  String get analyticsPremiumTrendsSubtitle;

  /// No description provided for @analyticsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get analyticsUpgrade;

  /// No description provided for @analyticsUnlockFullInsights.
  ///
  /// In en, this message translates to:
  /// **'Unlock Full Insights'**
  String get analyticsUnlockFullInsights;

  /// No description provided for @analyticsUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get analyticsUpgradeToPremium;

  /// No description provided for @analyticsReturnToCurrentWeek.
  ///
  /// In en, this message translates to:
  /// **'Return to current week'**
  String get analyticsReturnToCurrentWeek;

  /// No description provided for @analyticsPremiumAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium analytics'**
  String get analyticsPremiumAnalyticsTitle;

  /// No description provided for @analyticsPremiumAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Month and Year insights are available for premium users only. Upgrade to unlock broader trends and comparisons.'**
  String get analyticsPremiumAnalyticsBody;

  /// No description provided for @analyticsRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get analyticsRangeWeek;

  /// No description provided for @analyticsRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get analyticsRangeMonth;

  /// No description provided for @analyticsRangeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get analyticsRangeYear;

  /// No description provided for @analyticsPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get analyticsPerformance;

  /// No description provided for @analyticsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get analyticsSessions;

  /// No description provided for @analyticsFocusMin.
  ///
  /// In en, this message translates to:
  /// **'Focus min'**
  String get analyticsFocusMin;

  /// No description provided for @analyticsNoSubjectData.
  ///
  /// In en, this message translates to:
  /// **'No subject data for this range.'**
  String get analyticsNoSubjectData;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nBack'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to continue your focus journey.'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your journey to academic excellence'**
  String get authRegisterSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get authEmailHint;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get authFullNameHint;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authNameRequired;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsMismatch;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPasswordLink;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInButton;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccountPrompt;

  /// No description provided for @authSignUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUpLink;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authHaveAccountPrompt;

  /// No description provided for @authSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInLink;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccountButton;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOrDivider;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset\nPassword 🔑'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address associated with your account and we\'ll send you a link to reset your password.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authSendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLinkButton;

  /// No description provided for @authCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get authCheckEmailTitle;

  /// No description provided for @authResetLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to\n{email}'**
  String authResetLinkSentTo(String email);

  /// No description provided for @authBackToSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get authBackToSignInButton;

  /// No description provided for @authResetPasswordAppBar.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordAppBar;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authNewPasswordHint;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authUpdatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authUpdatePasswordButton;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You can sign in now.'**
  String get authPasswordUpdated;

  /// No description provided for @authResetLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired reset link.'**
  String get authResetLinkInvalid;

  /// No description provided for @authVerifyEmailAppBar.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyEmailAppBar;

  /// No description provided for @authEmailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get authEmailVerifiedSuccess;

  /// No description provided for @authContinueToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to login'**
  String get authContinueToLoginButton;

  /// No description provided for @authVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification link is invalid or expired.'**
  String get authVerifyFailed;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsDeleteAllShown.
  ///
  /// In en, this message translates to:
  /// **'Delete all shown'**
  String get notificationsDeleteAllShown;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your inbox is empty'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will notify you about your study progress.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all notifications?'**
  String get notificationsDeleteAllTitle;

  /// No description provided for @notificationsDeleteAllMessage.
  ///
  /// In en, this message translates to:
  /// **'Each notification will be removed from your inbox.'**
  String get notificationsDeleteAllMessage;

  /// No description provided for @notificationsDeleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get notificationsDeleteAllConfirm;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Planner'**
  String get plannerTitle;

  /// No description provided for @plannerTabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get plannerTabTasks;

  /// No description provided for @plannerTabRevisions.
  ///
  /// In en, this message translates to:
  /// **'Revisions'**
  String get plannerTabRevisions;

  /// No description provided for @plannerTabLectures.
  ///
  /// In en, this message translates to:
  /// **'Lectures'**
  String get plannerTabLectures;

  /// No description provided for @plannerTabExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get plannerTabExams;

  /// No description provided for @plannerEmptyTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this day.'**
  String get plannerEmptyTasks;

  /// No description provided for @plannerEmptyRevisions.
  ///
  /// In en, this message translates to:
  /// **'No revisions for this day.'**
  String get plannerEmptyRevisions;

  /// No description provided for @plannerEmptyLectures.
  ///
  /// In en, this message translates to:
  /// **'No lectures for this day.'**
  String get plannerEmptyLectures;

  /// No description provided for @plannerEmptyExams.
  ///
  /// In en, this message translates to:
  /// **'No exams for this day.'**
  String get plannerEmptyExams;

  /// No description provided for @plannerAddNewPlan.
  ///
  /// In en, this message translates to:
  /// **'Add New Plan'**
  String get plannerAddNewPlan;

  /// No description provided for @plannerCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get plannerCategory;

  /// No description provided for @plannerDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get plannerDetails;

  /// No description provided for @plannerTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get plannerTitleLabel;

  /// No description provided for @plannerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mathematics Chapter 3'**
  String get plannerTitleHint;

  /// No description provided for @plannerTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get plannerTitleRequired;

  /// No description provided for @plannerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get plannerNotesLabel;

  /// No description provided for @plannerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description...'**
  String get plannerNotesHint;

  /// No description provided for @plannerTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get plannerTime;

  /// No description provided for @plannerSetTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get plannerSetTime;

  /// No description provided for @plannerSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get plannerSubject;

  /// No description provided for @plannerSubjectSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get plannerSubjectSelect;

  /// No description provided for @plannerSubjectGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get plannerSubjectGeneral;

  /// No description provided for @plannerSavePlan.
  ///
  /// In en, this message translates to:
  /// **'Save Plan'**
  String get plannerSavePlan;

  /// No description provided for @plannerTypeTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get plannerTypeTask;

  /// No description provided for @plannerTypeRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get plannerTypeRevision;

  /// No description provided for @plannerTypeLecture.
  ///
  /// In en, this message translates to:
  /// **'Lecture'**
  String get plannerTypeLecture;

  /// No description provided for @plannerTypeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get plannerTypeExam;

  /// No description provided for @pomodoroFocusTimer.
  ///
  /// In en, this message translates to:
  /// **'Focus Timer'**
  String get pomodoroFocusTimer;

  /// No description provided for @pomodoroPhaseFocus.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get pomodoroPhaseFocus;

  /// No description provided for @pomodoroPhaseBreak.
  ///
  /// In en, this message translates to:
  /// **'BREAK'**
  String get pomodoroPhaseBreak;

  /// No description provided for @pomodoroPhaseReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get pomodoroPhaseReady;

  /// No description provided for @pomodoroGeneralFocus.
  ///
  /// In en, this message translates to:
  /// **'General Focus'**
  String get pomodoroGeneralFocus;

  /// No description provided for @pomodoroGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get pomodoroGeneral;

  /// No description provided for @pomodoroFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pomodoroFocus;

  /// No description provided for @pomodoroBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get pomodoroBreak;

  /// No description provided for @pomodoroMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String pomodoroMinutesShort(int minutes);

  /// No description provided for @pomodoroMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String pomodoroMinutesUnit(int minutes);

  /// No description provided for @pomodoroStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get pomodoroStartSession;

  /// No description provided for @pomodoroStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get pomodoroStop;

  /// No description provided for @pomodoroResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get pomodoroResume;

  /// No description provided for @pomodoroPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pomodoroPause;

  /// No description provided for @pomodoroSessionSetup.
  ///
  /// In en, this message translates to:
  /// **'Session Setup'**
  String get pomodoroSessionSetup;

  /// No description provided for @pomodoroLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get pomodoroLocked;

  /// No description provided for @pomodoroSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get pomodoroSubject;

  /// No description provided for @pomodoroFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get pomodoroFocusTime;

  /// No description provided for @pomodoroSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get pomodoroSessions;

  /// No description provided for @pomodoroTodaysSessions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sessions'**
  String get pomodoroTodaysSessions;

  /// No description provided for @pomodoroSessionsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String pomodoroSessionsTotal(int count);

  /// No description provided for @pomodoroNoSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet today'**
  String get pomodoroNoSessionsToday;

  /// No description provided for @pomodoroSessionMinutesStatus.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {status}'**
  String pomodoroSessionMinutesStatus(int minutes, String status);

  /// No description provided for @pomodoroStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pomodoroStatusCompleted;

  /// No description provided for @pomodoroStatusAborted.
  ///
  /// In en, this message translates to:
  /// **'Aborted'**
  String get pomodoroStatusAborted;

  /// No description provided for @pomodoroStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pomodoroStatusPaused;

  /// No description provided for @pomodoroStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get pomodoroStatusActive;

  /// No description provided for @pomodoroHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus History'**
  String get pomodoroHistoryTitle;

  /// No description provided for @pomodoroHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load session history.'**
  String get pomodoroHistoryLoadError;

  /// No description provided for @pomodoroHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No focus sessions in the last 30 days.'**
  String get pomodoroHistoryEmpty;

  /// No description provided for @pomodoroMinutesFocus.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focus'**
  String pomodoroMinutesFocus(int minutes);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage account actions and preferences.'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get profileOverviewTitle;

  /// No description provided for @profileOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick snapshot of your account and study pace.'**
  String get profileOverviewSubtitle;

  /// No description provided for @profileTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get profileTotalPoints;

  /// No description provided for @profileCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get profileCurrentStreak;

  /// No description provided for @profileStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} day} other{{count} days}}'**
  String profileStreakDays(int count);

  /// No description provided for @profileFocusSessions.
  ///
  /// In en, this message translates to:
  /// **'Focus Sessions'**
  String get profileFocusSessions;

  /// No description provided for @profilePlanStatus.
  ///
  /// In en, this message translates to:
  /// **'Plan Status'**
  String get profilePlanStatus;

  /// No description provided for @profilePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get profilePremium;

  /// No description provided for @profileFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get profileFree;

  /// No description provided for @profileAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountTitle;

  /// No description provided for @profileAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Email, verification, subscription, and sign out.'**
  String get profileAccountSubtitle;

  /// No description provided for @profileEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get profileEmailAddress;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get profileNoEmail;

  /// No description provided for @profileCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get profileCurrentPlan;

  /// No description provided for @profileDailyPlanner.
  ///
  /// In en, this message translates to:
  /// **'Daily Planner'**
  String get profileDailyPlanner;

  /// No description provided for @profileDailyPlannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks, revisions, lectures, and exams.'**
  String get profileDailyPlannerSubtitle;

  /// No description provided for @profileAiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI Notes'**
  String get profileAiNotes;

  /// No description provided for @profileAiNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate summaries and flashcards.'**
  String get profileAiNotesSubtitle;

  /// No description provided for @profileCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get profileCancelSubscription;

  /// No description provided for @profileCancelSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop renewal at the end of the billing period'**
  String get profileCancelSubscriptionSubtitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @profileLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from this device.'**
  String get profileLogoutSubtitle;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your study dashboard.'**
  String get profileLogoutMessage;

  /// No description provided for @profileFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get profileFreePlan;

  /// No description provided for @profilePremiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium plan'**
  String get profilePremiumPlan;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Zakerly Student'**
  String get profileDefaultName;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get profileUnverified;

  /// No description provided for @profileHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready for focused sessions, structured planning, and long-term progress tracking.'**
  String get profileHeroDescription;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your profile image, name, and security access.'**
  String get profileEditProfileSubtitle;

  /// No description provided for @profileVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get profileVerification;

  /// No description provided for @profileVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending — verify to secure your account.'**
  String get profileVerificationPending;

  /// No description provided for @profileResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get profileResend;

  /// No description provided for @profileVerificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox.'**
  String get profileVerificationEmailSent;

  /// No description provided for @profileVerificationEmailError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the email. Please try again.'**
  String get profileVerificationEmailError;

  /// No description provided for @profilePhotoAccessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Photo access is blocked. Please enable it from app settings.'**
  String get profilePhotoAccessBlocked;

  /// No description provided for @profilePhotoAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo access is required to choose an avatar.'**
  String get profilePhotoAccessRequired;

  /// No description provided for @profilePhotoLibraryError.
  ///
  /// In en, this message translates to:
  /// **'Could not open your photo library right now.'**
  String get profilePhotoLibraryError;

  /// No description provided for @profilePasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get profilePasswordResetSent;

  /// No description provided for @profilePasswordResetError.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset link right now.'**
  String get profilePasswordResetError;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get profileChangePhoto;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get profileDisplayNameHint;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profileNameRequired;

  /// No description provided for @profileNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get profileNameTooShort;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileEmailChangeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email change is not available yet.'**
  String get profileEmailChangeUnavailable;

  /// No description provided for @profileSendPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Send Password Reset Link'**
  String get profileSendPasswordReset;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @schedulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Schedule'**
  String get schedulesTitle;

  /// No description provided for @schedulesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No study sessions scheduled for today.'**
  String get schedulesEmptyMessage;

  /// No description provided for @schedulesEmptyAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first session'**
  String get schedulesEmptyAddFirst;

  /// No description provided for @schedulesActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Schedule actions'**
  String get schedulesActionsTooltip;

  /// No description provided for @schedulesDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule?'**
  String get schedulesDeleteDialogTitle;

  /// No description provided for @schedulesDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed from your study schedule.'**
  String schedulesDeleteDialogMessage(String title);

  /// No description provided for @schedulesCreateBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Study Block'**
  String get schedulesCreateBlockTitle;

  /// No description provided for @schedulesSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get schedulesSubjectLabel;

  /// No description provided for @schedulesSelectSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get schedulesSelectSubjectHint;

  /// No description provided for @schedulesFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get schedulesFieldRequired;

  /// No description provided for @schedulesBlockTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Block Title'**
  String get schedulesBlockTitleLabel;

  /// No description provided for @schedulesBlockTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Deep Work Session'**
  String get schedulesBlockTitleHint;

  /// No description provided for @schedulesSelectedDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected Day'**
  String get schedulesSelectedDayLabel;

  /// No description provided for @schedulesTimeRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get schedulesTimeRangeLabel;

  /// No description provided for @schedulesStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String schedulesStartsAt(String time);

  /// No description provided for @schedulesEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String schedulesEndsAt(String time);

  /// No description provided for @schedulesStartTimePastError.
  ///
  /// In en, this message translates to:
  /// **'You cannot choose a start time before the current time.'**
  String get schedulesStartTimePastError;

  /// No description provided for @schedulesEndAfterStartError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get schedulesEndAfterStartError;

  /// No description provided for @schedulesDaysOfWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Days of Week'**
  String get schedulesDaysOfWeekLabel;

  /// No description provided for @schedulesRemindersLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get schedulesRemindersLabel;

  /// No description provided for @schedulesReminderAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start time'**
  String get schedulesReminderAtStart;

  /// No description provided for @schedulesReminderMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute before} other{{minutes} minutes before}}'**
  String schedulesReminderMinutesBefore(int minutes);

  /// No description provided for @schedulesCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get schedulesCreateButton;

  /// No description provided for @schedulesPastDayError.
  ///
  /// In en, this message translates to:
  /// **'You cannot create a schedule for a past day.'**
  String get schedulesPastDayError;

  /// No description provided for @streaksDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} day streak} =1{{count} day streak} other{{count} day streak}}'**
  String streaksDayStreak(int count);

  /// No description provided for @streaksBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {count, plural, =0{{count} days} =1{{count} day} other{{count} days}}'**
  String streaksBest(int count);

  /// No description provided for @streaksTotalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get streaksTotalPoints;

  /// No description provided for @streaksLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get streaksLastActive;

  /// No description provided for @streaksMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get streaksMilestones;

  /// No description provided for @streaksMilestoneDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String streaksMilestoneDays(int days);

  /// No description provided for @subjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsTitle;

  /// No description provided for @subjectsNewSubject.
  ///
  /// In en, this message translates to:
  /// **'New Subject'**
  String get subjectsNewSubject;

  /// No description provided for @subjectsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your study map'**
  String get subjectsHeroTitle;

  /// No description provided for @subjectsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize each subject with its own color, icon, and daily target.'**
  String get subjectsHeroSubtitle;

  /// No description provided for @subjectsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active subjects'**
  String subjectsActiveCount(int count);

  /// No description provided for @subjectsFreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 free subjects'**
  String subjectsFreeCount(int count);

  /// No description provided for @subjectsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load subjects'**
  String get subjectsLoadErrorTitle;

  /// No description provided for @subjectsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subjects yet'**
  String get subjectsEmptyTitle;

  /// No description provided for @subjectsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first subject to start tracking study progress and daily goals.'**
  String get subjectsEmptyDescription;

  /// No description provided for @subjectsCreateSubject.
  ///
  /// In en, this message translates to:
  /// **'Create Subject'**
  String get subjectsCreateSubject;

  /// No description provided for @subjectsEditSubject.
  ///
  /// In en, this message translates to:
  /// **'Edit Subject'**
  String get subjectsEditSubject;

  /// No description provided for @subjectsEditorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject name, a distinct icon, and a realistic daily goal.'**
  String get subjectsEditorSubtitle;

  /// No description provided for @subjectsEditSubjectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the subject identity, color, icon, and daily target.'**
  String get subjectsEditSubjectSubtitle;

  /// No description provided for @subjectsSubjectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject Name'**
  String get subjectsSubjectNameLabel;

  /// No description provided for @subjectsSubjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Physics 101'**
  String get subjectsSubjectNameHint;

  /// No description provided for @subjectsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject name'**
  String get subjectsNameRequired;

  /// No description provided for @subjectsNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Subject name is too short'**
  String get subjectsNameTooShort;

  /// No description provided for @subjectsColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get subjectsColorLabel;

  /// No description provided for @subjectsIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get subjectsIconLabel;

  /// No description provided for @subjectsDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Target'**
  String get subjectsDailyTarget;

  /// No description provided for @subjectsDailyTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min daily target'**
  String subjectsDailyTargetLabel(int minutes);

  /// No description provided for @subjectsMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String subjectsMinutesValue(int minutes);

  /// No description provided for @subjectsMinutesPlannedDaily.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes planned every day'**
  String subjectsMinutesPlannedDaily(int minutes);

  /// No description provided for @subjectsProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get subjectsProgressLabel;

  /// No description provided for @subjectsPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String subjectsPercentValue(int percent);

  /// No description provided for @subjectsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get subjectsSaveChanges;

  /// No description provided for @subjectsArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get subjectsArchive;

  /// No description provided for @subjectsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive subject?'**
  String get subjectsArchiveTitle;

  /// No description provided for @subjectsArchiveMessage.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed from the active subjects list.'**
  String subjectsArchiveMessage(String name);

  /// No description provided for @subjectsFreeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Free plan limit reached'**
  String get subjectsFreeLimitTitle;

  /// No description provided for @subjectsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Subject Detail'**
  String get subjectsDetailTitle;

  /// No description provided for @subjectsAddChapter.
  ///
  /// In en, this message translates to:
  /// **'Add Chapter'**
  String get subjectsAddChapter;

  /// No description provided for @subjectsChaptersHeader.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get subjectsChaptersHeader;

  /// No description provided for @subjectsChaptersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track the units you have finished and keep momentum visible.'**
  String get subjectsChaptersSubtitle;

  /// No description provided for @subjectsChaptersDone.
  ///
  /// In en, this message translates to:
  /// **'Chapters Done'**
  String get subjectsChaptersDone;

  /// No description provided for @subjectsEditChapter.
  ///
  /// In en, this message translates to:
  /// **'Edit Chapter'**
  String get subjectsEditChapter;

  /// No description provided for @subjectsChapterTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter title'**
  String get subjectsChapterTitleLabel;

  /// No description provided for @subjectsFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get subjectsFieldRequired;

  /// No description provided for @subjectsNoChaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'No chapters yet'**
  String get subjectsNoChaptersTitle;

  /// No description provided for @subjectsNoChaptersDescription.
  ///
  /// In en, this message translates to:
  /// **'Break the subject into clear chapters so progress becomes easier to track.'**
  String get subjectsNoChaptersDescription;

  /// No description provided for @subjectsAddFirstChapter.
  ///
  /// In en, this message translates to:
  /// **'Add First Chapter'**
  String get subjectsAddFirstChapter;

  /// No description provided for @subjectsAnalyzingPdf.
  ///
  /// In en, this message translates to:
  /// **'Analyzing PDF…'**
  String get subjectsAnalyzingPdf;

  /// No description provided for @subjectsChapterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get subjectsChapterCompleted;

  /// No description provided for @subjectsChapterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get subjectsChapterInProgress;

  /// No description provided for @subjectsAiStudyMaterialsTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI study materials'**
  String get subjectsAiStudyMaterialsTooltip;

  /// No description provided for @subjectsAiCardTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Study Materials'**
  String get subjectsAiCardTitle;

  /// No description provided for @subjectsAiCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF and let AI build a summary, flashcards, and quiz.'**
  String get subjectsAiCardSubtitle;

  /// No description provided for @subjectsAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get subjectsAnalyzing;

  /// No description provided for @subjectsUploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get subjectsUploadPdf;

  /// No description provided for @subjectsView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get subjectsView;

  /// No description provided for @subjectsAttachPdfHint.
  ///
  /// In en, this message translates to:
  /// **'Attach a PDF (optional) for AI analysis'**
  String get subjectsAttachPdfHint;

  /// No description provided for @subjectsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get subjectsLanguageLabel;

  /// No description provided for @subjectsSummaryLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary length'**
  String get subjectsSummaryLengthLabel;

  /// No description provided for @subjectsAnalyzePdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze PDF'**
  String get subjectsAnalyzePdfTitle;

  /// No description provided for @subjectsAnalyzeWithAi.
  ///
  /// In en, this message translates to:
  /// **'Analyze with AI'**
  String get subjectsAnalyzeWithAi;

  /// No description provided for @subjectsNoMaterials.
  ///
  /// In en, this message translates to:
  /// **'No AI materials yet. Upload a PDF to generate them.'**
  String get subjectsNoMaterials;

  /// No description provided for @subscriptionAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Zakerly Premium'**
  String get subscriptionAppBarTitle;

  /// No description provided for @subscriptionRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get subscriptionRefreshStatus;

  /// No description provided for @subscriptionHeroTitlePremium.
  ///
  /// In en, this message translates to:
  /// **'You are Premium'**
  String get subscriptionHeroTitlePremium;

  /// No description provided for @subscriptionHeroTitleUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your study flow'**
  String get subscriptionHeroTitleUpgrade;

  /// No description provided for @subscriptionHeroSubtitlePremium.
  ///
  /// In en, this message translates to:
  /// **'All premium features are unlocked on your account.'**
  String get subscriptionHeroSubtitlePremium;

  /// No description provided for @subscriptionHeroSubtitleUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Remove limits and unlock AI notes, analytics, and more.'**
  String get subscriptionHeroSubtitleUpgrade;

  /// No description provided for @subscriptionFeatureUnlimitedSubjects.
  ///
  /// In en, this message translates to:
  /// **'Unlimited subjects'**
  String get subscriptionFeatureUnlimitedSubjects;

  /// No description provided for @subscriptionFeatureFullAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Full analytics'**
  String get subscriptionFeatureFullAnalytics;

  /// No description provided for @subscriptionFeatureAiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI study notes'**
  String get subscriptionFeatureAiNotes;

  /// No description provided for @subscriptionFeaturePriorityReminders.
  ///
  /// In en, this message translates to:
  /// **'Priority reminders'**
  String get subscriptionFeaturePriorityReminders;

  /// No description provided for @subscriptionChoosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get subscriptionChoosePaymentMethod;

  /// No description provided for @subscriptionPayPaymobMonthly.
  ///
  /// In en, this message translates to:
  /// **'Pay with Paymob — Monthly (EGP)'**
  String get subscriptionPayPaymobMonthly;

  /// No description provided for @subscriptionPayPaymobYearly.
  ///
  /// In en, this message translates to:
  /// **'Pay with Paymob — Yearly (EGP)'**
  String get subscriptionPayPaymobYearly;

  /// No description provided for @subscriptionPaymobNote.
  ///
  /// In en, this message translates to:
  /// **'Cards, wallets, and local methods via Paymob. Uses the native Paymob payment sheet inside the app.'**
  String get subscriptionPaymobNote;

  /// No description provided for @subscriptionPayStripe.
  ///
  /// In en, this message translates to:
  /// **'International card (Stripe)'**
  String get subscriptionPayStripe;

  /// No description provided for @subscriptionPremiumActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get subscriptionPremiumActiveTitle;

  /// No description provided for @subscriptionPremiumCanceling.
  ///
  /// In en, this message translates to:
  /// **'Premium (canceling)'**
  String get subscriptionPremiumCanceling;

  /// No description provided for @subscriptionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String subscriptionStatusLabel(String status);

  /// No description provided for @subscriptionProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String subscriptionProviderLabel(String provider);

  /// No description provided for @subscriptionAccessUntil.
  ///
  /// In en, this message translates to:
  /// **'Access until: {date}'**
  String subscriptionAccessUntil(String date);

  /// No description provided for @subscriptionRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews: {date}'**
  String subscriptionRenewsOn(String date);

  /// No description provided for @subscriptionCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get subscriptionCancelAction;

  /// No description provided for @subscriptionRenewalCanceledUntil.
  ///
  /// In en, this message translates to:
  /// **'Renewal canceled. Premium access until {date}.'**
  String subscriptionRenewalCanceledUntil(String date);

  /// No description provided for @subscriptionRenewalCanceledPeriod.
  ///
  /// In en, this message translates to:
  /// **'Renewal canceled. Premium access remains for this period.'**
  String get subscriptionRenewalCanceledPeriod;

  /// No description provided for @subscriptionCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription?'**
  String get subscriptionCancelDialogTitle;

  /// No description provided for @subscriptionCancelDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will stop renewing. You keep Premium access until the end of the current billing period.'**
  String get subscriptionCancelDialogContent;

  /// No description provided for @subscriptionKeepPremium.
  ///
  /// In en, this message translates to:
  /// **'Keep Premium'**
  String get subscriptionKeepPremium;

  /// No description provided for @subscriptionCanceled.
  ///
  /// In en, this message translates to:
  /// **'Subscription canceled.'**
  String get subscriptionCanceled;

  /// No description provided for @subscriptionCancelError.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel subscription.'**
  String get subscriptionCancelError;

  /// No description provided for @subscriptionPaymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed.'**
  String get subscriptionPaymentNotCompleted;

  /// No description provided for @subscriptionPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active. Enjoy your upgraded study flow.'**
  String get subscriptionPremiumActive;

  /// No description provided for @subscriptionPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Premium may take a moment to activate.'**
  String get subscriptionPaymentReceived;

  /// No description provided for @aiLoadSubjectsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subjects.'**
  String get aiLoadSubjectsFailed;

  /// No description provided for @aiStudyPackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Study pack deleted.'**
  String get aiStudyPackDeleted;

  /// No description provided for @aiDeleteStudyPackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete study pack.'**
  String get aiDeleteStudyPackFailed;

  /// No description provided for @aiRateLimitReached.
  ///
  /// In en, this message translates to:
  /// **'AI rate limit reached. Try again later.'**
  String get aiRateLimitReached;

  /// No description provided for @analyticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics data.'**
  String get analyticsLoadFailed;

  /// No description provided for @authGoogleTokenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get Google sign-in token. Please try again.'**
  String get authGoogleTokenFailed;

  /// No description provided for @authGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authGoogleSignInFailed;

  /// No description provided for @authServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Please check your internet connection and try again.'**
  String get authServerUnreachable;

  /// No description provided for @authGenericRetry.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericRetry;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load home data.'**
  String get homeLoadFailed;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get notificationsLoadFailed;

  /// No description provided for @plannerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items for this date.'**
  String get plannerLoadFailed;

  /// No description provided for @plannerCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item created successfully!'**
  String get plannerCreateSuccess;

  /// No description provided for @plannerCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create item.'**
  String get plannerCreateFailed;

  /// No description provided for @plannerCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item completed! Points earned'**
  String get plannerCompleteSuccess;

  /// No description provided for @plannerCompleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete item.'**
  String get plannerCompleteFailed;

  /// No description provided for @plannerDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully.'**
  String get plannerDeleteSuccess;

  /// No description provided for @plannerDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item.'**
  String get plannerDeleteFailed;

  /// No description provided for @pomodoroLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load focus data.'**
  String get pomodoroLoadFailed;

  /// No description provided for @pomodoroSessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Focus session started.'**
  String get pomodoroSessionStarted;

  /// No description provided for @pomodoroSessionRestored.
  ///
  /// In en, this message translates to:
  /// **'An active focus session was restored.'**
  String get pomodoroSessionRestored;

  /// No description provided for @pomodoroStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start session.'**
  String get pomodoroStartFailed;

  /// No description provided for @pomodoroSessionPaused.
  ///
  /// In en, this message translates to:
  /// **'Session paused.'**
  String get pomodoroSessionPaused;

  /// No description provided for @pomodoroSessionResumed.
  ///
  /// In en, this message translates to:
  /// **'Session resumed.'**
  String get pomodoroSessionResumed;

  /// No description provided for @pomodoroSessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Session completed successfully.'**
  String get pomodoroSessionCompleted;

  /// No description provided for @pomodoroSessionStopped.
  ///
  /// In en, this message translates to:
  /// **'Session stopped.'**
  String get pomodoroSessionStopped;

  /// No description provided for @pomodoroTimeUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Time is up!'**
  String get pomodoroTimeUpTitle;

  /// No description provided for @pomodoroBreakOverBody.
  ///
  /// In en, this message translates to:
  /// **'Great job! Take a well-deserved break.'**
  String get pomodoroBreakOverBody;

  /// No description provided for @schedulesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load schedules.'**
  String get schedulesLoadFailed;

  /// No description provided for @schedulesCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule created successfully!'**
  String get schedulesCreateSuccess;

  /// No description provided for @schedulesCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create schedule.'**
  String get schedulesCreateFailed;

  /// No description provided for @schedulesCreateInvalidData.
  ///
  /// In en, this message translates to:
  /// **'Failed to create schedule. Please check the selected data.'**
  String get schedulesCreateInvalidData;

  /// No description provided for @schedulesDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted.'**
  String get schedulesDeleteSuccess;

  /// No description provided for @schedulesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete schedule.'**
  String get schedulesDeleteFailed;

  /// No description provided for @schedulesReminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Reminder: {title}'**
  String schedulesReminderNotificationTitle(String title);

  /// No description provided for @schedulesReminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Your study session starts in 1 minute.} other{Your study session starts in {minutes} minutes.}}'**
  String schedulesReminderNotificationBody(int minutes);

  /// No description provided for @streaksLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load streak.'**
  String get streaksLoadFailed;

  /// No description provided for @subjectsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subjects.'**
  String get subjectsLoadFailed;

  /// No description provided for @subjectsCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subject created successfully.'**
  String get subjectsCreateSuccess;

  /// No description provided for @subjectsCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create subject.'**
  String get subjectsCreateFailed;

  /// No description provided for @subjectsUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subject updated successfully.'**
  String get subjectsUpdateSuccess;

  /// No description provided for @subjectsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update subject.'**
  String get subjectsUpdateFailed;

  /// No description provided for @subjectsArchiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subject archived successfully.'**
  String get subjectsArchiveSuccess;

  /// No description provided for @subjectsArchiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to archive subject.'**
  String get subjectsArchiveFailed;

  /// No description provided for @subjectsDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subject details'**
  String get subjectsDetailLoadFailed;

  /// No description provided for @subjectsChapterAddedAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Chapter added. Analyzing the PDF…'**
  String get subjectsChapterAddedAnalyzing;

  /// No description provided for @subjectsChapterAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chapter added successfully.'**
  String get subjectsChapterAddedSuccess;

  /// No description provided for @subjectsChapterAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add chapter'**
  String get subjectsChapterAddFailed;

  /// No description provided for @subjectsChapterMaterialsReady.
  ///
  /// In en, this message translates to:
  /// **'AI study materials are ready for this chapter.'**
  String get subjectsChapterMaterialsReady;

  /// No description provided for @subjectsMaterialsReady.
  ///
  /// In en, this message translates to:
  /// **'AI study materials are ready for this subject.'**
  String get subjectsMaterialsReady;

  /// No description provided for @subjectsAiJobFailed.
  ///
  /// In en, this message translates to:
  /// **'AI job failed.'**
  String get subjectsAiJobFailed;

  /// No description provided for @subjectsAiAnalysisTimedOut.
  ///
  /// In en, this message translates to:
  /// **'AI analysis timed out.'**
  String get subjectsAiAnalysisTimedOut;

  /// No description provided for @subjectsChapterUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Chapter updated successfully.'**
  String get subjectsChapterUpdateSuccess;

  /// No description provided for @subjectsChapterUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update chapter'**
  String get subjectsChapterUpdateFailed;

  /// No description provided for @subjectsChapterUpdateFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Failed to update chapter.'**
  String get subjectsChapterUpdateFailedShort;

  /// No description provided for @subjectsAnalyzePdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze the PDF.'**
  String get subjectsAnalyzePdfFailed;

  /// No description provided for @subscriptionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription info.'**
  String get subscriptionLoadFailed;

  /// No description provided for @subscriptionPaymobSessionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Paymob session data is incomplete. Please try again.'**
  String get subscriptionPaymobSessionIncomplete;

  /// No description provided for @subscriptionPaymobUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Paymob payments are temporarily unavailable. Please try another method or try again later.'**
  String get subscriptionPaymobUnavailable;

  /// No description provided for @subscriptionPaymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment completed successfully.'**
  String get subscriptionPaymentCompleted;

  /// No description provided for @subscriptionPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted and is pending confirmation.'**
  String get subscriptionPaymentPending;

  /// No description provided for @subscriptionPaymentRejected.
  ///
  /// In en, this message translates to:
  /// **'Payment was rejected.'**
  String get subscriptionPaymentRejected;

  /// No description provided for @subscriptionPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the payment.'**
  String get subscriptionPaymentFailed;

  /// No description provided for @subscriptionCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start Paymob checkout.'**
  String get subscriptionCheckoutFailed;

  /// No description provided for @subscriptionStripeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Card payments are temporarily unavailable. Please try another method or try again later.'**
  String get subscriptionStripeUnavailable;

  /// No description provided for @subscriptionStripeBrowserPrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in the browser, then return and tap Refresh.'**
  String get subscriptionStripeBrowserPrompt;

  /// No description provided for @subscriptionPaymentPageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the payment page.'**
  String get subscriptionPaymentPageFailed;

  /// No description provided for @subscriptionCardCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start card checkout.'**
  String get subscriptionCardCheckoutFailed;

  /// No description provided for @subscriptionCanceledEnded.
  ///
  /// In en, this message translates to:
  /// **'Subscription canceled. Premium access has ended.'**
  String get subscriptionCanceledEnded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
