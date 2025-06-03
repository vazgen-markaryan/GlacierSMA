import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Popup permettant de configurer, pour un capteur donné, les plages [Min/Max] de chaque DataMap associé.
/// On peut “Reset to Defaults” ou appliquer les valeurs.
class TestRangeSetupPopup extends StatefulWidget {
        /// Le capteur concerné
        final SensorsData sensor;

        /// Plages “par défaut” (minMaxRanges issu de constants.dart)
        final Map<DataMap, RangeValues> defaults;

        /// Plages actuellement affichées/éditées (Map clé → RangeValues)
        final Map<DataMap, RangeValues> currents;

        /// Callback appelé quand l’utilisateur appuie sur “Apply” pour retourner la
        /// nouvelle Map<DataMap, RangeValues>
        final void Function(Map<DataMap, RangeValues>) onApply;

        const TestRangeSetupPopup({
                required this.sensor,
                required this.defaults,
                required this.currents,
                required this.onApply,
                Key? key
        }) : super(key: key);

        @override
        State<TestRangeSetupPopup> createState() => TestRangeSetupPopupState();
}

class TestRangeSetupPopupState extends State<TestRangeSetupPopup> {
        /// TextEditingControllers pour les champs “Min” de chaque DataMap
        late final Map<DataMap, TextEditingController> controllersMin;

        /// TextEditingControllers pour les champs “Max” de chaque DataMap
        late final Map<DataMap, TextEditingController> controllersMax;

        /// Valeurs actuellement appliquées dans le popup (clone de [widget.currents])
        late Map<DataMap, RangeValues> appliedValues;

        /// Message d’erreur si une plage est invalide (affiché en rouge)
        String? rangeError;

        @override
        void initState() {
                super.initState();

                // Initialisation des contrôleurs à partir des valeurs “currents”
                controllersMin = {};
                controllersMax = {};
                for (var key in widget.currents.keys) {
                        final range = widget.currents[key]!;
                        controllersMin[key] = TextEditingController(text: range.start.toInt().toString());
                        controllersMax[key] = TextEditingController(text: range.end.toInt().toString());
                }

                // Clone des map “currents” pour ne pas modifier directement la prop reçue
                appliedValues = Map<DataMap, RangeValues>.from(widget.currents);
        }

        @override
        void dispose() {
                for (var c in controllersMin.values) {
                        c.dispose();
                }
                for (var c in controllersMax.values) {
                        c.dispose();
                }
                super.dispose();
        }

        /// Vérifie si au moins une plage a changé ET si toutes les plages sont valides.
        /// - Si un min/max ne respecte pas les contraintes globales (min ≤ max et à l’intérieur de [minMaxRanges]), on remplit [_rangeError] puis renvoie false.
        /// - Si toutes sont valides mais aucune n’a changé, renvoie false.
        /// - Sinon (au moins un changement), renvoie true.
        bool hasRangeChangesAndValid() {
                rangeError = null;

                bool anyChanged = false;
                for (var key in widget.currents.keys) {
                        final def = widget.defaults[key]!;
                        final startValue = int.tryParse(controllersMin[key]!.text) ?? def.start.toInt();
                        final endValue = int.tryParse(controllersMax[key]!.text) ?? def.end.toInt();

                        // Validation de la plage (min ≤ max et au sein des bornes globales)
                        if (!isRangeValid(key, startValue, endValue)) {
                                rangeError = tr('test.min_max_constraint');
                                return false;
                        }

                        // Comparaison avec la valeur déjà appliquée
                        final newRange = RangeValues(startValue.toDouble(), endValue.toDouble());
                        if (appliedValues[key] != newRange) {
                                anyChanged = true;
                        }
                }

                return anyChanged;
        }

        /// Renvoie true si [min] et [max] sont à l’intérieur de la plage autorisée définie dans [minMaxRanges], et si min ≤ max.
        bool isRangeValid(DataMap key, int min, int max) {
                final sensorHeader = widget.sensor.header;
                final minMax = minMaxRanges[sensorHeader]?[key.header];
                if (minMax == null) {
                        // Si aucune contrainte globale définie, on accepte par défaut
                        return min <= max;
                }
                return (min <= max) && (min >= minMax.start) && (max <= minMax.end);
        }

