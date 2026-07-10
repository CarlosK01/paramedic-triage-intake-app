import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/triage_form_provider.dart';
import '../providers/triage_providers.dart';
import '../widgets/priority_selector.dart';
import '../widgets/status_selector.dart';
import '../widgets/sync_status_banner.dart';
import '../widgets/triage_record_card.dart';

/// The single screen of the app: triage intake form on top, live
/// connectivity/sync banners, and the list of previously submitted
/// records beneath. All business logic is delegated to
/// [triageFormProvider] and the triage use-case providers - this widget only
/// wires user input to those providers and renders their state.
class TriageIntakePage extends ConsumerWidget {
  const TriageIntakePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(triageFormProvider);
    final formNotifier = ref.read(triageFormProvider.notifier);
    final isOnlineAsync = ref.watch(connectivityStreamProvider);
    final isSyncingAsync = ref.watch(syncingStatusProvider);
    final recordsAsync = ref.watch(allRecordsProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    final isOffline = isOnlineAsync.maybeWhen(
      data: (isOnline) => !isOnline,
      orElse: () => false,
    );
    final isSyncing = isSyncingAsync.maybeWhen(
      data: (syncing) => syncing,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramedic Triage Intake'),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Chip(
                  label: Text('$pendingCount pending'),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline) const OfflineBanner(),
          if (!isOffline && isSyncing) const SyncingBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Patient Name',
                    errorText: formState.patientNameError,
                  ),
                  onChanged: formNotifier.updatePatientName,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Condition Description',
                    errorText: formState.conditionError,
                  ),
                  maxLines: 3,
                  onChanged: formNotifier.updateConditionDescription,
                ),
                const SizedBox(height: 20),
                PrioritySelector(
                  selectedPriority: formState.priority,
                  errorText: formState.priorityError,
                  onChanged: formNotifier.updatePriority,
                ),
                const SizedBox(height: 20),
                StatusSelector(
                  selectedStatus: formState.status,
                  onChanged: formNotifier.updateStatus,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: formState.isSubmitting
                      ? null
                      : () => _handleSubmit(context, formNotifier),
                  child: formState.isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Triage Record'),
                ),
                const SizedBox(height: 12),
                if (pendingCount > 0)
                  OutlinedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () => ref.read(syncServiceProvider).manualSync().then((_) {
                              ref.invalidate(allRecordsProvider);
                            }),
                    icon: const Icon(Icons.sync),
                    label: const Text('Retry Sync Now'),
                  ),
                const SizedBox(height: 28),
                Text(
                  'Submitted Records',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No records submitted yet.'),
                      );
                    }
                    return Column(
                      children: records
                          .map((record) => TriageRecordCard(record: record))
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Could not load records: $err'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
      BuildContext context, TriageFormNotifier formNotifier) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await formNotifier.submit();

    if (!context.mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Triage record saved.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
