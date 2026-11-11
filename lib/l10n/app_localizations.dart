import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @candidateAcceptedOfferRequired.
  ///
  /// In en, this message translates to:
  /// **'Save an offer with status Accepted before hiring this candidate. A positive decision alone is not enough.'**
  String get candidateAcceptedOfferRequired;

  /// No description provided for @candidateOfferStageRequired.
  ///
  /// In en, this message translates to:
  /// **'Move this candidate to the offer stage before confirming hiring.'**
  String get candidateOfferStageRequired;

  /// No description provided for @candidateOfferMissing.
  ///
  /// In en, this message translates to:
  /// **'No offer saved'**
  String get candidateOfferMissing;

  /// No description provided for @employmentRemindersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} follow-up meetings need your attention'**
  String employmentRemindersCount(int count);

  /// No description provided for @employmentPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Hiring date and follow-up meetings'**
  String get employmentPlanTitle;

  /// No description provided for @employmentHiringDate.
  ///
  /// In en, this message translates to:
  /// **'Hiring date'**
  String get employmentHiringDate;

  /// No description provided for @employmentPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Suggested 1-hour meetings from 15:00 to 16:00, 1, 3, 6, and 12 months after hiring. Select a meeting to change its date or start time.'**
  String get employmentPlanDescription;

  /// No description provided for @employmentSaveExplanation.
  ///
  /// In en, this message translates to:
  /// **'Save the hiring date and follow-up meetings for this person.'**
  String get employmentSaveExplanation;

  /// No description provided for @employmentHireExplanation.
  ///
  /// In en, this message translates to:
  /// **'Confirm hiring to move this candidate to Hired people and save these meetings. An accepted offer and a positive decision in the offer stage are required.'**
  String get employmentHireExplanation;

  /// No description provided for @employmentExportOnSave.
  ///
  /// In en, this message translates to:
  /// **'Also export a calendar file (.ics)'**
  String get employmentExportOnSave;

  /// No description provided for @employmentExportExplanation.
  ///
  /// In en, this message translates to:
  /// **'After saving, choose where to save the file, then import it into your calendar. Canceling the file dialog keeps your changes saved in People.'**
  String get employmentExportExplanation;

  /// No description provided for @employmentPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Hiring date and follow-up meetings saved.'**
  String get employmentPlanSaved;

  /// No description provided for @employmentHireSaved.
  ///
  /// In en, this message translates to:
  /// **'Hiring confirmed. You can find this person and their meetings in Hired people.'**
  String get employmentHireSaved;

  /// No description provided for @employmentMilestone.
  ///
  /// In en, this message translates to:
  /// **'{months}-month follow-up'**
  String employmentMilestone(int months);

  /// No description provided for @employmentPlanSave.
  ///
  /// In en, this message translates to:
  /// **'Save meeting plan'**
  String get employmentPlanSave;

  /// No description provided for @employmentHireAndPlan.
  ///
  /// In en, this message translates to:
  /// **'Confirm hiring'**
  String get employmentHireAndPlan;

  /// No description provided for @employmentPlanEdit.
  ///
  /// In en, this message translates to:
  /// **'Plan follow-up meetings'**
  String get employmentPlanEdit;

  /// No description provided for @employmentExportCalendar.
  ///
  /// In en, this message translates to:
  /// **'Export calendar (.ics)'**
  String get employmentExportCalendar;

  /// No description provided for @employmentCalendarSaved.
  ///
  /// In en, this message translates to:
  /// **'Calendar file saved. Import it into your calendar to schedule meetings and receive reminders.'**
  String get employmentCalendarSaved;

  /// No description provided for @employmentCalendarExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Your changes are saved in People, but the calendar file could not be exported. Try Export calendar again from Hired people and choose a writable folder.'**
  String get employmentCalendarExportFailed;

  /// No description provided for @employmentPlanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Each follow-up must be on or after the hiring date.'**
  String get employmentPlanInvalid;

  /// No description provided for @employmentMeetingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get employmentMeetingCompleted;

  /// No description provided for @employmentUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming and overdue follow-ups'**
  String get employmentUpcoming;

  /// No description provided for @employmentOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get employmentOverdue;

  /// No description provided for @employmentRemindersInfo.
  ///
  /// In en, this message translates to:
  /// **'In-app reminders show meetings due within 7 days and overdue meetings. Calendar exports include reminders 1 day and 15 minutes before each meeting.'**
  String get employmentRemindersInfo;

  /// No description provided for @hiredPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Hired people'**
  String get hiredPeopleTitle;

  /// No description provided for @hiredPeopleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep recruiting history and ongoing reviews together.'**
  String get hiredPeopleSubtitle;

  /// No description provided for @hiredPeopleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hired people yet. People appear here after reaching a hired stage.'**
  String get hiredPeopleEmpty;

  /// No description provided for @hiredPeopleSearch.
  ///
  /// In en, this message translates to:
  /// **'Search hired people'**
  String get hiredPeopleSearch;

  /// No description provided for @employeeReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review history'**
  String get employeeReviewsTitle;

  /// No description provided for @employeeReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ongoing reviews yet. Add the first review to start the history.'**
  String get employeeReviewsEmpty;

  /// No description provided for @employeeReviewsHidden.
  ///
  /// In en, this message translates to:
  /// **'Reviews are hidden. Use Show evaluations in the header to view them.'**
  String get employeeReviewsHidden;

  /// No description provided for @employeeAddReview.
  ///
  /// In en, this message translates to:
  /// **'Add review'**
  String get employeeAddReview;

  /// No description provided for @employeeEditReview.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get employeeEditReview;

  /// No description provided for @employeeReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review title'**
  String get employeeReviewTitle;

  /// No description provided for @employeeReviewer.
  ///
  /// In en, this message translates to:
  /// **'Reviewer'**
  String get employeeReviewer;

  /// No description provided for @employeeReviewDate.
  ///
  /// In en, this message translates to:
  /// **'Review date'**
  String get employeeReviewDate;

  /// No description provided for @employeeReviewNotes.
  ///
  /// In en, this message translates to:
  /// **'Discussion and feedback'**
  String get employeeReviewNotes;

  /// No description provided for @employeeReviewGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals and follow-up actions'**
  String get employeeReviewGoals;

  /// No description provided for @employeeReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Complete the title, reviewer, and discussion before saving.'**
  String get employeeReviewRequired;

  /// No description provided for @employeeReviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Review saved.'**
  String get employeeReviewSaved;

  /// No description provided for @employeeRecruitingHistory.
  ///
  /// In en, this message translates to:
  /// **'Recruiting history'**
  String get employeeRecruitingHistory;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get appTitle;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your changes have not been saved. Discard them?'**
  String get unsavedChangesMessage;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @candidateActions.
  ///
  /// In en, this message translates to:
  /// **'Candidate actions'**
  String get candidateActions;

  /// No description provided for @candidateMoveToStage.
  ///
  /// In en, this message translates to:
  /// **'Move to stage'**
  String get candidateMoveToStage;

  /// No description provided for @candidateMoveForwardBlocked.
  ///
  /// In en, this message translates to:
  /// **'Record positive interviewer feedback before advancing.'**
  String get candidateMoveForwardBlocked;

  /// No description provided for @candidateRejectBlocked.
  ///
  /// In en, this message translates to:
  /// **'Record negative interviewer feedback before rejecting.'**
  String get candidateRejectBlocked;

  /// No description provided for @candidateHireBlocked.
  ///
  /// In en, this message translates to:
  /// **'Hiring requires the offer stage, an accepted offer and a positive decision.'**
  String get candidateHireBlocked;

  /// No description provided for @candidateTransitionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Move to the next active stage, or choose a final outcome.'**
  String get candidateTransitionBlocked;

  /// No description provided for @companyLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Company logo'**
  String get companyLogoLabel;

  /// No description provided for @minimizeWindow.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizeWindow;

  /// No description provided for @maximizeWindow.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get maximizeWindow;

  /// No description provided for @restoreWindow.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreWindow;

  /// No description provided for @closeWindow.
  ///
  /// In en, this message translates to:
  /// **'Close window'**
  String get closeWindow;

  /// No description provided for @windowActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the window.'**
  String get windowActionFailed;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub API'**
  String get authSignIn;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get authSignOut;

  /// No description provided for @authenticatedAs.
  ///
  /// In en, this message translates to:
  /// **'GitHub API connected as: {username}'**
  String authenticatedAs(String username);

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'GitHub API connection failed. Try again.'**
  String get authUnknownError;

  /// No description provided for @authMissingConfiguration.
  ///
  /// In en, this message translates to:
  /// **'GitHub OAuth credentials are missing from the build configuration.'**
  String get authMissingConfiguration;

  /// No description provided for @authUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'GitHub sign-in is available on Windows only.'**
  String get authUnsupportedPlatform;

  /// No description provided for @authBrowserLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the system browser.'**
  String get authBrowserLaunchFailed;

  /// No description provided for @authCallbackTimeout.
  ///
  /// In en, this message translates to:
  /// **'GitHub sign-in timed out. Try again.'**
  String get authCallbackTimeout;

  /// No description provided for @authInvalidCallback.
  ///
  /// In en, this message translates to:
  /// **'The authorization response was invalid. Try again.'**
  String get authInvalidCallback;

  /// No description provided for @authDenied.
  ///
  /// In en, this message translates to:
  /// **'GitHub API access was denied.'**
  String get authDenied;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'A network error interrupted the GitHub API connection.'**
  String get authNetworkError;

  /// No description provided for @authServiceError.
  ///
  /// In en, this message translates to:
  /// **'GitHub could not complete the request. Try again later.'**
  String get authServiceError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The saved GitHub API authorization is invalid. Connect again.'**
  String get authInvalidCredentials;

  /// No description provided for @scoutingFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Scouting filters'**
  String get scoutingFiltersTitle;

  /// No description provided for @scoutingKeywordLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills or keywords'**
  String get scoutingKeywordLabel;

  /// No description provided for @scoutingKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'Flutter, Rust, machine learning'**
  String get scoutingKeywordHint;

  /// No description provided for @scoutingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get scoutingLocationLabel;

  /// No description provided for @scoutingLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Milan, Italy'**
  String get scoutingLocationHint;

  /// No description provided for @scoutingMinimumRepositories.
  ///
  /// In en, this message translates to:
  /// **'Minimum public repositories'**
  String get scoutingMinimumRepositories;

  /// No description provided for @scoutingMinimumFollowers.
  ///
  /// In en, this message translates to:
  /// **'Minimum followers'**
  String get scoutingMinimumFollowers;

  /// No description provided for @scoutingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start scouting'**
  String get scoutingStartButton;

  /// No description provided for @scoutingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Searching GitHub...'**
  String get scoutingInProgress;

  /// No description provided for @scoutingConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect your GitHub API to start scouting.'**
  String get scoutingConnectFirst;

  /// No description provided for @scoutingReadyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose skills or a location, then start scouting.'**
  String get scoutingReadyPrompt;

  /// No description provided for @scoutingEmptyQuery.
  ///
  /// In en, this message translates to:
  /// **'Enter a skill or location to search GitHub users.'**
  String get scoutingEmptyQuery;

  /// No description provided for @scoutingAuthenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect your GitHub API again to continue.'**
  String get scoutingAuthenticationRequired;

  /// No description provided for @scoutingRateLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'GitHub search is rate limited. Wait a moment and try again.'**
  String get scoutingRateLimitExceeded;

  /// No description provided for @scoutingRequestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'GitHub took too long to respond. Check your connection and retry.'**
  String get scoutingRequestTimedOut;

  /// No description provided for @scoutingInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'GitHub returned an unexpected response. Try again.'**
  String get scoutingInvalidResponse;

  /// No description provided for @scoutingNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get scoutingNetworkError;

  /// No description provided for @scoutingServiceError.
  ///
  /// In en, this message translates to:
  /// **'GitHub could not complete the search. Try again later.'**
  String get scoutingServiceError;

  /// No description provided for @scoutingNoResults.
  ///
  /// In en, this message translates to:
  /// **'No candidates matched these filters.'**
  String get scoutingNoResults;

  /// No description provided for @scoutingResultsOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} candidates'**
  String scoutingResultsOfTotal(int shown, int total);

  /// No description provided for @scoutingLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load more candidates. Try again.'**
  String get scoutingLoadMoreFailed;

  /// No description provided for @scoutingClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get scoutingClearFilters;

  /// No description provided for @scoutingKeywordHelper.
  ///
  /// In en, this message translates to:
  /// **'Separate several skills with commas.'**
  String get scoutingKeywordHelper;

  /// No description provided for @scoutingNoBiography.
  ///
  /// In en, this message translates to:
  /// **'No biography provided.'**
  String get scoutingNoBiography;

  /// No description provided for @scoutingPublicActivity.
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get scoutingPublicActivity;

  /// No description provided for @scoutingOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get scoutingOpenProfile;

  /// No description provided for @scoutingOpenProfileError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this GitHub profile.'**
  String get scoutingOpenProfileError;

  /// No description provided for @scoutingLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get scoutingLoadMore;

  /// No description provided for @scoutingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scoutingRetry;

  /// No description provided for @candidateBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Hiring pipeline'**
  String get candidateBoardTitle;

  /// No description provided for @candidateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add candidate'**
  String get candidateAdd;

  /// No description provided for @candidateEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit candidate'**
  String get candidateEdit;

  /// No description provided for @candidateDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete candidate'**
  String get candidateDelete;

  /// No description provided for @candidateDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this candidate and the encrypted CV?'**
  String get candidateDeleteConfirm;

  /// No description provided for @candidateEmpty.
  ///
  /// In en, this message translates to:
  /// **'No candidates yet. Add a candidate or import one from scouting.'**
  String get candidateEmpty;

  /// No description provided for @candidateSave.
  ///
  /// In en, this message translates to:
  /// **'Save candidate'**
  String get candidateSave;

  /// No description provided for @candidateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get candidateCancel;

  /// No description provided for @candidateFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get candidateFirstName;

  /// No description provided for @candidateLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get candidateLastName;

  /// No description provided for @candidateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a first name.'**
  String get candidateNameRequired;

  /// No description provided for @candidateEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get candidateEmail;

  /// No description provided for @candidatePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get candidatePhone;

  /// No description provided for @candidateLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get candidateLocation;

  /// No description provided for @candidateHeadline.
  ///
  /// In en, this message translates to:
  /// **'Professional headline'**
  String get candidateHeadline;

  /// No description provided for @candidateSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma-separated)'**
  String get candidateSkills;

  /// No description provided for @candidateExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get candidateExperience;

  /// No description provided for @candidateExperienceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of years, zero or greater.'**
  String get candidateExperienceInvalid;

  /// No description provided for @candidateSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get candidateSource;

  /// No description provided for @candidateStage.
  ///
  /// In en, this message translates to:
  /// **'Pipeline stage'**
  String get candidateStage;

  /// No description provided for @candidateGithubUrl.
  ///
  /// In en, this message translates to:
  /// **'GitHub profile URL'**
  String get candidateGithubUrl;

  /// No description provided for @candidateLinkedinUrl.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn profile URL'**
  String get candidateLinkedinUrl;

  /// No description provided for @candidateResume.
  ///
  /// In en, this message translates to:
  /// **'CV / resume'**
  String get candidateResume;

  /// No description provided for @candidateImportResume.
  ///
  /// In en, this message translates to:
  /// **'Import CV'**
  String get candidateImportResume;

  /// No description provided for @candidateReplaceResume.
  ///
  /// In en, this message translates to:
  /// **'Replace CV'**
  String get candidateReplaceResume;

  /// No description provided for @candidateResumeEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Stored locally with encryption'**
  String get candidateResumeEncrypted;

  /// No description provided for @candidateOcrRunning.
  ///
  /// In en, this message translates to:
  /// **'Reading CV offline...'**
  String get candidateOcrRunning;

  /// No description provided for @candidateOcrApplied.
  ///
  /// In en, this message translates to:
  /// **'CV text extracted. Review the suggested details before saving.'**
  String get candidateOcrApplied;

  /// No description provided for @candidateOcrTextPreview.
  ///
  /// In en, this message translates to:
  /// **'Review extracted text'**
  String get candidateOcrTextPreview;

  /// No description provided for @candidateOcrNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Text was extracted, but no name or email was identified. Review the extracted text and enter the contact details manually.'**
  String get candidateOcrNoContacts;

  /// No description provided for @candidateOcrNoText.
  ///
  /// In en, this message translates to:
  /// **'No text could be extracted. Check the Windows OCR language settings.'**
  String get candidateOcrNoText;

  /// No description provided for @candidateOcrError.
  ///
  /// In en, this message translates to:
  /// **'Offline CV reading failed. Check that a Windows OCR language is installed.'**
  String get candidateOcrError;

  /// No description provided for @candidateResumeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF, PNG, or JPEG file up to 15 MB.'**
  String get candidateResumeUnsupported;

  /// No description provided for @candidateFeedback.
  ///
  /// In en, this message translates to:
  /// **'Interview & feedback'**
  String get candidateFeedback;

  /// No description provided for @candidateFeedbackRequired.
  ///
  /// In en, this message translates to:
  /// **'Feedback required'**
  String get candidateFeedbackRequired;

  /// No description provided for @candidateFeedbackMissing.
  ///
  /// In en, this message translates to:
  /// **'Awaiting decision'**
  String get candidateFeedbackMissing;

  /// No description provided for @candidateFeedbackPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get candidateFeedbackPositive;

  /// No description provided for @candidateFeedbackNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get candidateFeedbackNegative;

  /// No description provided for @candidateOverallDecision.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get candidateOverallDecision;

  /// No description provided for @candidateRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get candidateRatings;

  /// No description provided for @candidateAverageRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get candidateAverageRating;

  /// No description provided for @ratingTechnicalSkills.
  ///
  /// In en, this message translates to:
  /// **'Technical skills'**
  String get ratingTechnicalSkills;

  /// No description provided for @ratingProblemSolving.
  ///
  /// In en, this message translates to:
  /// **'Problem solving'**
  String get ratingProblemSolving;

  /// No description provided for @ratingCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get ratingCommunication;

  /// No description provided for @ratingTeamFit.
  ///
  /// In en, this message translates to:
  /// **'Team fit'**
  String get ratingTeamFit;

  /// No description provided for @ratingMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get ratingMotivation;

  /// No description provided for @recruitingNavToggle.
  ///
  /// In en, this message translates to:
  /// **'Expand or collapse menu'**
  String get recruitingNavToggle;

  /// No description provided for @candidateProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Candidate profile saved'**
  String get candidateProfileSaved;

  /// No description provided for @candidateFeedbackSave.
  ///
  /// In en, this message translates to:
  /// **'Save feedback'**
  String get candidateFeedbackSave;

  /// No description provided for @candidateFeedbackDate.
  ///
  /// In en, this message translates to:
  /// **'Interview date'**
  String get candidateFeedbackDate;

  /// No description provided for @candidateFeedbackNotes.
  ///
  /// In en, this message translates to:
  /// **'Interview notes'**
  String get candidateFeedbackNotes;

  /// No description provided for @candidateFeedbackHistory.
  ///
  /// In en, this message translates to:
  /// **'Hiring activity'**
  String get candidateFeedbackHistory;

  /// No description provided for @candidateFeedbackNone.
  ///
  /// In en, this message translates to:
  /// **'No interview notes yet.'**
  String get candidateFeedbackNone;

  /// No description provided for @candidateFeedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved'**
  String get candidateFeedbackSaved;

  /// No description provided for @candidateOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer / pre-contract'**
  String get candidateOffer;

  /// No description provided for @candidateOfferPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get candidateOfferPosition;

  /// No description provided for @candidateOfferSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get candidateOfferSalary;

  /// No description provided for @candidateOfferCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get candidateOfferCurrency;

  /// No description provided for @candidateOfferContractType.
  ///
  /// In en, this message translates to:
  /// **'Contract type'**
  String get candidateOfferContractType;

  /// No description provided for @candidateOfferStartDate.
  ///
  /// In en, this message translates to:
  /// **'Proposed start date'**
  String get candidateOfferStartDate;

  /// No description provided for @candidateOfferNotes.
  ///
  /// In en, this message translates to:
  /// **'Offer notes'**
  String get candidateOfferNotes;

  /// No description provided for @candidateOfferStatus.
  ///
  /// In en, this message translates to:
  /// **'Offer status'**
  String get candidateOfferStatus;

  /// No description provided for @candidateOfferDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get candidateOfferDraft;

  /// No description provided for @candidateOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get candidateOfferSent;

  /// No description provided for @candidateOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get candidateOfferAccepted;

  /// No description provided for @candidateOfferDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get candidateOfferDeclined;

  /// No description provided for @candidateOfferSave.
  ///
  /// In en, this message translates to:
  /// **'Save offer'**
  String get candidateOfferSave;

  /// No description provided for @candidateSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidate sources'**
  String get candidateSourcesTitle;

  /// No description provided for @candidateStagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hiring stages'**
  String get candidateStagesTitle;

  /// No description provided for @candidateSourceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get candidateSourceAdd;

  /// No description provided for @candidateAddFromScouting.
  ///
  /// In en, this message translates to:
  /// **'Add to hiring board'**
  String get candidateAddFromScouting;

  /// No description provided for @candidateAlreadyTracked.
  ///
  /// In en, this message translates to:
  /// **'This GitHub profile is already on the hiring board.'**
  String get candidateAlreadyTracked;

  /// No description provided for @recruitingNavPipeline.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get recruitingNavPipeline;

  /// No description provided for @recruitingNavCandidates.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get recruitingNavCandidates;

  /// No description provided for @recruitingNavSection.
  ///
  /// In en, this message translates to:
  /// **'Recruiting'**
  String get recruitingNavSection;

  /// No description provided for @candidatesListTitle.
  ///
  /// In en, this message translates to:
  /// **'All candidates'**
  String get candidatesListTitle;

  /// No description provided for @candidatesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, skill, location or email'**
  String get candidatesSearchHint;

  /// No description provided for @candidatesFilterStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get candidatesFilterStage;

  /// No description provided for @candidatesFilterSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get candidatesFilterSource;

  /// No description provided for @candidatesFilterFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get candidatesFilterFeedback;

  /// No description provided for @candidatesAllStages.
  ///
  /// In en, this message translates to:
  /// **'All stages'**
  String get candidatesAllStages;

  /// No description provided for @candidatesAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get candidatesAllSources;

  /// No description provided for @candidatesFeedbackAny.
  ///
  /// In en, this message translates to:
  /// **'Any feedback'**
  String get candidatesFeedbackAny;

  /// No description provided for @candidatesFeedbackMissingOption.
  ///
  /// In en, this message translates to:
  /// **'Feedback missing'**
  String get candidatesFeedbackMissingOption;

  /// No description provided for @candidatesWithResume.
  ///
  /// In en, this message translates to:
  /// **'With CV'**
  String get candidatesWithResume;

  /// No description provided for @candidatesSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get candidatesSortLabel;

  /// No description provided for @candidatesSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get candidatesSortRecent;

  /// No description provided for @candidatesSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get candidatesSortName;

  /// No description provided for @candidatesSortStage.
  ///
  /// In en, this message translates to:
  /// **'Pipeline stage'**
  String get candidatesSortStage;

  /// No description provided for @candidatesClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get candidatesClearFilters;

  /// No description provided for @candidatesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No candidates match these filters.'**
  String get candidatesNoResults;

  /// No description provided for @candidatesCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} candidates'**
  String candidatesCount(int shown, int total);

  /// No description provided for @candidatesUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String candidatesUpdatedOn(String date);

  /// No description provided for @candidateStatPending.
  ///
  /// In en, this message translates to:
  /// **'Candidate feedback pending'**
  String get candidateStatPending;

  /// No description provided for @candidateStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get candidateStatTotal;

  /// No description provided for @recruitingNavSearch.
  ///
  /// In en, this message translates to:
  /// **'GitHub search'**
  String get recruitingNavSearch;

  /// No description provided for @recruitingNavFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get recruitingNavFavorites;

  /// No description provided for @recruitingNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get recruitingNavSettings;

  /// No description provided for @recruitingFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved GitHub profiles'**
  String get recruitingFavoritesTitle;

  /// No description provided for @recruitingFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Save profiles from GitHub search to revisit them later.'**
  String get recruitingFavoritesEmpty;

  /// No description provided for @recruitingSaveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get recruitingSaveFavorite;

  /// No description provided for @recruitingRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get recruitingRemoveFavorite;

  /// No description provided for @recruitingFavoriteSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved to favorites.'**
  String get recruitingFavoriteSaved;

  /// No description provided for @candidateSettingName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get candidateSettingName;

  /// No description provided for @candidateSettingSave.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get candidateSettingSave;

  /// No description provided for @candidateDefaultNew.
  ///
  /// In en, this message translates to:
  /// **'CV review'**
  String get candidateDefaultNew;

  /// No description provided for @candidateDefaultScreening.
  ///
  /// In en, this message translates to:
  /// **'Introductory interview'**
  String get candidateDefaultScreening;

  /// No description provided for @candidateDefaultTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical interview'**
  String get candidateDefaultTechnical;

  /// No description provided for @candidateDefaultFinal.
  ///
  /// In en, this message translates to:
  /// **'Germany interview'**
  String get candidateDefaultFinal;

  /// No description provided for @candidateDefaultOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get candidateDefaultOffer;

  /// No description provided for @candidateDefaultHired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get candidateDefaultHired;

  /// No description provided for @candidateDefaultRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get candidateDefaultRejected;

  /// No description provided for @candidateDefaultGrafton.
  ///
  /// In en, this message translates to:
  /// **'Grafton'**
  String get candidateDefaultGrafton;

  /// No description provided for @candidateDefaultPoli.
  ///
  /// In en, this message translates to:
  /// **'Poli'**
  String get candidateDefaultPoli;

  /// No description provided for @candidateDefaultGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get candidateDefaultGithub;

  /// No description provided for @candidateDefaultOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get candidateDefaultOther;

  /// No description provided for @candidateOpenResume.
  ///
  /// In en, this message translates to:
  /// **'Open CV'**
  String get candidateOpenResume;

  /// No description provided for @candidateOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get candidateOpenProfile;

  /// No description provided for @candidateActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save this recruiting change. Please review the data and try again.'**
  String get candidateActionFailed;

  /// No description provided for @recruitingHideEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Hide evaluations'**
  String get recruitingHideEvaluations;

  /// No description provided for @recruitingShowEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Show evaluations'**
  String get recruitingShowEvaluations;

  /// No description provided for @candidatePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get candidatePersonalDetails;

  /// No description provided for @candidateHiringProcess.
  ///
  /// In en, this message translates to:
  /// **'Hiring process'**
  String get candidateHiringProcess;

  /// No description provided for @candidateStageEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Stage evaluation'**
  String get candidateStageEvaluation;

  /// No description provided for @candidateStageEvaluationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage evaluations & screening'**
  String get candidateStageEvaluationsTitle;

  /// No description provided for @candidateInterviewStep.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get candidateInterviewStep;

  /// No description provided for @candidateEvaluationDate.
  ///
  /// In en, this message translates to:
  /// **'Evaluation date'**
  String get candidateEvaluationDate;

  /// No description provided for @candidateEvaluationNotes.
  ///
  /// In en, this message translates to:
  /// **'Evaluation notes'**
  String get candidateEvaluationNotes;

  /// No description provided for @candidateCurrentStageAction.
  ///
  /// In en, this message translates to:
  /// **'Current stage'**
  String get candidateCurrentStageAction;

  /// No description provided for @candidateFeedbackSentToCandidate.
  ///
  /// In en, this message translates to:
  /// **'Feedback communicated to candidate'**
  String get candidateFeedbackSentToCandidate;

  /// No description provided for @candidateAdvanceStage.
  ///
  /// In en, this message translates to:
  /// **'Advance to {stage}'**
  String candidateAdvanceStage(String stage);

  /// No description provided for @pipelineInterviewer.
  ///
  /// In en, this message translates to:
  /// **'Interviewer / feedback owner'**
  String get pipelineInterviewer;

  /// No description provided for @pipelineSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule interview'**
  String get pipelineSchedule;

  /// No description provided for @pipelineScheduleRequired.
  ///
  /// In en, this message translates to:
  /// **'Schedule the interview and assign an interviewer before recording a decision.'**
  String get pipelineScheduleRequired;

  /// No description provided for @pipelineCvRequired.
  ///
  /// In en, this message translates to:
  /// **'Save your CV review notes before scheduling the introductory interview. No decision is needed at this stage.'**
  String get pipelineCvRequired;

  /// No description provided for @pipelineCommunicationRequired.
  ///
  /// In en, this message translates to:
  /// **'Communicate the feedback to the candidate and mark it as shared before continuing.'**
  String get pipelineCommunicationRequired;

  /// No description provided for @pipelineFeedbackPending.
  ///
  /// In en, this message translates to:
  /// **'Candidate feedback pending'**
  String get pipelineFeedbackPending;

  /// No description provided for @pipelineFeedbackShared.
  ///
  /// In en, this message translates to:
  /// **'Candidate feedback shared'**
  String get pipelineFeedbackShared;

  /// No description provided for @pipelineReviewCv.
  ///
  /// In en, this message translates to:
  /// **'Review CV and add initial notes'**
  String get pipelineReviewCv;

  /// No description provided for @pipelineAwaitingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Collect interviewer feedback'**
  String get pipelineAwaitingFeedback;

  /// No description provided for @pipelineReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for the next step'**
  String get pipelineReady;

  /// No description provided for @pipelineEditFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edit interview & feedback'**
  String get pipelineEditFeedback;

  /// No description provided for @pipelineCurrentStep.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STEP'**
  String get pipelineCurrentStep;

  /// No description provided for @pipelineOutcome.
  ///
  /// In en, this message translates to:
  /// **'OUTCOME'**
  String get pipelineOutcome;

  /// No description provided for @pipelineCompletedSteps.
  ///
  /// In en, this message translates to:
  /// **'Previous steps'**
  String get pipelineCompletedSteps;

  /// No description provided for @pipelineCvDescription.
  ///
  /// In en, this message translates to:
  /// **'Read the CV and capture your first impressions. Then arrange the introductory interview; no approval decision is needed here.'**
  String get pipelineCvDescription;

  /// No description provided for @pipelineInterviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule the conversation, collect the interviewer’s decision, and communicate the outcome to the candidate before continuing.'**
  String get pipelineInterviewDescription;

  /// No description provided for @pipelineOfferDescription.
  ///
  /// In en, this message translates to:
  /// **'Prepare and send the proposal, then record the candidate’s response. An accepted offer completes the selection process.'**
  String get pipelineOfferDescription;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
