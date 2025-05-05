import 'package:flutter/material.dart';

/// Données pour générer un chip
class ChipData {
        final String text;
        final Color bgColor;
        const ChipData(this.text, this.bgColor);
}

/// Construit un Chip unique, avec contrôles de dimension/font
Widget buildChip(
        String text, {
                required Color bgColor,
                double fontSize = 10,
                EdgeInsets padding = EdgeInsets.zero,
                EdgeInsets labelPadding = const EdgeInsets.symmetric(horizontal: 4),
                VisualDensity visualDensity =
                const VisualDensity(horizontal: -4, vertical: -4)
        }) {
        return Chip(
                label: Text(text, style: TextStyle(fontSize: fontSize, color: Colors.white)),
                backgroundColor: bgColor,
                padding: padding,
                labelPadding: labelPadding,
                visualDensity: visualDensity,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap
        );
}

/// Construit une ligne de chips à partir d’une liste de [ChipData]
Widget buildChips(
        List<ChipData> chips, {
                double spacing = 4,
                double runSpacing = 2,
                double fontSize = 10
        }) {
        return Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: chips
                        .map((c) => buildChip(
                                        c.text,
                                        bgColor: c.bgColor,
                                        fontSize: fontSize
                                ))
                        .toList()
        );
}