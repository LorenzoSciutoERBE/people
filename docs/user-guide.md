# User guide

People is a Windows desktop recruiting application. It opens on the hiring pipeline and includes GitHub talent search, saved profiles, candidate records, interview feedback, and offer tracking.

The Material 3 navigation separates **Candidates**, **GitHub search**, **Favorites**, and **Hired people**; **Settings** is available at the bottom of the sidebar. GitHub search supports repository languages, location, repository counts, and follower filters. Search results can be saved as favorites or added directly to the hiring pipeline.

Candidate records and resumes are stored locally in an AES-GCM encrypted vault. The vault key is held by Windows secure storage (DPAPI). PDF, PNG, and JPEG resumes up to 15 MB are supported. Text-based PDFs are read locally; scanned PDFs and images use Windows OCR with installed language packs. Candidate records do not leave the computer. The hiring pipeline is CV review → introductory interview → technical interview → Germany interview → offer → hired or rejected. CV review records initial notes without an approval decision. Each interview tracks its date, time, interviewer, internal decision, and candidate communication. Positive feedback advances a candidate after it has been communicated; negative feedback enables rejection after communication. The offer stage handles preparation and proposal, and hiring requires an accepted offer. Board cards and the candidate list show pending communication even when evaluation scores are hidden. The candidate list can filter pending candidate communication. Existing version 1 vaults are migrated once, returning candidates to CV review while retaining profiles and resumes.

Recruiting sources and hiring-stage names/order are configurable in Settings. The initial source list includes Grafton, Poli, GitHub, and Other.

**Hired people** contains everyone in a stage with a hired outcome. Open a person to view recruiting history and add or edit ongoing reviews with a date, reviewer, discussion notes, and follow-up goals. Reviews and meeting plans remain in the encrypted vault; older vaults load without modification.

Moving a candidate to a hired stage opens a hiring-date form and proposes 1-hour follow-ups at 15:00 after 1, 3, 6, and 12 calendar months. Month-end anniversaries use the last valid day of the target month. Confirm hiring with a single action and optionally select calendar export; canceling the file chooser keeps the hiring and meeting plan saved. Adjust meeting dates/times, mark completed meetings, and export a calendar file either while hiring or later from the person's history. Changing the hiring date regenerates the proposed dates and preserves completion flags.

The app shows reminders for incomplete meetings that are overdue or due within the next seven days, updating while the app is open. Calendar files follow [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545), include tentative appointments with 1-day and 15-minute alarms, and use local wall-clock times. Import the `.ics` file into your calendar to schedule the meetings; exporting does not book meetings or send invitations. Closed-app reminders depend on the imported calendar's notification settings. Event IDs remain stable across exports, but calendar import tools may require replacing an earlier import to avoid duplicates.

## Windows OCR

For scanned resumes, install English or Italian OCR capabilities under **Settings > Time & language > Language & region**. Digital PDFs with usable embedded text do not require an OCR language pack.
