import 'package:flutter/material.dart';

class DebugToggleButton extends StatelessWidget {
        final bool isDebugVisible;
        final VoidCallback onToggle;

        const DebugToggleButton({
                super.key,
                required this.isDebugVisible,
                required this.onToggle
        });

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                                onTap: onToggle,
                                child: Row(
                                        children: [
                                                const Text("D", style: TextStyle(fontSize: 16, color: Colors.white)), //DEBUG SWITCH
                                                const SizedBox(width: 8),
                                                Container(
                                                        width: 60,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                                color: isDebugVisible ? Colors.green : Colors.grey,
                                                                borderRadius: BorderRadius.circular(15)
                                                        ),
                                                        child: AnimatedAlign(
                                                                duration: const Duration(milliseconds: 200),
                                                                alignment: isDebugVisible ? Alignment.centerRight : Alignment.centerLeft,
                                                                child: Container(
                                                                        width: 25,
                                                                        height: 25,
                                                                        decoration: const BoxDecoration(
                                                                                color: Colors.white,
                                                                                shape: BoxShape.circle
                                                                        )
                                                                )
                                                        )
                                                )
                                        ]
                                )
                        )
                );
        }
}