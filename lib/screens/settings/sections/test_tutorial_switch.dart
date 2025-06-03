import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestTutorialSwitch extends StatefulWidget {
        @override
        State<TestTutorialSwitch> createState() => TestTutorialSwitchState();
}

class TestTutorialSwitchState extends State<TestTutorialSwitch> {
        bool skipTutorial = false;

        @override
        void initState() {
                super.initState();
                load();
        }

        Future<void> load() async {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                                skipTutorial = prefs.getBool('skip_test_tutorial') ?? false;
                        }
                );
        }

        Future<void> onChanged(bool? value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('skip_test_tutorial', value ?? false);
                setState(() {
                                skipTutorial = value ?? false;
                        }
                );
        }

        @override
        Widget build(BuildContext context) {
                return CheckboxListTile(
                        value: skipTutorial,
                        onChanged: onChanged,
                        title: Text(tr("test.skip_tutorial_test_page"))
                );
        }
}