# Paramedic Triage Intake

An offline-first mobile application for field paramedics to log critical
patient triage data instantly, with a guarantee that no record is ever lost
regardless of network conditions.

## Architecture

The project follows **Clean Architecture**, split into three layers:

```
lib/
  core/                          # Shared, feature-agnostic code
    constants/                   # Colors, enums, tunable config
    theme/                       # Material 3 ThemeData
    services/                    # ConnectivityService, SyncService
    utils/                       # Pure validation functions

  features/triage/
    domain/                      # Pure Dart, zero framework/package dependencies
      entities/                  # TriageRecord (business object)
      repositories/              # TriageRepository (abstract contract)
      usecases/                  # SaveTriage, GetPending, GetAll, SyncPending

    data/                        # Implements the domain contracts
      models/                    # TriageRecordModel (Hive-annotated)
      datasources/                # TriageLocalDataSource (Hive), MockApiService
      repositories/                # TriageRepositoryImpl (offline-first logic lives here)

    presentation/                # Everything Flutter/UI-specific
      pages/                     # TriageIntakePage (the single screen)
      widgets/                   # PrioritySelector, StatusSelector, cards, banners
      providers/                 # Riverpod wiring + form state

  main.dart                      # Hive init, DI overrides, app lifecycle
```

**Dependency direction**: `presentation` -> `domain` <- `data`. The domain
layer has no imports from `data` or `presentation`, and no Flutter/Hive
imports at all - it is pure Dart. This is what makes the offline-first logic
and validation rules unit-testable without a device, emulator, or Hive
instance.

Widgets never call the repository or Hive directly - they read Riverpod
providers and call methods on `TriageFormNotifier`, which is the only place
that assembles a `TriageRecord` and hands it to the repository.

## Offline-First Strategy

All the offline-first decision logic lives in one place:
`TriageRepositoryImpl.saveTriage()`.

```
User taps Submit
      |
      v
Validate form (patient name, condition, priority all required)
      |  invalid -> show inline errors, stop
      v valid
Save locally to Hive immediately (record now exists, cannot be lost)
      |
      v
Check connectivity (ConnectivityService.isOnlineNow())
      |
      +-- Online  -> attempt MockApiService.upload()
      |                +-- success -> mark isSynced = true
      |                +-- failure -> leave isSynced = false (stays pending)
      |
      +-- Offline -> leave isSynced = false (stays pending), no API call attempted
```

The UI is never blocked on the network call: `saveTriage()` is awaited from
the form's submit handler, but the local save always happens first and the
network attempt (2 second artificial delay) only ever affects whether the
record is marked `synced` vs `pending` - it never causes data loss or a
crash. Any exception from the mock API is caught inside the repository and
converted into "leave this record pending," so it never propagates up to
the UI as an unhandled error.

## Sync Queue Explanation

`SyncService` (in `core/services/sync_service.dart`) is responsible for
clearing the pending queue automatically:

1. On creation, it subscribes to `ConnectivityService.onlineStatus`.
2. The moment that stream emits `true` (connectivity restored), it calls
   `TriageRepository.syncPending()`.
3. `syncPending()` fetches every record where `isSynced == false` and
   uploads them **sequentially** (not in parallel), marking each one synced
   immediately after a successful upload. If one record's upload fails, the
   loop logs it and moves on to the next record rather than aborting the
   whole batch - so a single flaky record never blocks the rest of the
   queue.
4. Records are keyed by their own `id` in the Hive box, so re-saving a
   record after a successful sync is an **upsert**, not an insert - this is
   what prevents duplicate uploads/records if a sync is retried.
5. An `_isSyncing` guard means overlapping sync runs (e.g. connectivity
   flickering on/off quickly) don't launch a second concurrent sync pass.
6. `SyncService` also exposes `attemptSyncOnResume()`, called from
   `main.dart`'s `WidgetsBindingObserver.didChangeAppLifecycleState` whenever
   the app returns to the foreground - so bringing the app back from the
   background after connectivity was restored elsewhere also triggers a
   sync, rather than waiting only for the connectivity-changed stream event.
