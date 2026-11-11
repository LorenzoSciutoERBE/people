// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get candidateAcceptedOfferRequired =>
      'Save an offer with status Accepted before hiring this candidate. A positive decision alone is not enough.';

  @override
  String get candidateOfferStageRequired =>
      'Move this candidate to the offer stage before confirming hiring.';

  @override
  String get candidateOfferMissing => 'No offer saved';

  @override
  String employmentRemindersCount(int count) {
    return '$count follow-up meetings need your attention';
  }

  @override
  String get employmentPlanTitle => 'Hiring date and follow-up meetings';

  @override
  String get employmentHiringDate => 'Hiring date';

  @override
  String get employmentPlanDescription =>
      'Suggested 1-hour meetings from 15:00 to 16:00, 1, 3, 6, and 12 months after hiring. Select a meeting to change its date or start time.';

  @override
  String get employmentSaveExplanation =>
      'Save the hiring date and follow-up meetings for this person.';

  @override
  String get employmentHireExplanation =>
      'Confirm hiring to move this candidate to Hired people and save these meetings. An accepted offer and a positive decision in the offer stage are required.';

  @override
  String get employmentExportOnSave => 'Also export a calendar file (.ics)';

  @override
  String get employmentExportExplanation =>
      'After saving, choose where to save the file, then import it into your calendar. Canceling the file dialog keeps your changes saved in People.';

  @override
  String get employmentPlanSaved => 'Hiring date and follow-up meetings saved.';

  @override
  String get employmentHireSaved =>
      'Hiring confirmed. You can find this person and their meetings in Hired people.';

  @override
  String employmentMilestone(int months) {
    return '$months-month follow-up';
  }

  @override
  String get employmentPlanSave => 'Save meeting plan';

  @override
  String get employmentHireAndPlan => 'Confirm hiring';

  @override
  String get employmentPlanEdit => 'Plan follow-up meetings';

  @override
  String get employmentExportCalendar => 'Export calendar (.ics)';

  @override
  String get employmentCalendarSaved =>
      'Calendar file saved. Import it into your calendar to schedule meetings and receive reminders.';

  @override
  String get employmentCalendarExportFailed =>
      'Your changes are saved in People, but the calendar file could not be exported. Try Export calendar again from Hired people and choose a writable folder.';

  @override
  String get employmentPlanInvalid =>
      'Each follow-up must be on or after the hiring date.';

  @override
  String get employmentMeetingCompleted => 'Completed';

  @override
  String get employmentUpcoming => 'Upcoming and overdue follow-ups';

  @override
  String get employmentOverdue => 'Overdue';

  @override
  String get employmentRemindersInfo =>
      'In-app reminders show meetings due within 7 days and overdue meetings. Calendar exports include reminders 1 day and 15 minutes before each meeting.';

  @override
  String get hiredPeopleTitle => 'Hired people';

  @override
  String get hiredPeopleSubtitle =>
      'Keep recruiting history and ongoing reviews together.';

  @override
  String get hiredPeopleEmpty =>
      'No hired people yet. People appear here after reaching a hired stage.';

  @override
  String get hiredPeopleSearch => 'Search hired people';

  @override
  String get employeeReviewsTitle => 'Review history';

  @override
  String get employeeReviewsEmpty =>
      'No ongoing reviews yet. Add the first review to start the history.';

  @override
  String get employeeReviewsHidden =>
      'Reviews are hidden. Use Show evaluations in the header to view them.';

  @override
  String get employeeAddReview => 'Add review';

  @override
  String get employeeEditReview => 'Edit review';

  @override
  String get employeeReviewTitle => 'Review title';

  @override
  String get employeeReviewer => 'Reviewer';

  @override
  String get employeeReviewDate => 'Review date';

  @override
  String get employeeReviewNotes => 'Discussion and feedback';

  @override
  String get employeeReviewGoals => 'Goals and follow-up actions';

  @override
  String get employeeReviewRequired =>
      'Complete the title, reviewer, and discussion before saving.';

  @override
  String get employeeReviewSaved => 'Review saved.';

  @override
  String get employeeRecruitingHistory => 'Recruiting history';

  @override
  String get appTitle => 'People';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesMessage =>
      'Your changes have not been saved. Discard them?';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get candidateActions => 'Candidate actions';

  @override
  String get candidateMoveToStage => 'Move to stage';

  @override
  String get candidateMoveForwardBlocked =>
      'Record positive interviewer feedback before advancing.';

  @override
  String get candidateRejectBlocked =>
      'Record negative interviewer feedback before rejecting.';

  @override
  String get candidateHireBlocked =>
      'Hiring requires the offer stage, an accepted offer and a positive decision.';

  @override
  String get candidateTransitionBlocked =>
      'Move to the next active stage, or choose a final outcome.';

  @override
  String get companyLogoLabel => 'Company logo';

  @override
  String get minimizeWindow => 'Minimize';

  @override
  String get maximizeWindow => 'Maximize';

  @override
  String get restoreWindow => 'Restore';

  @override
  String get closeWindow => 'Close window';

  @override
  String get windowActionFailed => 'Unable to update the window.';

  @override
  String get languageTooltip => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get authSignIn => 'Connect GitHub API';

  @override
  String get authSignOut => 'Disconnect';

  @override
  String authenticatedAs(String username) {
    return 'GitHub API connected as: $username';
  }

  @override
  String get authUnknownError => 'GitHub API connection failed. Try again.';

  @override
  String get authMissingConfiguration =>
      'GitHub OAuth credentials are missing from the build configuration.';

  @override
  String get authUnsupportedPlatform =>
      'GitHub sign-in is available on Windows only.';

  @override
  String get authBrowserLaunchFailed => 'Unable to open the system browser.';

  @override
  String get authCallbackTimeout => 'GitHub sign-in timed out. Try again.';

  @override
  String get authInvalidCallback =>
      'The authorization response was invalid. Try again.';

  @override
  String get authDenied => 'GitHub API access was denied.';

  @override
  String get authNetworkError =>
      'A network error interrupted the GitHub API connection.';

  @override
  String get authServiceError =>
      'GitHub could not complete the request. Try again later.';

  @override
  String get authInvalidCredentials =>
      'The saved GitHub API authorization is invalid. Connect again.';

  @override
  String get scoutingFiltersTitle => 'Scouting filters';

  @override
  String get scoutingKeywordLabel => 'Skills or keywords';

  @override
  String get scoutingKeywordHint => 'Flutter, Rust, machine learning';

  @override
  String get scoutingLocationLabel => 'Location';

  @override
  String get scoutingLocationHint => 'Milan, Italy';

  @override
  String get scoutingMinimumRepositories => 'Minimum public repositories';

  @override
  String get scoutingMinimumFollowers => 'Minimum followers';

  @override
  String get scoutingStartButton => 'Start scouting';

  @override
  String get scoutingInProgress => 'Searching GitHub...';

  @override
  String get scoutingConnectFirst =>
      'Connect your GitHub API to start scouting.';

  @override
  String get scoutingReadyPrompt =>
      'Choose skills or a location, then start scouting.';

  @override
  String get scoutingEmptyQuery =>
      'Enter a skill or location to search GitHub users.';

  @override
  String get scoutingAuthenticationRequired =>
      'Connect your GitHub API again to continue.';

  @override
  String get scoutingRateLimitExceeded =>
      'GitHub search is rate limited. Wait a moment and try again.';

  @override
  String get scoutingRequestTimedOut =>
      'GitHub took too long to respond. Check your connection and retry.';

  @override
  String get scoutingInvalidResponse =>
      'GitHub returned an unexpected response. Try again.';

  @override
  String get scoutingNetworkError =>
      'Check your internet connection and try again.';

  @override
  String get scoutingServiceError =>
      'GitHub could not complete the search. Try again later.';

  @override
  String get scoutingNoResults => 'No candidates matched these filters.';

  @override
  String scoutingResultsOfTotal(int shown, int total) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Showing $shown of $totalString candidates';
  }

  @override
  String get scoutingLoadMoreFailed =>
      'Could not load more candidates. Try again.';

  @override
  String get scoutingClearFilters => 'Clear filters';

  @override
  String get scoutingKeywordHelper => 'Separate several skills with commas.';

  @override
  String get scoutingNoBiography => 'No biography provided.';

  @override
  String get scoutingPublicActivity => 'public';

  @override
  String get scoutingOpenProfile => 'Open profile';

  @override
  String get scoutingOpenProfileError => 'Unable to open this GitHub profile.';

  @override
  String get scoutingLoadMore => 'Load more';

  @override
  String get scoutingRetry => 'Retry';

  @override
  String get candidateBoardTitle => 'Hiring pipeline';

  @override
  String get candidateAdd => 'Add candidate';

  @override
  String get candidateEdit => 'Edit candidate';

  @override
  String get candidateDelete => 'Delete candidate';

  @override
  String get candidateDeleteConfirm =>
      'Delete this candidate and the encrypted CV?';

  @override
  String get candidateEmpty =>
      'No candidates yet. Add a candidate or import one from scouting.';

  @override
  String get candidateSave => 'Save candidate';

  @override
  String get candidateCancel => 'Cancel';

  @override
  String get candidateFirstName => 'First name';

  @override
  String get candidateLastName => 'Last name';

  @override
  String get candidateNameRequired => 'Enter at least a first name.';

  @override
  String get candidateEmail => 'Email';

  @override
  String get candidatePhone => 'Phone';

  @override
  String get candidateLocation => 'Location';

  @override
  String get candidateHeadline => 'Professional headline';

  @override
  String get candidateSkills => 'Skills (comma-separated)';

  @override
  String get candidateExperience => 'Years of experience';

  @override
  String get candidateExperienceInvalid =>
      'Enter a whole number of years, zero or greater.';

  @override
  String get candidateSource => 'Source';

  @override
  String get candidateStage => 'Pipeline stage';

  @override
  String get candidateGithubUrl => 'GitHub profile URL';

  @override
  String get candidateLinkedinUrl => 'LinkedIn profile URL';

  @override
  String get candidateResume => 'CV / resume';

  @override
  String get candidateImportResume => 'Import CV';

  @override
  String get candidateReplaceResume => 'Replace CV';

  @override
  String get candidateResumeEncrypted => 'Stored locally with encryption';

  @override
  String get candidateOcrRunning => 'Reading CV offline...';

  @override
  String get candidateOcrApplied =>
      'CV text extracted. Review the suggested details before saving.';

  @override
  String get candidateOcrTextPreview => 'Review extracted text';

  @override
  String get candidateOcrNoContacts =>
      'Text was extracted, but no name or email was identified. Review the extracted text and enter the contact details manually.';

  @override
  String get candidateOcrNoText =>
      'No text could be extracted. Check the Windows OCR language settings.';

  @override
  String get candidateOcrError =>
      'Offline CV reading failed. Check that a Windows OCR language is installed.';

  @override
  String get candidateResumeUnsupported =>
      'Choose a PDF, PNG, or JPEG file up to 15 MB.';

  @override
  String get candidateFeedback => 'Interview & feedback';

  @override
  String get candidateFeedbackRequired => 'Feedback required';

  @override
  String get candidateFeedbackMissing => 'Awaiting decision';

  @override
  String get candidateFeedbackPositive => 'Positive';

  @override
  String get candidateFeedbackNegative => 'Negative';

  @override
  String get candidateOverallDecision => 'Overall';

  @override
  String get candidateRatings => 'Ratings';

  @override
  String get candidateAverageRating => 'Average rating';

  @override
  String get ratingTechnicalSkills => 'Technical skills';

  @override
  String get ratingProblemSolving => 'Problem solving';

  @override
  String get ratingCommunication => 'Communication';

  @override
  String get ratingTeamFit => 'Team fit';

  @override
  String get ratingMotivation => 'Motivation';

  @override
  String get recruitingNavToggle => 'Expand or collapse menu';

  @override
  String get candidateProfileSaved => 'Candidate profile saved';

  @override
  String get candidateFeedbackSave => 'Save feedback';

  @override
  String get candidateFeedbackDate => 'Interview date';

  @override
  String get candidateFeedbackNotes => 'Interview notes';

  @override
  String get candidateFeedbackHistory => 'Hiring activity';

  @override
  String get candidateFeedbackNone => 'No interview notes yet.';

  @override
  String get candidateFeedbackSaved => 'Feedback saved';

  @override
  String get candidateOffer => 'Offer / pre-contract';

  @override
  String get candidateOfferPosition => 'Position';

  @override
  String get candidateOfferSalary => 'Salary';

  @override
  String get candidateOfferCurrency => 'Currency';

  @override
  String get candidateOfferContractType => 'Contract type';

  @override
  String get candidateOfferStartDate => 'Proposed start date';

  @override
  String get candidateOfferNotes => 'Offer notes';

  @override
  String get candidateOfferStatus => 'Offer status';

  @override
  String get candidateOfferDraft => 'Draft';

  @override
  String get candidateOfferSent => 'Sent';

  @override
  String get candidateOfferAccepted => 'Accepted';

  @override
  String get candidateOfferDeclined => 'Declined';

  @override
  String get candidateOfferSave => 'Save offer';

  @override
  String get candidateSourcesTitle => 'Candidate sources';

  @override
  String get candidateStagesTitle => 'Hiring stages';

  @override
  String get candidateSourceAdd => 'Add source';

  @override
  String get candidateAddFromScouting => 'Add to hiring board';

  @override
  String get candidateAlreadyTracked =>
      'This GitHub profile is already on the hiring board.';

  @override
  String get recruitingNavPipeline => 'Pipeline';

  @override
  String get recruitingNavCandidates => 'Candidates';

  @override
  String get recruitingNavSection => 'Recruiting';

  @override
  String get candidatesListTitle => 'All candidates';

  @override
  String get candidatesSearchHint => 'Search by name, skill, location or email';

  @override
  String get candidatesFilterStage => 'Stage';

  @override
  String get candidatesFilterSource => 'Source';

  @override
  String get candidatesFilterFeedback => 'Feedback';

  @override
  String get candidatesAllStages => 'All stages';

  @override
  String get candidatesAllSources => 'All sources';

  @override
  String get candidatesFeedbackAny => 'Any feedback';

  @override
  String get candidatesFeedbackMissingOption => 'Feedback missing';

  @override
  String get candidatesWithResume => 'With CV';

  @override
  String get candidatesSortLabel => 'Sort by';

  @override
  String get candidatesSortRecent => 'Recently updated';

  @override
  String get candidatesSortName => 'Name';

  @override
  String get candidatesSortStage => 'Pipeline stage';

  @override
  String get candidatesClearFilters => 'Clear filters';

  @override
  String get candidatesNoResults => 'No candidates match these filters.';

  @override
  String candidatesCount(int shown, int total) {
    return '$shown of $total candidates';
  }

  @override
  String candidatesUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get candidateStatPending => 'Candidate feedback pending';

  @override
  String get candidateStatTotal => 'Total';

  @override
  String get recruitingNavSearch => 'GitHub search';

  @override
  String get recruitingNavFavorites => 'Favorites';

  @override
  String get recruitingNavSettings => 'Settings';

  @override
  String get recruitingFavoritesTitle => 'Saved GitHub profiles';

  @override
  String get recruitingFavoritesEmpty =>
      'No favorites yet. Save profiles from GitHub search to revisit them later.';

  @override
  String get recruitingSaveFavorite => 'Save to favorites';

  @override
  String get recruitingRemoveFavorite => 'Remove from favorites';

  @override
  String get recruitingFavoriteSaved => 'Profile saved to favorites.';

  @override
  String get candidateSettingName => 'Name';

  @override
  String get candidateSettingSave => 'Save settings';

  @override
  String get candidateDefaultNew => 'CV review';

  @override
  String get candidateDefaultScreening => 'Introductory interview';

  @override
  String get candidateDefaultTechnical => 'Technical interview';

  @override
  String get candidateDefaultFinal => 'Germany interview';

  @override
  String get candidateDefaultOffer => 'Offer';

  @override
  String get candidateDefaultHired => 'Hired';

  @override
  String get candidateDefaultRejected => 'Rejected';

  @override
  String get candidateDefaultGrafton => 'Grafton';

  @override
  String get candidateDefaultPoli => 'Poli';

  @override
  String get candidateDefaultGithub => 'GitHub';

  @override
  String get candidateDefaultOther => 'Other';

  @override
  String get candidateOpenResume => 'Open CV';

  @override
  String get candidateOpenProfile => 'Open profile';

  @override
  String get candidateActionFailed =>
      'Unable to save this recruiting change. Please review the data and try again.';

  @override
  String get recruitingHideEvaluations => 'Hide evaluations';

  @override
  String get recruitingShowEvaluations => 'Show evaluations';

  @override
  String get candidatePersonalDetails => 'Personal details';

  @override
  String get candidateHiringProcess => 'Hiring process';

  @override
  String get candidateStageEvaluation => 'Stage evaluation';

  @override
  String get candidateStageEvaluationsTitle => 'Stage evaluations & screening';

  @override
  String get candidateInterviewStep => 'Interview';

  @override
  String get candidateEvaluationDate => 'Evaluation date';

  @override
  String get candidateEvaluationNotes => 'Evaluation notes';

  @override
  String get candidateCurrentStageAction => 'Current stage';

  @override
  String get candidateFeedbackSentToCandidate =>
      'Feedback communicated to candidate';

  @override
  String candidateAdvanceStage(String stage) {
    return 'Advance to $stage';
  }

  @override
  String get pipelineInterviewer => 'Interviewer / feedback owner';

  @override
  String get pipelineSchedule => 'Schedule interview';

  @override
  String get pipelineScheduleRequired =>
      'Schedule the interview and assign an interviewer before recording a decision.';

  @override
  String get pipelineCvRequired =>
      'Save your CV review notes before scheduling the introductory interview. No decision is needed at this stage.';

  @override
  String get pipelineCommunicationRequired =>
      'Communicate the feedback to the candidate and mark it as shared before continuing.';

  @override
  String get pipelineFeedbackPending => 'Candidate feedback pending';

  @override
  String get pipelineFeedbackShared => 'Candidate feedback shared';

  @override
  String get pipelineReviewCv => 'Review CV and add initial notes';

  @override
  String get pipelineAwaitingFeedback => 'Collect interviewer feedback';

  @override
  String get pipelineReady => 'Ready for the next step';

  @override
  String get pipelineEditFeedback => 'Edit interview & feedback';

  @override
  String get pipelineCurrentStep => 'CURRENT STEP';

  @override
  String get pipelineOutcome => 'OUTCOME';

  @override
  String get pipelineCompletedSteps => 'Previous steps';

  @override
  String get pipelineCvDescription =>
      'Read the CV and capture your first impressions. Then arrange the introductory interview; no approval decision is needed here.';

  @override
  String get pipelineInterviewDescription =>
      'Schedule the conversation, collect the interviewer’s decision, and communicate the outcome to the candidate before continuing.';

  @override
  String get pipelineOfferDescription =>
      'Prepare and send the proposal, then record the candidate’s response. An accepted offer completes the selection process.';
}
