// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'People';

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
  String get candidateOcrNoText =>
      'No text could be extracted. Check the Windows OCR language settings.';

  @override
  String get candidateOcrError =>
      'Offline CV reading failed. Check that a Windows OCR language is installed.';

  @override
  String get candidateResumeUnsupported =>
      'Choose a PDF, PNG, or JPEG file up to 15 MB.';

  @override
  String get candidateFeedback => 'Interview feedback';

  @override
  String get candidateFeedbackRequired => 'Feedback required';

  @override
  String get candidateFeedbackMissing => 'No decision recorded for this stage';

  @override
  String get candidateFeedbackPositive => 'Positive';

  @override
  String get candidateFeedbackNegative => 'Negative';

  @override
  String get candidateFeedbackNeutral => 'Neutral';

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
  String get candidateFeedbackNotes => 'Interview notes';

  @override
  String get candidateFeedbackHistory => 'Interview history';

  @override
  String get candidateFeedbackNone => 'No interview notes yet.';

  @override
  String get candidateFeedbackSaved => 'Feedback saved';

  @override
  String get candidateMoveBlocked =>
      'A positive decision for the current stage is required before moving forward.';

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
  String get candidateStageAdd => 'Add stage';

  @override
  String get candidateStageMoveUp => 'Move stage up';

  @override
  String get candidateStageMoveDown => 'Move stage down';

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
  String get candidateStatPending => 'Feedback pending';

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
  String get recruitingAddFavoriteCandidate => 'Add to candidates';

  @override
  String get recruitingFavoriteSaved => 'Profile saved to favorites.';

  @override
  String get candidateSettingName => 'Name';

  @override
  String get candidateSettingSave => 'Save settings';

  @override
  String get candidateDefaultNew => 'New';

  @override
  String get candidateDefaultCvReview => 'CV review';

  @override
  String get candidateDefaultScreening => 'Screening interview';

  @override
  String get candidateDefaultTechnical => 'Technical interview';

  @override
  String get candidateDefaultFinal => 'Final interview';

  @override
  String get candidateDefaultOffer => 'Offer / pre-contract';

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
}
