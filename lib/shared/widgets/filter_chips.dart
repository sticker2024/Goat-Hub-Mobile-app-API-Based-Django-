import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selectedOption;
  final Function(String) onSelected;
  final String Function(String)? optionLabel;

  const FilterChips({
    super.key,
    required this.label,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.optionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedOption == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    optionLabel?.call(option) ?? option,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  onSelected: (_) => onSelected(option),
                  selectedColor: Theme.of(context).primaryColor,
                  checkmarkColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}