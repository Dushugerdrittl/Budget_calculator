import 'package:flutter/material.dart';

class CurrencySelector extends StatelessWidget {
  final Map<String, String> currencySymbols;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;

  const CurrencySelector({
    super.key,
    required this.currencySymbols,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Select Currency: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        DropdownButton<String>(
          value:
              currencySymbols.entries
                  .firstWhere((entry) => entry.value == selectedCurrency)
                  .key,
          items:
              currencySymbols.keys
                  .map(
                    (String key) =>
                        DropdownMenuItem<String>(value: key, child: Text(key)),
                  )
                  .toList(),
          onChanged: (String? newKey) {
            if (newKey != null) {
              onCurrencyChanged(currencySymbols[newKey]!);
            }
          },
        ),
      ],
    );
  }
}
