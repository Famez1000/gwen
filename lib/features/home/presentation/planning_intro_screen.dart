import 'package:flutter/material.dart';

import 'planning_destination_screen.dart';

class PlanningIntroScreen extends StatelessWidget {
  const PlanningIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final mutedText = isDark ? Colors.white60 : Colors.black.withAlpha(153);
    final introCardColor = isDark
        ? Colors.white.withAlpha(18)
        : primaryColor.withAlpha(18);
    final introCardBorderColor = isDark
        ? Colors.white.withAlpha(20)
        : primaryColor.withAlpha(28);

    const introText =
        "The best way to overcome anxiety and panic attacks is with a structured plan - a personal plan to gradually vanquish it. Let Gwyn help you create one.\n\nWhether you want to just cope with anxiety, understand it better, or begin the journey of healing, simply tell Gwyn what you'd like to achieve, and she will create a personalized action plan for you.";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan with Gwyn',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: Image.asset(
                    'assets/images/gwyn-plan.png',
                    width: 116,
                    height: 116,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Let's make a plan together",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: introCardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: introCardBorderColor),
              ),
              child: Text(
                introText,
                style: TextStyle(
                  fontSize: 17.25,
                  height: 1.45,
                  color: mutedText,
                ),
              ),
            ),
            const SizedBox(height: 44),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlanningDestinationScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Let's start",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
