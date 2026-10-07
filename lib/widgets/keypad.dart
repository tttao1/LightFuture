import 'package:flutter/material.dart';

import '../app/theme.dart';

class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    super.key,
    required this.value,
    required this.changed,
    required this.submit,
    this.maxLength = 10,
    this.allowNegative = false,
  });
  final String value;
  final ValueChanged<String> changed;
  final VoidCallback submit;
  final int maxLength;
  final bool allowNegative;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEECFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          value.isEmpty ? '输入答案' : value,
          key: const Key('number-answer'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: value.isEmpty ? 18 : 30,
            color: value.isEmpty ? muted : primary,
            letterSpacing: value.isEmpty ? 0 : 3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.65,
        children:
            [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  allowNegative ? '±' : '清空',
                  '0',
                  '⌫',
                ]
                .map(
                  (label) => OutlinedButton(
                    key: Key('digit-$label'),
                    onPressed: () {
                      if (label == '清空') {
                        changed('');
                      } else if (label == '⌫') {
                        if (value.isNotEmpty) {
                          changed(value.substring(0, value.length - 1));
                        }
                      } else if (label == '±') {
                        changed(
                          value.startsWith('-')
                              ? value.substring(1)
                              : '-$value',
                        );
                      } else if (value.replaceAll('-', '').length < maxLength) {
                        changed('$value$label');
                      }
                    },
                    child: Text(label, style: const TextStyle(fontSize: 22)),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('submit-answer'),
        onPressed: value.isEmpty || value == '-' ? null : submit,
        child: const Text('确认答案'),
      ),
    ],
  );
}
