import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

/// Popup identique au BatteryPopup, mais pour choisir la langue.
/// Affiché via Positioned(left:…, top:…) par ConnectionScreen.
/// Ne gère pas la position lui-même.
class LanguagePopup extends StatefulWidget {

        final double iconCenterOffset;
        final void Function(Locale) onSelect;

        const LanguagePopup({
                Key? key,
                required this.iconCenterOffset,
                required this.onSelect
        }) : super(key: key);

        @override
        LanguagePopupState createState() => LanguagePopupState();
}

class LanguagePopupState extends State<LanguagePopup>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> fade;
        late final Animation<double> scale;

        @override
        void initState() {
                super.initState();
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();
                fade = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
                scale = Tween(begin: 0.9, end: 1.0).animate(fade);
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                const double arrowWidth = 16.0;
                const double arrowHeight = 8.0;

                final supported = context.supportedLocales;
                final current = context.locale;

                return FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(
                                scale: scale,
                                child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                // 1) La flèche, traduite horizontalement pour être centrée sous le SVG
                                                Transform.translate(
                                                        offset: Offset(widget.iconCenterOffset - arrowWidth / 2, 0),
                                                        child: ClipPath(
                                                                clipper: TriangleClipper(),
                                                                child: Container(
                                                                        width: arrowWidth,
                                                                        height: arrowHeight,
                                                                        color: Colors.red
                                                                )
                                                        )
                                                ),

                                                // 2) Le container des drapeaux
                                                Container(
                                                        decoration: BoxDecoration(
                                                                color: const Color(0xFF2B2B2B),
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(color: Colors.red, width: 2)
                                                        ),
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: supported.map((locale) {
                                                                                final isSel = locale == current;
                                                                                return GestureDetector(
                                                                                        onTap: () => widget.onSelect(locale),
                                                                                        child: Padding(
                                                                                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                                                                                child: Column(
                                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                                        children: [
                                                                                                                SvgPicture.asset(
                                                                                                                        'assets/icons/${locale.languageCode}.svg',
                                                                                                                        width: 32,
                                                                                                                        height: 32
                                                                                                                ),
                                                                                                                const SizedBox(height: 4),
                                                                                                                Text(
                                                                                                                        tr('settings.language.${locale.languageCode}'),
                                                                                                                        style: TextStyle(
                                                                                                                                color: isSel ? Colors.green : Colors.grey,
                                                                                                                                fontWeight:
                                                                                                                                isSel ? FontWeight.bold : FontWeight.normal,
                                                                                                                                fontSize: 12,
                                                                                                                                decoration: TextDecoration.none
                                                                                                                        )
                                                                                                                )
                                                                                                        ]
                                                                                                )
                                                                                        )
                                                                                );
                                                                        }
                                                                ).toList()
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
        bool shouldReclip(covariant CustomClipper<Path> old) => false;
}