        /// Méthode pour remettre tous les champs à leur valeur “defaults”
        void resetToDefaults() {
                // Pour chaque DataMap, on remet les contrôleurs à la valeur par défaut
                for (var key in widget.defaults.keys) {
                        final defaultRange = widget.defaults[key]!;
                        controllersMin[key]!.text = defaultRange.start.toInt().toString();
                        controllersMax[key]!.text = defaultRange.end.toInt().toString();
                }

                // On met à jour appliedValues en mémoire (pour désactiver le bouton “Apply” si nécessaire)
                appliedValues = Map<DataMap, RangeValues>.from(widget.defaults);

                // Il faut également propager ces valeurs par défaut dans widget.currents, sinon, à la réouverture, on continuera de lire l’ancienne valeur.
                for (var key in widget.defaults.keys) {
                        widget.currents[key] = widget.defaults[key]!;
                }

                setState(() {
                                rangeError = null;
                        }
                );
        }

        /// Construit un champ TextField “Min” ou “Max” avec unité et style conditionnel
        Widget buildRangeField({
                required String label,
                required TextEditingController controller,
                required DataMap key,
                required TextEditingController minController,
                required TextEditingController maxController,
                required VoidCallback onChanged,
                required String unit,
                required bool Function(DataMap, int, int) isRangeValid
        }) {
                final minVal = int.tryParse(minController.text) ?? 0;
                final maxVal = int.tryParse(maxController.text) ?? 0;
                final invalid = !isRangeValid(key, minVal, maxVal);

                return Expanded(
                        child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                        TextField(
                                                controller: controller,
                                                decoration: InputDecoration(
                                                        labelText: label,
                                                        labelStyle: TextStyle(
                                                                color: invalid ? Colors.red : Colors.white70,
                                                                fontWeight: invalid ? FontWeight.bold : FontWeight.normal
                                                        ),
                                                        enabledBorder: UnderlineInputBorder(
                                                                borderSide: BorderSide(
                                                                        color: invalid ? Colors.red : Colors.white38
                                                                )
                                                        ),

                                                        // On ajoute de l’espace à droite pour afficher l’unité sans chevauchement
                                                        contentPadding: const EdgeInsets.only(right: 40)
                                                ),
                                                style: TextStyle(
                                                        color: invalid ? Colors.red : Colors.white,
                                                        fontWeight: invalid ? FontWeight.bold : FontWeight.normal
                                                ),
                                                keyboardType: TextInputType.number,
                                                onChanged: (_) => onChanged()
                                        ),

                                        // Etiquette “unité” flottante à droite
                                        Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Text(
                                                        unit,
                                                        style: const TextStyle(color: Colors.white70, fontSize: 14)
                                                )
                                        )
                                ]
                        )
                );
        }

        @override
        Widget build(BuildContext context) {
                // Vérification globale de la validité
                bool valid = true;
                for (var key in widget.currents.keys) {
                        final def = widget.defaults[key]!;
                        final minVal = int.tryParse(controllersMin[key]!.text) ?? def.start.toInt();
                        final maxVal = int.tryParse(controllersMax[key]!.text) ?? def.end.toInt();
                        if (!isRangeValid(key, minVal, maxVal)) {
                                valid = false;
                                break;
                        }
                }

                // Détection de tout changement dans les plages
                final hasChanged = widget.currents.keys.any(
                        (key) {
                                final def = widget.defaults[key]!;
                                final minVal = int.tryParse(controllersMin[key]!.text) ?? def.start.toInt();
                                final maxVal = int.tryParse(controllersMax[key]!.text) ?? def.end.toInt();
                                final newRange = RangeValues(minVal.toDouble(), maxVal.toDouble());
                                return appliedValues[key] != newRange;
                        }
                );

                return CustomPopup(
                        title: tr(widget.sensor.title ?? ''),
                        content: SingleChildScrollView(
                                child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                // Pour chaque DataMap du capteur, on affiche icône + nom + champs Min/Max
                                                for (var key in widget.currents.keys)
                                                        Container(
                                                                margin: const EdgeInsets.only(bottom: 12, right: 8),
                                                                padding: const EdgeInsets.all(12),
                                                                decoration: BoxDecoration(
                                                                        color: Colors.white10,
                                                                        borderRadius: BorderRadius.circular(8)
                                                                ),
                                                                child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                                // Ligne icône + nom du DataMap
                                                                                Row(
                                                                                        children: [
                                                                                                SvgPicture.asset(
                                                                                                        key.svgLogo,
                                                                                                        height: 24,
                                                                                                        width: 24,
                                                                                                        colorFilter: const ColorFilter.mode(
                                                                                                                Colors.white70,
                                                                                                                BlendMode.srcIn
                                                                                                        )
                                                                                                ),
                                                                                                const SizedBox(width: 8),
                                                                                                Text(
                                                                                                        tr(key.name),
                                                                                                        style: const TextStyle(
                                                                                                                color: Colors.white70,
                                                                                                                fontSize: 15
                                                                                                        )
                                                                                                )
                                                                                        ]
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                // Ligne champs “Min” et “Max”
                                                                                Row(
                                                                                        children: [
                                                                                                buildRangeField(
                                                                                                        label: tr("test.min"),
                                                                                                        controller: controllersMin[key]!,
                                                                                                        key: key,
                                                                                                        minController: controllersMin[key]!,
                                                                                                        maxController: controllersMax[key]!,
                                                                                                        onChanged: () => setState(() {
                                                                                                                }
                                                                                                        ),
                                                                                                        unit: getUnitForHeader(key.header),
                                                                                                        isRangeValid: isRangeValid
                                                                                                ),
                                                                                                const SizedBox(width: 12),
                                                                                                buildRangeField(
                                                                                                        label: tr("test.max"),
                                                                                                        controller: controllersMax[key]!,
                                                                                                        key: key,
                                                                                                        minController: controllersMin[key]!,
                                                                                                        maxController: controllersMax[key]!,
                                                                                                        onChanged: () => setState(() {
                                                                                                                }
                                                                                                        ),
                                                                                                        unit: getUnitForHeader(key.header),
                                                                                                        isRangeValid: isRangeValid
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        ]
                                                                )
                                                        ),

                                                // Si une plage est invalide, on affiche un message d’erreur
                                                if (!valid)
                                                Padding(
                                                        padding: const EdgeInsets.only(bottom: 8),
                                                        child: Text(
                                                                tr('test.min_max_constraint'),
                                                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                                                        )
                                                ),

                                                // Bouton “Reset to Defaults” unique
                                                ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                        onPressed: resetToDefaults,
                                                        child: Text(tr('test.reset_default'))
                                                )
                                        ]
                                )
                        ),

                        actions: [
                                // Bouton “Cancel” ferme simplement le popup
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(tr('test.cancel'))
                                ),

                                // Bouton “Apply” n’est activé que si tout est valide ET si au moins une plage a changé
                                TextButton(
                                        onPressed: (valid && hasChanged)
                                                ? () {
                                                        // On met à jour appliedValues avec les valeurs saisies
                                                        for (var key in widget.currents.keys) {
                                                                final def = widget.defaults[key]!;
                                                                final minVal = int.tryParse(controllersMin[key]!.text) ?? def.start.toInt();
                                                                final maxVal = int.tryParse(controllersMax[key]!.text) ?? def.end.toInt();
                                                                widget.currents[key] = RangeValues(minVal.toDouble(), maxVal.toDouble());
                                                        }

                                                        // On alimente le clone appliedValues pour la suite
                                                        appliedValues
                                                        ..clear()
                                                        ..addAll(widget.currents);

                                                        // On appelle le callback pour renvoyer la nouvelle Map au parent
                                                        widget.onApply(widget.currents);

                                                        // On ferme le popup
                                                        Navigator.of(context).pop();
                                                }
                                                : null,
                                        child: Text(tr('test.apply'))
                                )
                        ]
                );
        }
}