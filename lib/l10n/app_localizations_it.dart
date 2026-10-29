// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'People';

  @override
  String get unsavedChangesTitle => 'Modifiche non salvate';

  @override
  String get unsavedChangesMessage =>
      'Le modifiche non sono state salvate. Vuoi eliminarle?';

  @override
  String get keepEditing => 'Continua a modificare';

  @override
  String get discardChanges => 'Elimina modifiche';

  @override
  String get candidateActions => 'Azioni candidato';

  @override
  String get candidateMoveToStage => 'Sposta in una fase';

  @override
  String get candidateMoveForwardBlocked =>
      'Registra una decisione positiva o neutrale per la fase corrente prima di proseguire.';

  @override
  String get candidateRejectBlocked =>
      'Registra una decisione negativa o neutrale per la fase corrente prima di scartare il candidato.';

  @override
  String get candidateHireBlocked =>
      'Per assumere servono la fase di offerta, un\'offerta accettata e una decisione positiva.';

  @override
  String get candidateTransitionBlocked =>
      'Passa alla fase attiva successiva oppure scegli un esito finale.';

  @override
  String get companyLogoLabel => 'Logo aziendale';

  @override
  String get minimizeWindow => 'Riduci a icona';

  @override
  String get maximizeWindow => 'Ingrandisci';

  @override
  String get restoreWindow => 'Ripristina';

  @override
  String get closeWindow => 'Chiudi finestra';

  @override
  String get windowActionFailed => 'Impossibile aggiornare la finestra.';

  @override
  String get languageTooltip => 'Lingua';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get authSignIn => 'Collega le API GitHub';

  @override
  String get authSignOut => 'Disconnetti';

  @override
  String authenticatedAs(String username) {
    return 'API GitHub collegate come: $username';
  }

  @override
  String get authUnknownError =>
      'Connessione alle API GitHub non riuscita. Riprova.';

  @override
  String get authMissingConfiguration =>
      'Le credenziali OAuth GitHub non sono presenti nella configurazione di build.';

  @override
  String get authUnsupportedPlatform =>
      'L\'accesso GitHub è disponibile solo su Windows.';

  @override
  String get authBrowserLaunchFailed =>
      'Impossibile aprire il browser di sistema.';

  @override
  String get authCallbackTimeout => 'Accesso a GitHub scaduto. Riprova.';

  @override
  String get authInvalidCallback =>
      'La risposta di autorizzazione non è valida. Riprova.';

  @override
  String get authDenied => 'L\'accesso alle API GitHub è stato negato.';

  @override
  String get authNetworkError =>
      'Un errore di rete ha interrotto la connessione alle API GitHub.';

  @override
  String get authServiceError =>
      'GitHub non ha completato la richiesta. Riprova più tardi.';

  @override
  String get authInvalidCredentials =>
      'L\'autorizzazione GitHub salvata non è valida. Ricollega l\'API.';

  @override
  String get scoutingFiltersTitle => 'Filtri scouting';

  @override
  String get scoutingKeywordLabel => 'Competenze o parole chiave';

  @override
  String get scoutingKeywordHint => 'Flutter, Rust, machine learning';

  @override
  String get scoutingLocationLabel => 'Località';

  @override
  String get scoutingLocationHint => 'Milano, Italia';

  @override
  String get scoutingMinimumRepositories => 'Repository pubblici minimi';

  @override
  String get scoutingMinimumFollowers => 'Follower minimi';

  @override
  String get scoutingStartButton => 'Avvia scouting';

  @override
  String get scoutingInProgress => 'Ricerca su GitHub in corso...';

  @override
  String get scoutingConnectFirst =>
      'Collega le API GitHub per iniziare lo scouting.';

  @override
  String get scoutingReadyPrompt =>
      'Scegli competenze o località, poi avvia lo scouting.';

  @override
  String get scoutingEmptyQuery =>
      'Inserisci una competenza o una località per cercare utenti GitHub.';

  @override
  String get scoutingAuthenticationRequired =>
      'Ricollega le API GitHub per continuare.';

  @override
  String get scoutingRateLimitExceeded =>
      'La ricerca GitHub è limitata. Attendi qualche istante e riprova.';

  @override
  String get scoutingRequestTimedOut =>
      'GitHub ha impiegato troppo tempo per rispondere. Controlla la connessione e riprova.';

  @override
  String get scoutingInvalidResponse =>
      'GitHub ha restituito una risposta imprevista. Riprova.';

  @override
  String get scoutingNetworkError =>
      'Controlla la connessione Internet e riprova.';

  @override
  String get scoutingServiceError =>
      'GitHub non ha completato la ricerca. Riprova più tardi.';

  @override
  String get scoutingNoResults => 'Nessun candidato corrisponde ai filtri.';

  @override
  String scoutingResultsOfTotal(int shown, int total) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$shown di $totalString candidati';
  }

  @override
  String get scoutingLoadMoreFailed =>
      'Impossibile caricare altri candidati. Riprova.';

  @override
  String get scoutingClearFilters => 'Azzera filtri';

  @override
  String get scoutingKeywordHelper => 'Separa più competenze con una virgola.';

  @override
  String get scoutingNoBiography => 'Biografia non disponibile.';

  @override
  String get scoutingPublicActivity => 'pubblico';

  @override
  String get scoutingOpenProfile => 'Apri profilo';

  @override
  String get scoutingOpenProfileError =>
      'Impossibile aprire questo profilo GitHub.';

  @override
  String get scoutingLoadMore => 'Carica altri';

  @override
  String get scoutingRetry => 'Riprova';

  @override
  String get candidateBoardTitle => 'Pipeline di selezione';

  @override
  String get candidateAdd => 'Aggiungi candidato';

  @override
  String get candidateEdit => 'Modifica candidato';

  @override
  String get candidateDelete => 'Elimina candidato';

  @override
  String get candidateDeleteConfirm =>
      'Eliminare il candidato e il CV cifrato?';

  @override
  String get candidateEmpty =>
      'Nessun candidato. Aggiungine uno o importalo dalla ricerca.';

  @override
  String get candidateSave => 'Salva candidato';

  @override
  String get candidateCancel => 'Annulla';

  @override
  String get candidateFirstName => 'Nome';

  @override
  String get candidateLastName => 'Cognome';

  @override
  String get candidateNameRequired => 'Inserisci almeno il nome.';

  @override
  String get candidateEmail => 'Email';

  @override
  String get candidatePhone => 'Telefono';

  @override
  String get candidateLocation => 'Località';

  @override
  String get candidateHeadline => 'Profilo professionale';

  @override
  String get candidateSkills => 'Competenze (separate da virgole)';

  @override
  String get candidateExperience => 'Anni di esperienza';

  @override
  String get candidateExperienceInvalid =>
      'Inserisci un numero intero di anni, uguale o superiore a zero.';

  @override
  String get candidateSource => 'Canale di provenienza';

  @override
  String get candidateStage => 'Fase del processo';

  @override
  String get candidateGithubUrl => 'Profilo GitHub';

  @override
  String get candidateLinkedinUrl => 'Profilo LinkedIn';

  @override
  String get candidateResume => 'CV';

  @override
  String get candidateImportResume => 'Importa CV';

  @override
  String get candidateReplaceResume => 'Sostituisci CV';

  @override
  String get candidateResumeEncrypted => 'Salvato localmente con cifratura';

  @override
  String get candidateOcrRunning => 'Lettura offline del CV in corso...';

  @override
  String get candidateOcrApplied =>
      'Testo estratto. Verifica i dati suggeriti prima di salvare.';

  @override
  String get candidateOcrNoText =>
      'Nessun testo estratto. Controlla le lingue OCR di Windows.';

  @override
  String get candidateOcrError =>
      'Lettura offline non riuscita. Verifica che Windows abbia una lingua OCR installata.';

  @override
  String get candidateResumeUnsupported =>
      'Scegli un file PDF, PNG o JPEG fino a 15 MB.';

  @override
  String get candidateFeedback => 'Feedback colloquio';

  @override
  String get candidateFeedbackRequired => 'Feedback obbligatorio';

  @override
  String get candidateFeedbackMissing =>
      'Nessuna decisione registrata per questa fase';

  @override
  String get candidateFeedbackPositive => 'Positivo';

  @override
  String get candidateFeedbackNegative => 'Negativo';

  @override
  String get candidateFeedbackNeutral => 'Neutro';

  @override
  String get candidateOverallDecision => 'Giudizio complessivo';

  @override
  String get candidateRatings => 'Valutazioni';

  @override
  String get candidateAverageRating => 'Voto medio';

  @override
  String get ratingTechnicalSkills => 'Competenze tecniche';

  @override
  String get ratingProblemSolving => 'Problem solving';

  @override
  String get ratingCommunication => 'Comunicazione';

  @override
  String get ratingTeamFit => 'Affinità col team';

  @override
  String get ratingMotivation => 'Motivazione';

  @override
  String get recruitingNavToggle => 'Espandi o compatta il menu';

  @override
  String get candidateProfileSaved => 'Anagrafica candidato salvata';

  @override
  String get candidateFeedbackSave => 'Salva feedback';

  @override
  String get candidateFeedbackNotes => 'Note del colloquio';

  @override
  String get candidateFeedbackHistory => 'Storico colloqui';

  @override
  String get candidateFeedbackNone => 'Nessuna nota di colloquio.';

  @override
  String get candidateFeedbackSaved => 'Feedback salvato';

  @override
  String get candidateMoveBlocked =>
      'Per avanzare è necessaria una decisione positiva sulla fase corrente.';

  @override
  String get candidateOffer => 'Offerta / precontratto';

  @override
  String get candidateOfferPosition => 'Posizione';

  @override
  String get candidateOfferSalary => 'Retribuzione';

  @override
  String get candidateOfferCurrency => 'Valuta';

  @override
  String get candidateOfferContractType => 'Tipo di contratto';

  @override
  String get candidateOfferStartDate => 'Data di inizio proposta';

  @override
  String get candidateOfferNotes => 'Note sull\'offerta';

  @override
  String get candidateOfferStatus => 'Stato dell\'offerta';

  @override
  String get candidateOfferDraft => 'Bozza';

  @override
  String get candidateOfferSent => 'Inviata';

  @override
  String get candidateOfferAccepted => 'Accettata';

  @override
  String get candidateOfferDeclined => 'Rifiutata';

  @override
  String get candidateOfferSave => 'Salva offerta';

  @override
  String get candidateSourcesTitle => 'Canali di provenienza';

  @override
  String get candidateStagesTitle => 'Fasi di selezione';

  @override
  String get candidateSourceAdd => 'Aggiungi canale';

  @override
  String get candidateStageAdd => 'Aggiungi fase';

  @override
  String get candidateStageMoveUp => 'Sposta fase in alto';

  @override
  String get candidateStageMoveDown => 'Sposta fase in basso';

  @override
  String get candidateAddFromScouting => 'Aggiungi alla pipeline';

  @override
  String get candidateAlreadyTracked =>
      'Questo profilo GitHub è già nella pipeline.';

  @override
  String get recruitingNavPipeline => 'Pipeline';

  @override
  String get recruitingNavCandidates => 'Candidati';

  @override
  String get recruitingNavSection => 'Selezione';

  @override
  String get candidatesListTitle => 'Tutti i candidati';

  @override
  String get candidatesSearchHint =>
      'Cerca per nome, competenza, località o email';

  @override
  String get candidatesFilterStage => 'Fase';

  @override
  String get candidatesFilterSource => 'Fonte';

  @override
  String get candidatesFilterFeedback => 'Feedback';

  @override
  String get candidatesAllStages => 'Tutte le fasi';

  @override
  String get candidatesAllSources => 'Tutte le fonti';

  @override
  String get candidatesFeedbackAny => 'Qualsiasi feedback';

  @override
  String get candidatesFeedbackMissingOption => 'Feedback mancante';

  @override
  String get candidatesWithResume => 'Con CV';

  @override
  String get candidatesSortLabel => 'Ordina per';

  @override
  String get candidatesSortRecent => 'Aggiornati di recente';

  @override
  String get candidatesSortName => 'Nome';

  @override
  String get candidatesSortStage => 'Fase della pipeline';

  @override
  String get candidatesClearFilters => 'Azzera filtri';

  @override
  String get candidatesNoResults => 'Nessun candidato corrisponde ai filtri.';

  @override
  String candidatesCount(int shown, int total) {
    return '$shown di $total candidati';
  }

  @override
  String candidatesUpdatedOn(String date) {
    return 'Aggiornato il $date';
  }

  @override
  String get candidateStatPending => 'Feedback in attesa';

  @override
  String get candidateStatTotal => 'Totale';

  @override
  String get recruitingNavSearch => 'Ricerca GitHub';

  @override
  String get recruitingNavFavorites => 'Preferiti';

  @override
  String get recruitingNavSettings => 'Impostazioni';

  @override
  String get recruitingFavoritesTitle => 'Profili GitHub salvati';

  @override
  String get recruitingFavoritesEmpty =>
      'Ancora nessun preferito. Salva i profili dalla ricerca GitHub per ritrovarli.';

  @override
  String get recruitingSaveFavorite => 'Salva nei preferiti';

  @override
  String get recruitingRemoveFavorite => 'Rimuovi dai preferiti';

  @override
  String get recruitingAddFavoriteCandidate => 'Aggiungi ai candidati';

  @override
  String get recruitingFavoriteSaved => 'Profilo aggiunto ai preferiti.';

  @override
  String get candidateSettingName => 'Nome';

  @override
  String get candidateSettingSave => 'Salva impostazioni';

  @override
  String get candidateDefaultNew => 'Nuovo';

  @override
  String get candidateDefaultCvReview => 'Valutazione CV';

  @override
  String get candidateDefaultScreening => 'Colloquio conoscitivo';

  @override
  String get candidateDefaultTechnical => 'Colloquio tecnico';

  @override
  String get candidateDefaultFinal => 'Colloquio finale';

  @override
  String get candidateDefaultOffer => 'Offerta / precontratto';

  @override
  String get candidateDefaultHired => 'Assunto';

  @override
  String get candidateDefaultRejected => 'Rifiutato';

  @override
  String get candidateDefaultGrafton => 'Grafton';

  @override
  String get candidateDefaultPoli => 'Poli';

  @override
  String get candidateDefaultGithub => 'GitHub';

  @override
  String get candidateDefaultOther => 'Altro';

  @override
  String get candidateOpenResume => 'Apri CV';

  @override
  String get candidateOpenProfile => 'Apri profilo';

  @override
  String get candidateActionFailed =>
      'Impossibile salvare la modifica. Verifica i dati e riprova.';
}
