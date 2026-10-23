import 'dart:math' as math;

import 'package:flutter/material.dart';

class CatalogAutocomplete<T extends Object> extends StatelessWidget {
  const CatalogAutocomplete({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.options,
    required this.display,
    required this.onSelected,
    this.optionLabel,
    this.required = false,
    this.enabled = true,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final Iterable<T> Function(String) options;
  final String Function(T) display;
  final String Function(T)? optionLabel;
  final ValueChanged<T> onSelected;
  final bool required, enabled;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: display,
      optionsBuilder: (value) =>
          enabled ? options(value.text) : const Iterable.empty(),
      onSelected: onSelected,
      fieldViewBuilder: (context, text, focus, submitted) => TextFormField(
        controller: text,
        focusNode: focus,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => v == null || v.trim().isEmpty
                  ? 'Enter the ball’s name or model.'
                  : null
            : null,
        onFieldSubmitted: (_) => submitted(),
      ),
      optionsViewBuilder: (context, selected, options) {
        final values = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: constraints.maxWidth,
              height: math.min(224, values.length * 56),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: values.length,
                itemBuilder: (context, index) => InkWell(
                  onTap: () => selected(values[index]),
                  child: Container(
                    color: AutocompleteHighlightedOption.of(context) == index
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    height: 56,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      optionLabel?.call(values[index]) ??
                          display(values[index]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
