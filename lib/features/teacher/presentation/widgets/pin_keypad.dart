import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Keyboard-free PIN entry shared by first-run setup and teacher unlock.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.pin,
    required this.onDigit,
    required this.onDelete,
    this.title = 'Enter Teacher PIN',
    this.enabled = true,
    this.helperText,
  });

  final String pin;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final String title;
  final bool enabled;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Spacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final filled = index < pin.length;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Semantics(
                label: filled ? 'PIN digit entered' : 'Empty PIN position',
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: filled ? colorScheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
            );
          }),
        ),
        if (helperText != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            helperText!,
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: Spacing.lg),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ]) ...[
          Row(children: row.map((digit) => _digit(context, digit)).toList()),
          const SizedBox(height: Spacing.xs),
        ],
        Row(
          children: [
            const Expanded(child: SizedBox(height: 58)),
            _digit(context, '0'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    key: const ValueKey('pin_delete'),
                    onPressed: enabled && pin.isNotEmpty ? onDelete : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                      ),
                    ),
                    child: const Icon(Icons.backspace_outlined),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digit(BuildContext context, String digit) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 58,
        child: OutlinedButton(
          key: ValueKey('pin_digit_$digit'),
          onPressed: enabled && pin.length < 6 ? () => onDigit(digit) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            textStyle: Theme.of(context).textTheme.titleLarge,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
            ),
          ),
          child: Text(digit),
        ),
      ),
    ),
  );
}
