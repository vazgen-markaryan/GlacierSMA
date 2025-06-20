import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

class HardwarePopup extends StatefulWidget {
        final ValueNotifier<double?> voltageNotifier;
        final Color color;
        final Offset position;
        final ValueNotifier<Map<String, double?>> ramNotifier;

        const HardwarePopup({
                super.key,
                required this.voltageNotifier,
                required this.color,
                required this.position,
                required this.ramNotifier
        });

        @override
        State<HardwarePopup> createState() => HardwarePopupState();

        static void show({
                required BuildContext context,
                required BuildContext iconKey,
                required ValueNotifier<double?> voltageNotifier,
                required ValueNotifier<Map<String, double?>> ramNotifier
        }) {
                final renderObject = iconKey.findRenderObject();
                if (renderObject is! RenderBox) return;
                final box = renderObject;
                final position = box.localToGlobal(Offset.zero);
                final overlay = Overlay.of(context);

                late final OverlayEntry entry;

                entry = OverlayEntry(
                        builder: (_) => GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => entry.remove(),
                                child: Stack(
                                        children: [
                                                HardwarePopup(
                                                        voltageNotifier: voltageNotifier,
                                                        ramNotifier: ramNotifier,
                                                        position: position,
                                                        color: Colors.green
                                                )
                                        ]
                                )
                        )
                );

                overlay.insert(entry);
        }
}

