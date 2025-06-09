import 'package:flutter/material.dart';

/// Um widget de dropdown melhorado que resolve problemas de overlay e renderização
class ImprovedDropdown<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final bool isDense;
  final bool isExpanded;
  final double menuMaxHeight;

  const ImprovedDropdown({
    Key? key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isDense = true,
    this.isExpanded = true,
    this.menuMaxHeight = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Use um tema específico para o dropdown para evitar problemas de overlay
      data: Theme.of(context).copyWith(
        // Usar cores específicas para melhorar a visualização
        canvasColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          isDense: isDense,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: isExpanded,
        menuMaxHeight: menuMaxHeight,
        // Alinhamento para melhorar a renderização
        alignment: AlignmentDirectional.centerStart,
        // Cores para melhorar a visualização
        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
        // Estilos específicos para os itens
        style: Theme.of(context).textTheme.bodyMedium,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 24,
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
