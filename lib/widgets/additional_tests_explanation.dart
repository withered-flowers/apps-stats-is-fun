import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'dart:math' as math;

class AdditionalTestsExplanation extends StatefulWidget {
  const AdditionalTestsExplanation({super.key});

  @override
  State<AdditionalTestsExplanation> createState() =>
      _AdditionalTestsExplanationState();
}

class _AdditionalTestsExplanationState
    extends State<AdditionalTestsExplanation> {
  final _selectedIndex = signal(0); // 0=ANOVA, 1=Chi-Squared

  // ANOVA Signals
  // ANOVA Signals (Backend Latency in ms)
  final _meanA = signal(50.0); // Legacy
  final _meanB = signal(45.0); // Refactored
  final _meanC = signal(40.0); // Experimental
  final _variance = 5.0; // Fixed within-group variance for simplicity

  // Chi-Square Signals (Coin Flip Example)
  // Chi-Square Signals (Churn Analysis)
  // Users who churned out of 100 users per plan
  final _churnBasic = signal(40.0);
  final _churnPro = signal(20.0);
  final _churnEnterprise = signal(10.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.science_rounded, color: colorScheme.secondary),
        title: Text(
          'Advanced Tests Playground',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Interactive ANOVA & Chi-Squared'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Watch((context) {
                  return ToggleButtons(
                    isSelected: [
                      0,
                      1,
                    ].map((i) => i == _selectedIndex.value).toList(),
                    onPressed: (index) {
                      _selectedIndex.value = index;
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: 100,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('One-Way ANOVA'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Chi-Squared Test'),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                Watch((context) {
                  return IndexedStack(
                    index: _selectedIndex.value,
                    children: [
                      _buildAnovaDemo(context),
                      _buildChiSquaredDemo(context),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnovaDemo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Computed F-Statistic (Simplified for Demo)
    // F = Var(Between) / Var(Within)
    // Var(Within) is fixed at 5.0
    // Var(Between) is variance of the 3 means * n (assume n=10 per group)
    return Column(
      key: const ValueKey('anova_demo'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'One-Way ANOVA (Backend Algorithm Performance)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare the latency (ms) of 3 search algorithms. H0: No difference. H1: Significant difference.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _InteractiveSignalSlider(
          label: 'Algorithm A (Legacy)',
          signal: _meanA,
          min: 0,
          max: 120,
          color: colorScheme.primary,
        ),
        _InteractiveSignalSlider(
          label: 'Algorithm B (Refactored)',
          signal: _meanB,
          min: 0,
          max: 120,
          color: colorScheme.secondary,
        ),
        _InteractiveSignalSlider(
          label: 'Algorithm C (Experimental)',
          signal: _meanC,
          min: 0,
          max: 120,
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: 24),
        Watch((context) {
          final ma = _meanA.value;
          final mb = _meanB.value;
          final mc = _meanC.value;

          // Calculate F
          final grandMean = (ma + mb + mc) / 3;
          final n = 10;
          final ssb =
              n *
              (math.pow(ma - grandMean, 2) +
                  math.pow(mb - grandMean, 2) +
                  math.pow(mc - grandMean, 2));
          final msb = ssb / (3 - 1);
          final msw = _variance; // Fixed assumption
          final f = msb / msw;

          // P-value approx (simple threshold for demo)
          // Critical F(2, 27) at 0.05 is ~3.35
          final isSignificant = f > 3.35;
          final color = isSignificant ? colorScheme.error : colorScheme.primary;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'F-Statistic: ${f.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isSignificant
                          ? 'Groups are DIFFERENT (p < 0.05)'
                          : 'Groups are Similar (p > 0.05)',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _AnovaPainter(
                    ma: ma,
                    mb: mb,
                    mc: mc,
                    colorA: colorScheme.primary,
                    colorB: colorScheme.secondary,
                    colorC: colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildChiSquaredDemo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      key: const ValueKey('chisquared_demo'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi-Squared Test (Churn Analysis)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Do users Churn differently based on their Plan? (100 users/plan)\nH0: Plan doesn\'t affect Churn. H1: Plan affects Churn.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _InteractiveSignalSlider(
          label: 'Basic Plan Churners',
          signal: _churnBasic,
          min: 0,
          max: 100,
          color: colorScheme.primary,
        ),
        _InteractiveSignalSlider(
          label: 'Pro Plan Churners',
          signal: _churnPro,
          min: 0,
          max: 100,
          color: colorScheme.secondary,
        ),
        _InteractiveSignalSlider(
          label: 'Enterprise Plan Churners',
          signal: _churnEnterprise,
          min: 0,
          max: 100,
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: 24),
        Watch((context) {
          final cB = _churnBasic.value;
          final cP = _churnPro.value;
          final cE = _churnEnterprise.value;

          // Total Observed
          final totalChurn = cB + cP + cE;
          final totalUsers = 300.0;

          // Expected Churn Rate (if H0 is true, all plans have same churn rate)
          final expChurnPerGroup =
              (100 * totalChurn) / totalUsers; // or totalChurn / 3
          final expStayPerGroup = 100 - expChurnPerGroup;

          // Chi2 Calculation (Sum of (O-E)^2 / E for all 6 cells)
          // Cells: Basic-Churn, Basic-Stay, Pro-Churn, Pro-Stay, Ent-Churn, Ent-Stay
          double calcCell(double obs, double exp) {
            if (exp == 0) return 0;
            return math.pow(obs - exp, 2) / exp;
          }

          double chi2 = 0;
          // Basic
          chi2 += calcCell(cB, expChurnPerGroup);
          chi2 += calcCell(100 - cB, expStayPerGroup);
          // Pro
          chi2 += calcCell(cP, expChurnPerGroup);
          chi2 += calcCell(100 - cP, expStayPerGroup);
          // Enterprise
          chi2 += calcCell(cE, expChurnPerGroup);
          chi2 += calcCell(100 - cE, expStayPerGroup);

          // Critical Chi2(df=2) at 0.05 is 5.991
          final isDependent = chi2 > 5.991;
          final color = isDependent ? colorScheme.error : colorScheme.primary;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'χ² Statistic: ${chi2.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        isDependent
                            ? 'Plans affect Churn! (p < 0.05)'
                            : 'No Difference (p > 0.05)',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ChiSqPainter(
                    cB: cB,
                    cP: cP,
                    cE: cE,
                    expChurn: expChurnPerGroup,
                    colorB: colorScheme.primary,
                    colorP: colorScheme.secondary,
                    colorE: colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _InteractiveSignalSlider extends StatelessWidget {
  final String label;
  final Signal<double> signal;
  final double min;
  final double max;
  final Color color;

  const _InteractiveSignalSlider({
    required this.label,
    required this.signal,
    required this.min,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(signal.value.toStringAsFixed(0)),
            ],
          ),
          Slider(
            value: signal.value.clamp(min, max),
            min: min,
            max: max,
            activeColor: color,
            onChanged: (v) => signal.value = v,
          ),
        ],
      );
    });
  }
}

class _AnovaPainter extends CustomPainter {
  final double ma, mb, mc;
  final Color colorA, colorB, colorC;

  _AnovaPainter({
    required this.ma,
    required this.mb,
    required this.mc,
    required this.colorA,
    required this.colorB,
    required this.colorC,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale: Mean 0-120 maps to Width 0.1-0.9
    double x(double m) => w * (0.1 + (m / 140.0) * 0.8);

    // Draw Axis
    canvas.drawLine(Offset(0, h), Offset(w, h), Paint()..color = Colors.grey);

    // Draw Distributions
    _drawBell(canvas, x(ma), h, colorA);
    _drawBell(canvas, x(mb), h, colorB);
    _drawBell(canvas, x(mc), h, colorC);
  }

  void _drawBell(Canvas canvas, double cx, double h, Color c) {
    final paint = Paint()
      ..color = c.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final path = Path();
    double width = 40;
    double height = 100;
    path.moveTo(cx - width, h);
    path.quadraticBezierTo(cx, h - height * 2, cx + width, h);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, h - 5), 4, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _AnovaPainter old) =>
      old.ma != ma || old.mb != mb || old.mc != mc;
}

class _ChiSqPainter extends CustomPainter {
  final double cB, cP, cE;
  final double expChurn;
  final Color colorB, colorP, colorE;

  _ChiSqPainter({
    required this.cB,
    required this.cP,
    required this.cE,
    required this.expChurn,
    required this.colorB,
    required this.colorP,
    required this.colorE,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layout: 3 Group Bars. Each bar has "Churned" part colored, "Stayed" part grey.
    // Also draw a dashed line for Expected Churn Rate.

    final barW = w / 5;
    final maxH = h - 20; // reserve space for text

    void drawBar(double x, double churnCount, Color color, String label) {
      // Total is 100. Scale height to maxH.
      final churnH = (churnCount / 100.0) * maxH;

      // Draw Stay (Grey) - background full bar essentially
      canvas.drawRect(
        Rect.fromLTWH(x, 0, barW, maxH),
        Paint()..color = Colors.grey.withValues(alpha: 0.2),
      );

      // Draw Churn (Color)
      canvas.drawRect(
        Rect.fromLTWH(x, maxH - churnH, barW, churnH),
        Paint()..color = color,
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + (barW - tp.width) / 2, maxH + 4));

      // Value Label
      final tpV = TextPainter(
        text: TextSpan(
          text: '${churnCount.toInt()}%',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tpV.layout();
      if (churnH > 15) {
        tpV.paint(
          canvas,
          Offset(x + (barW - tpV.width) / 2, maxH - churnH + 2),
        );
      }
    }

    drawBar(w * 0.1, cB, colorB, "Basic");
    drawBar(w * 0.4, cP, colorP, "Pro");
    drawBar(w * 0.7, cE, colorE, "Enterp.");

    // Draw Expected Line
    final expH = maxH - ((expChurn / 100.0) * maxH);
    final paintLine = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dashW = 5;
    final dashSpace = 5;
    double startX = 0;
    while (startX < w) {
      canvas.drawLine(
        Offset(startX, expH),
        Offset(startX + dashW, expH),
        paintLine,
      );
      startX += dashW + dashSpace;
    }

    TextPainter(
        text: const TextSpan(
          text: "Expected Average",
          style: TextStyle(fontSize: 9, color: Colors.black54),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, Offset(w - 90, expH - 12));
  }

  @override
  bool shouldRepaint(covariant _ChiSqPainter old) =>
      old.cB != cB || old.cP != cP || old.cE != cE;
}