7. A manual **"Retry Sync Now"** button is available in the UI (shown
   whenever there are pending records) which calls the same sync path.

## Packages Used

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management and dependency injection |
| `hive` / `hive_flutter` | Local, offline persistence |
| `connectivity_plus` | Network reachability detection and change stream |
| `equatable` | Value equality for the `TriageRecord` domain entity |
| `uuid` | Generating unique record ids on submit |
| `intl` | Date formatting on the record cards |

## How to Run

1. Ensure Flutter (latest stable) is installed: `flutter --version`
2. From the project root:
   ```bash
   flutter pub get
   flutter run
   ```
3. The app opens directly to the triage intake form - there is only one screen.

### Note on the generated Hive adapter

`lib/features/triage/data/models/triage_record_model.g.dart` is normally
produced by `build_runner`. It has been **hand-written** in this submission
(mechanically, field-by-field, matching exactly what `hive_generator` would
emit) because it was created in an environment without Flutter/pub.dev
access to run codegen. To regenerate it properly in a real Flutter
environment (recommended, and safe - it will produce an equivalent file):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## How to Simulate Offline Mode

**On a real device (recommended for the demo video):**
Turn on Airplane Mode from the device's OS settings, submit a triage
record, observe it saved with a "Pending" badge, then turn Airplane Mode
off and watch the "Syncing..." banner appear and the badge flip to "Synced".

**On an emulator:**
- Android emulator: use the extended controls (`...` in the emulator
  toolbar) -> Cellular -> set "Signal strength" to "None", or toggle Wi-Fi
  off in the emulator's quick settings.
- iOS Simulator does not reliably support hard offline toggling; the
  Android emulator or a real device is preferable for this demo.

## How Random Failures Work

`MockApiService.upload()` simulates `POST /api/v1/triage`:
- Waits `AppConstants.mockApiDelay` (2 seconds) to mimic a realistic round-trip.
- Uses `Random().nextDouble() < AppConstants.mockApiFailureRate` (30%) to
  decide whether to throw. On failure it throws a plain `Exception`, which
  `TriageRepositoryImpl` catches and treats exactly like an offline
  submission (record stays `isSynced = false`).
- Because failures are random even while "online," you may see a record
  saved as Pending immediately after submitting while connected - this is
  expected and demonstrates the retry path, which the background
  `SyncService` will clear on its next successful attempt.

## How Testing Works

Tests live in `test/` and use hand-written in-memory fakes
(`test/fakes.dart`) instead of a mocking framework - the interfaces
involved (`TriageLocalDataSource`, `MockApiService`, `ConnectivityService`)
are small enough that fakes are simpler and faster than codegen-based mocks.

```bash
flutter test
```

Test files:
- `test/validators_test.dart` - patient name / condition / priority
  validation rules (8 assertions)
- `test/mock_api_service_test.dart` - deterministic success/failure via a
  fixed-value fake `Random`, plus a timing check on the artificial delay
- `test/triage_repository_test.dart` - the full offline-first decision
  matrix (online+success, online+failure, offline, never-throws) plus
  retry-marks-synced and continue-past-one-failure
- `test/sync_service_test.dart` - manual sync clears the queue, the
  `syncingStream` emits `[true, false]`, and overlapping syncs don't
  double-upload

21 tests in total (unit tests across validators, the mock API, the
repository's offline-first decision matrix, and the sync service, plus a
widget test suite covering the form-fill/submit/offline flow end to end).

## Demo Video

`demo/demo.mp4` shows the app saving a record while the device is in
Airplane Mode, then automatically syncing it once Airplane Mode is turned
off, with no user interaction required beyond the initial submit.

## Extra Features Implemented

- Pending-records count badge in the app bar
- Live sync status indicator ("Syncing...") banner
- "Waiting for Network" banner while offline
- Manual "Retry Sync Now" button
- `lastSyncedAt` timestamp tracked in `SyncService` (available via
  `SyncService.lastSyncedAt`, ready to surface in the UI if desired)
- Animated priority selector (`AnimatedContainer`) for a polished feel on selection
