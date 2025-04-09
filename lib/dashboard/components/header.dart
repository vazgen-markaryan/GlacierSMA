import 'package:flutter/material.dart';

class Header extends StatelessWidget {
        const Header({super.key});

        @override
        Widget build(BuildContext context) {
                return Container(
                        margin: EdgeInsets.only(top: 16.0),
                        child: Row(
                                children: [
                                        Text(
                                                "Tableau de bord",
                                                style: Theme.of(context).textTheme.titleLarge
                                        )
                                ]
                        )
                );
        }
}