import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Large, thumb-friendly priority picker (1-5). Each option is rendered in
/// its hazard colour at all times (not just when selected) so paramedics
/// can scan the row visually without reading labels.
class PrioritySelector extends StatelessWidget {
  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onChanged,
    this.errorText,
  });

  final int? selectedPriority;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority Level', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final priority = index + 1;
            final isSelected = selectedPriority == priority;
            final color = AppColors.forPriority(priority);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: priority == 5 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => onChanged(priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$priority',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
      ],
    );
  }
}