class HardwarePopupState extends State<HardwarePopup> with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> fade;
        late final Animation<double> scale;

        late bool showStackUsageText;
        late bool showHeapUsageText;
        Timer? toggleTimer;

        @override
        void initState() {
                super.initState();

                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();

                fade = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
                scale = Tween(begin: 0.9, end: 1.0).animate(fade);

                showStackUsageText = true;
                showHeapUsageText = true;

                toggleTimer = Timer.periodic(
                        const Duration(seconds: 2), (_) {
                                setState(
                                        () {
                                                showStackUsageText = !showStackUsageText;
                                                showHeapUsageText = !showHeapUsageText;
                                        }
                                );
                        }
                );
        }

        @override
        void dispose() {
                controller.dispose();
                toggleTimer?.cancel();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                final position = widget.position;
                final screenWidth = MediaQuery.of(context).size.width;

                const iconSize = 30.0;
                const arrowWidth = 16.0;
                const arrowRightOffset = 10.0;

                final iconCenterX = position.dx + iconSize / 2;
                final arrowCenterInPopup = arrowRightOffset + arrowWidth / 2;
                final right = screenWidth - iconCenterX - arrowCenterInPopup;

                return Positioned(
                        top: position.dy + iconSize + 15,
                        right: right,
                        child: Material(
                                color: Colors.transparent,
                                elevation: 6,
                                borderRadius: BorderRadius.circular(12),
                                shadowColor: Colors.black45,
                                child: ValueListenableBuilder<double?>(
                                        valueListenable: widget.voltageNotifier,
                                        builder: (context, voltage, _) {
                                                final (percent, iconPath, color) = getBatteryInfo(voltage);
                                                final isLow = percent < 0.33;

                                                return ValueListenableBuilder<Map<String, double?>>(
                                                        valueListenable: widget.ramNotifier,
                                                        builder: (context, ram, __) {
                                                                return Stack(
                                                                        clipBehavior: Clip.none,
                                                                        children: [
                                                                                Container(
                                                                                        padding: const EdgeInsets.all(12),
                                                                                        decoration: BoxDecoration(
                                                                                                color: const Color(0xFF2B2B2B),
                                                                                                borderRadius: BorderRadius.circular(10),
                                                                                                border: Border.all(color: Colors.green, width: 2),
                                                                                                boxShadow: const[
                                                                                                        BoxShadow(
                                                                                                                color: Colors.black45,
                                                                                                                blurRadius: 10,
                                                                                                                offset: Offset(0, 4)
                                                                                                        )
                                                                                                ]
                                                                                        ),
                                                                                        child: Column(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                        // Ligne voltage
                                                                                                        Row(
                                                                                                                children: [
                                                                                                                        SvgPicture.asset(iconPath,
                                                                                                                                height: 18,
                                                                                                                                colorFilter: ColorFilter.mode(
                                                                                                                                        isLow ? const Color.fromRGBO(255, 0, 0, 1) : color,
                                                                                                                                        BlendMode.srcIn
                                                                                                                                )
                                                                                                                        ),

                                                                                                                        const SizedBox(width: 8),

                                                                                                                        Text(
                                                                                                                                voltage != null
                                                                                                                                        ? tr('home.hardware_info.voltage', namedArgs: {'value': voltage.toStringAsFixed(2)})
                                                                                                                                        : tr('home.hardware_info.voltage_unknown'),
                                                                                                                                style: TextStyle(
                                                                                                                                        color: isLow ? const Color.fromRGBO(255, 0, 0, 1) : color,
                                                                                                                                        fontWeight: FontWeight.bold)
                                                                                                                        )
                                                                                                                ]
                                                                                                        ),

                                                                                                        const SizedBox(height: 4),

                                                                                                        // Ligne état batterie
                                                                                                        Row(
                                                                                                                children: [
                                                                                                                        SvgPicture.asset(iconPath,
                                                                                                                                height: 18,
                                                                                                                                colorFilter: ColorFilter.mode(
                                                                                                                                        isLow ? const Color.fromRGBO(255, 0, 0, 1) : color,
                                                                                                                                        BlendMode.srcIn)
                                                                                                                        ),

                                                                                                                        const SizedBox(width: 8),

                                                                                                                        Text(
                                                                                                                                tr('home.hardware_info.state', namedArgs: {'percent': (percent * 100).round().toString()}),
                                                                                                                                style: TextStyle(
                                                                                                                                        color: isLow ? const Color.fromRGBO(255, 0, 0, 1) : color,
                                                                                                                                        fontWeight: FontWeight.bold)
                                                                                                                        )
                                                                                                                ]
                                                                                                        ),

                                                                                                        const SizedBox(height: 4),

                                                                                                        // RAM utilisé
                                                                                                        Builder(
                                                                                                                builder: (context) {
                                                                                                                        final formatter = NumberFormat.decimalPattern('fr_FR');
                                                                                                                        final ramFree = (ram['ram_stack'] ?? 0) + (ram['ram_heap'] ?? 0);
                                                                                                                        final ramUsed = (32768.0 - ramFree).clamp(0.0, 32768.0);
                                                                                                                        final usedPercentage = ramUsed / 32768.0;
                                                                                                                        final color = usedPercentage < 0.5 ? Colors.green : usedPercentage < 0.8 ? Colors.orange : Colors.red;
                                                                                                                        final ramLabel = '${formatter.format(ramUsed)} / ${formatter.format(32768)} ${tr('home.hardware_info.bytes')}';
                                                                                                                        final ramPercentage = '(${(usedPercentage * 100).round()}%)';

                                                                                                                        // Mesure exacte de la largeur du texte
                                                                                                                        final textPainter = TextPainter(
                                                                                                                                text: TextSpan(
                                                                                                                                        text: ramLabel,
                                                                                                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                                                                                                                                ),
                                                                                                                                textDirection: ui.TextDirection.ltr
                                                                                                                        )..layout();

                                                                                                                        final barWidth = textPainter.size.width;

                                                                                                                        return Column(
                                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                                children: [
                                                                                                                                        Row(
                                                                                                                                                children: [
                                                                                                                                                        SvgPicture.asset('assets/icons/ram.svg', height: 16, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
                                                                                                                                                        const SizedBox(width: 6),
                                                                                                                                                        Text(
                                                                                                                                                                tr('home.hardware_info.ram_used', namedArgs: {'ramPercentage': ramPercentage.toString()}),
                                                                                                                                                                style: TextStyle(
                                                                                                                                                                        color: color,
                                                                                                                                                                        fontWeight: FontWeight.bold,
                                                                                                                                                                        fontSize: 12
                                                                                                                                                                )
                                                                                                                                                        )
                                                                                                                                                ]
                                                                                                                                        ),

                                                                                                                                        const SizedBox(height: 4),

                                                                                                                                        // Barre exactement aussi large que le texte
                                                                                                                                        SizedBox(
                                                                                                                                                width: barWidth,
                                                                                                                                                child: ClipRRect(
                                                                                                                                                        borderRadius: BorderRadius.circular(6),
                                                                                                                                                        child: Container(
                                                                                                                                                                height: 10,
                                                                                                                                                                color: Colors.grey.shade700,
                                                                                                                                                                child: FractionallySizedBox(
                                                                                                                                                                        alignment: Alignment.centerLeft,
                                                                                                                                                                        widthFactor: usedPercentage,
                                                                                                                                                                        child: Container(color: color)
                                                                                                                                                                )
                                                                                                                                                        )
                                                                                                                                                )
                                                                                                                                        ),

                                                                                                                                        const SizedBox(height: 4),

                                                                                                                                        Text(
                                                                                                                                                ramLabel,
                                                                                                                                                style: TextStyle(
                                                                                                                                                        color: color,
                                                                                                                                                        fontWeight: FontWeight.bold,
                                                                                                                                                        fontSize: 12
                                                                                                                                                )
                                                                                                                                        )
                                                                                                                                ]
                                                                                                                        );
                                                                                                                }
                                                                                                        )
                                                                                                ]
                                                                                        )
                                                                                ),

                                                                                Positioned(
                                                                                        top: -8,
                                                                                        right: arrowRightOffset,
                                                                                        child: ClipPath(
                                                                                                clipper: TriangleClipper(),
                                                                                                child: Container(
                                                                                                        width: arrowWidth,
                                                                                                        height: 10,
                                                                                                        color: Colors.green
                                                                                                )
                                                                                        )
                                                                                )
                                                                        ]
                                                                );
                                                        }
                                                );
                                        }
                                )
                        )
                );
        }
}

class TriangleClipper extends CustomClipper<Path> {
        @override
        Path getClip(Size size) {
                final path = Path();
                path.moveTo(0, size.height);
                path.lineTo(size.width / 2, 0);
                path.lineTo(size.width, size.height);
                path.close();
                return path;
        }

        @override
        bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Fournit la fonction getBatteryInfo pour convertir une tension en pourcentage, chemin d'icône et couleur correspondants.
(double, String, Color) getBatteryInfo(double? voltage) {
        final percent = (((voltage ?? 11.0).clamp(11.0, 12.7) - 11.0) / 1.7).clamp(0.0, 1.0);
        if (percent >= 0.66) return (percent, "assets/icons/battery-full.svg", Colors.green);
        if (percent >= 0.33) return (percent, "assets/icons/battery-mid.svg", Colors.orange);
        return (percent, "assets/icons/battery-low.svg", Colors.red);
}