import 'sensors_data.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SensorDetailsPopup extends StatefulWidget {
        final SensorsData sensor;

        const SensorDetailsPopup({super.key, required this.sensor});

        @override
        State<SensorDetailsPopup> createState() => SensorDetailsPopupState();
}

class SensorDetailsPopupState extends State<SensorDetailsPopup>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> scale;

        @override
        void initState() {
                super.initState();
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();

                scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: ScaleTransition(
                                scale: scale,
                                child: Center(
                                        child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                        maxWidth: 500,
                                                        maxHeight: MediaQuery.of(context).size.height * 0.75
                                                ),
                                                child: Container(
                                                        decoration: BoxDecoration(
                                                                color: secondaryColor,
                                                                borderRadius: BorderRadius.circular(16)
                                                        ),
                                                        child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                        // Header stylisé
                                                                        Container(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                                                decoration: const BoxDecoration(
                                                                                        color: Color(0xFF1F1F1F),
                                                                                        borderRadius: BorderRadius.only(
                                                                                                topLeft: Radius.circular(16),
                                                                                                topRight: Radius.circular(16)
                                                                                        )
                                                                                ),
                                                                                child: Row(
                                                                                        children: [
                                                                                                Expanded(
                                                                                                        child: Text(
                                                                                                                widget.sensor.title ?? "Détails du capteur",
                                                                                                                style: const TextStyle(
                                                                                                                        color: primaryColor,
                                                                                                                        fontSize: 20,
                                                                                                                        fontWeight: FontWeight.bold
                                                                                                                )
                                                                                                        )
                                                                                                ),
                                                                                                GestureDetector(
                                                                                                        onTap: () => Navigator.of(context).pop(),
                                                                                                        child: const Icon(Icons.close, color: Colors.red, size: 28)
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        ),

                                                                        // Corps de la popup
                                                                        Flexible(
                                                                                child: Padding(
                                                                                        padding: const EdgeInsets.all(20),
                                                                                        child: Scrollbar(
                                                                                                thumbVisibility: true,
                                                                                                radius: const Radius.circular(8),
                                                                                                thickness: 6,
                                                                                                child: Padding(
                                                                                                        padding: const EdgeInsets.only(right: 20),
                                                                                                        child: SingleChildScrollView(
                                                                                                                child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                                                                        valueListenable: widget.sensor.dataNotifier,
                                                                                                                        builder: (context, data, _) {
                                                                                                                                final items = data.entries.toList();

                                                                                                                                return Column(
                                                                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                                        children: [
                                                                                                                                                Text(
                                                                                                                                                        "Mise à jour : ${DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(DateTime.now())}",
                                                                                                                                                        style: const TextStyle(
                                                                                                                                                                color: Colors.white54,
                                                                                                                                                                fontSize: 16,
                                                                                                                                                                fontStyle: FontStyle.italic
                                                                                                                                                        )
                                                                                                                                                ),
                                                                                                                                                const SizedBox(height: 12),
                                                                                                                                                ...items.map((entry) {
                                                                                                                                                                final key = entry.key;
                                                                                                                                                                final value = entry.value;

                                                                                                                                                                return Container(
                                                                                                                                                                        margin: const EdgeInsets.only(bottom: 10),
                                                                                                                                                                        padding: const EdgeInsets.symmetric(
                                                                                                                                                                                vertical: 6, horizontal: 8),
                                                                                                                                                                        decoration: BoxDecoration(
                                                                                                                                                                                color: Colors.white10,
                                                                                                                                                                                borderRadius: BorderRadius.circular(8)
                                                                                                                                                                        ),
                                                                                                                                                                        child: Row(
                                                                                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                                                                                children: [
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
                                                                                                                                                                                                                key.name,
                                                                                                                                                                                                                style: const TextStyle(
                                                                                                                                                                                                                        color: Colors.white70,
                                                                                                                                                                                                                        fontSize: 15
                                                                                                                                                                                                                )
                                                                                                                                                                                                        )
                                                                                                                                                                                                ]
                                                                                                                                                                                        ),
                                                                                                                                                                                        Flexible(
                                                                                                                                                                                                child: Text(
                                                                                                                                                                                                        value.toString(),
                                                                                                                                                                                                        style: const TextStyle(
                                                                                                                                                                                                                color: Colors.white,
                                                                                                                                                                                                                fontWeight: FontWeight.bold
                                                                                                                                                                                                        ),
                                                                                                                                                                                                        textAlign: TextAlign.right,
                                                                                                                                                                                                        overflow: TextOverflow.ellipsis
                                                                                                                                                                                                )
                                                                                                                                                                                        )
                                                                                                                                                                                ]
                                                                                                                                                                        )
                                                                                                                                                                );
                                                                                                                                                        }
                                                                                                                                                )
                                                                                                                                        ]
                                                                                                                                );
                                                                                                                        }
                                                                                                                )
                                                                                                        )
                                                                                                )
                                                                                        )
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                )
                                        )
                                )
                        )
                );
        }
}