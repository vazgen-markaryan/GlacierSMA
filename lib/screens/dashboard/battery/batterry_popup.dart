import 'package:flutter/material.dart';

class BatteryPopup extends StatelessWidget {
        final double voltage;
        final double percent;
        final Color color;
        final VoidCallback onClose;
        final BuildContext targetContext;

        const BatteryPopup({
                super.key,
                required this.voltage,
                required this.percent,
                required this.color,
                required this.onClose,
                required this.targetContext
        });

        @override
        Widget build(BuildContext context) {
                final box = targetContext.findRenderObject() as RenderBox;
                final position = box.localToGlobal(Offset.zero);

                return Positioned(
                        top: position.dy + 40,
                        left: position.dx - 10,
                        child: Material(
                                color: Colors.transparent,
                                child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                                Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                                color: const Color(0xFF2B2B2B),
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(color: color, width: 2)
                                                        ),
                                                        child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                        Text("Voltage : ${voltage.toStringAsFixed(2)} V", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                                                                        Text("État : ${(percent * 100).round()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold))
                                                                ]
                                                        )
                                                ),
                                                // Flèche en bas
                                                Positioned(
                                                        top: -8,
                                                        left: 20,
                                                        child: ClipPath(
                                                                clipper: TriangleClipper(),
                                                                child: Container(
                                                                        width: 16,
                                                                        height: 10,
                                                                        color: color
                                                                )
                                                        )
                                                )
                                        ]
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