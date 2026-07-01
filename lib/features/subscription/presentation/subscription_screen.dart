import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  _SubscriptionPlan _selectedPlan = _SubscriptionPlan.yearly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceText = isDark ? Colors.white : Colors.black87;
    final mutedText = isDark ? Colors.white70 : Colors.black.withAlpha(153);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Gwen Plus',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF191A2A),
                          Color(0xFF1F2933),
                          Color(0xFF172826),
                        ]
                      : const [
                          Color(0xFFF1EEFF),
                          Color(0xFFF9F7F1),
                          Color(0xFFE9F6F2),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withAlpha(128)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/icon3.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Unlock Gwen support',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: surfaceText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start with a 3-day free trial, then continue with the plan that fits you best.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      _PlanOption(
                        title: 'Monthly',
                        price: '\$5.99',
                        period: 'per month',
                        isSelected: _selectedPlan == _SubscriptionPlan.monthly,
                        primaryColor: primaryColor,
                        surfaceText: surfaceText,
                        mutedText: mutedText,
                        onTap: () {
                          setState(() {
                            _selectedPlan = _SubscriptionPlan.monthly;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _PlanOption(
                        title: 'Yearly',
                        price: '\$49.99',
                        period: 'per year',
                        badge: 'Best value',
                        isSelected: _selectedPlan == _SubscriptionPlan.yearly,
                        primaryColor: primaryColor,
                        surfaceText: surfaceText,
                        mutedText: mutedText,
                        onTap: () {
                          setState(() {
                            _selectedPlan = _SubscriptionPlan.yearly;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '3 days free, then ${_selectedPlan.price} ${_selectedPlan.periodLabel}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedText,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _BenefitLine(
                        icon: Icons.chat_bubble_rounded,
                        text: 'Chat with Gwen from supportive app moments',
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _BenefitLine(
                        icon: Icons.favorite_rounded,
                        text: 'Gentle anxiety support when you need it',
                        color: Colors.pink.shade300,
                      ),
                      const SizedBox(height: 12),
                      _BenefitLine(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Personalized reflections and next steps',
                        color: Colors.teal.shade500,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment setup is coming next.'),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Try for free'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cancel anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SubscriptionPlan {
  monthly(price: '\$5.99', periodLabel: 'per month'),
  yearly(price: '\$49.99', periodLabel: 'per year');

  final String price;
  final String periodLabel;

  const _SubscriptionPlan({required this.price, required this.periodLabel});
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool isSelected;
  final Color primaryColor;
  final Color surfaceText;
  final Color mutedText;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.isSelected,
    required this.primaryColor,
    required this.surfaceText,
    required this.mutedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBackground = primaryColor.withAlpha(24);
    final borderColor = isSelected
        ? primaryColor
        : Theme.of(context).dividerColor.withAlpha(102);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBackground : Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? primaryColor : mutedText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: surfaceText,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: TextStyle(
                color: surfaceText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _BenefitLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withAlpha(166),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
