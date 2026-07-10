import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

/// Simple two-option segmented control for [TriageStatus]. Kept as its own
/// widget for symmetry with [PrioritySelector] and to keep the page body
/// declarative and easy to read.
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  final TriageStatus selectedStatus;
  final ValueChanged<TriageStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<TriageStatus>(
          segments: TriageStatus.values
              .map(
                (status) => ButtonSegment<TriageStatus>(
                  value: status,
                  label: Text(status.label),
                ),
              )
              .toList(),
          selected: {selectedStatus},
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.comfortable,
          ),
        ),
      ],
    );
  }
}
