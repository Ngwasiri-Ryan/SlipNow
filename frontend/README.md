# SlipNow — Flutter frontend

SlipNow helps students see their GCE grades as soon as results are released:
search a candidate, pay 1,000 FCFA with MTN MoMo / Orange Money, and get a
copy of the result slip as a PDF for urgent needs (public exams, pending
scholarships, school admissions at home or abroad). Students are still urged
to collect their original slip from their school.

This is the **frontend only**. All data comes from mock repositories and is
persisted on-device, so the app is fully usable without a backend.

## Run

```bash
cd frontend
flutter pub get
flutter run -d chrome      # or an Android / iOS device or emulator
```

## Project layout

```
lib/
  main.dart                 Wires AppState to the (mock) repositories
  app.dart                  MaterialApp, theme, language scope, first screen
  core/
    constants.dart          Price, exam years, exam streams, support contacts
    mission.dart            The app's purpose, shown in Terms and Help
    l10n.dart               English / French helper: context.tr('en', 'fr')
    nav.dart                Global navigator key + fade route helpers
    theme/                  AppColors (light/dark + 4 brand themes), ThemeData
  data/
    models/models.dart      AppUser, ExamResult, Purchase, ResultsRelease, ...
    models/chat.dart        ChatMessage, SupportAgent, SupportEvent
    repositories/
      repositories.dart     Auth, Results, Payment and SupportChat interfaces
      mock_repositories.dart  Mock implementations used today
      mock_support_chat.dart  Simulated support agent (typing, ticks, replies)
    mock/mock_data.dart     Mock GCE results, release status, notifications
    local/local_store.dart  SharedPreferences JSON persistence (app + chat)
  state/
    app_state.dart          Single ChangeNotifier holding app state
    chat_controller.dart    Support conversation state
  services/
    pdf_service.dart        Slip + receipt PDF generation, print, save, share
    external_actions.dart   WhatsApp, phone, share sheet, clipboard
  ui/
    screens/                One file per screen
    widgets/                Buttons, fields, cards, chat bubbles, toast, ...
```

## Connecting a backend later

The UI only talks to `AppState`, and `AppState` only talks to the interfaces
in `lib/data/repositories/repositories.dart`:

| Interface               | Methods                                                  |
| ----------------------- | -------------------------------------------------------- |
| `AuthRepository`        | `signUp`, `logIn`, `updateProfile`, `logOut`             |
| `ResultsRepository`     | `search(ResultQuery)`, `releaseStatus()`                 |
| `PaymentRepository`     | `confirmPayment(result, method, phone)` → transaction ID |
| `SupportChatRepository` | `agent`, `events` stream, `send(message)`                |

To go live, write `Api*Repository` classes implementing these interfaces
(e.g. with `package:http` or `dio`, and a WebSocket for `events`) and swap
them in `lib/main.dart`. Throw `AuthException(message)` from auth calls to
show the message as a toast.

`releaseStatus()` is what the admin dashboard will control: it returns the
session (e.g. 2026), whether results are released, the release date, and the
expected date while pending. The Home card and Search screen follow it.

Things that are simulated today and will need real implementations:

- Login accepts any phone/password and always returns the demo user.
- Payments wait 2.2s and return a fake transaction ID (no real MoMo/Orange API).
- Results release status comes from `mockRelease` in `mock_data.dart`.
- The support agent is a keyword-based mock; voice notes are simulated.
- Purchases, saved candidates, notifications and chat live only on the device.

## Hidden demo controls

On the welcome (splash) screen:

- Tap the logo **3 times** to open the theme picker (4 brand palettes).
- Tap the logo **5 times** to reset all demo data and restart onboarding.

On Home (debug builds only):

- Long-press the results card to switch between "released" and
  "not released yet".
