import 'package:flutter/material.dart';
import 'dart:math' as math;

class BoxPlotWidget extends StatelessWidget {
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;
  final String label;

  const BoxPlotWidget({
    super.key,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    this.outliers = const [],
    this.label = 'Data Distribution',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100, // Fixed height for the plot area
              width: double.infinity,
              child: CustomPaint(
                painter: _BoxPlotPainter(
                  min: min,
                  q1: q1,
                  median: median,
                  q3: q3,
                  max: max,
                  outliers: outliers,
                  colorScheme: colorScheme,
                ),
              ),
            ),
            // Legend / Key values
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.secondary,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _legendItem('Min: ${min.toStringAsFixed(1)}', style),
        _legendItem('Q1: ${q1.toStringAsFixed(1)}', style),
        _legendItem('Med: ${median.toStringAsFixed(1)}', style),
        _legendItem('Q3: ${q3.toStringAsFixed(1)}', style),
        _legendItem('Max: ${max.toStringAsFixed(1)}', style),
      ],
    );
  }

  Widget _legendItem(String text, TextStyle? style) {
    return Text(text, style: style);
  }
}

class _BoxPlotPainter extends CustomPainter {
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;
  final ColorScheme colorScheme;

  _BoxPlotPainter({
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.outliers,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final boxHeight = 40.0;

    // Determine drawing range
    // We need to include outliers in the range calculation to fit everything
    double globalMin = min;
    double globalMax = max;
    if (outliers.isNotEmpty) {
      globalMin = math.min(globalMin, outliers.first);
      globalMax = math.max(globalMax, outliers.last);
    }

    final range = globalMax - globalMin;
    if (range == 0) return; // Prevent division by zero if all values are same

    double normalize(double value) {
      return ((value - globalMin) / range) * size.width;
    }

    final xMin = normalize(min);
    final xQ1 = normalize(q1);
    final xMedian = normalize(median);
    final xQ3 = normalize(q3);
    final xMax = normalize(max);

    // Draw Whiskers (lines from box to min/max)
    // Left whisker: Min to Q1
    canvas.drawLine(Offset(xMin, centerY), Offset(xQ1, centerY), paint);
    // Right whisker: Q3 to Max
    canvas.drawLine(Offset(xQ3, centerY), Offset(xMax, centerY), paint);

    // Draw Whisker ends (caps)
    final capHeight = 10.0;
    canvas.drawLine(
      Offset(xMin, centerY - capHeight / 2),
      Offset(xMin, centerY + capHeight / 2),
      paint,
    );
    canvas.drawLine(
      Offset(xMax, centerY - capHeight / 2),
      Offset(xMax, centerY + capHeight / 2),
      paint,
    );

    // Draw Box (Q1 to Q3)
    final boxRect = Rect.fromCenter(
      center: Offset((xQ1 + xQ3) / 2, centerY),
      width: xQ3 - xQ1,
      height: boxHeight,
    );
    canvas.drawRect(boxRect, fillPaint);
    canvas.drawRect(boxRect, paint);

    // Draw Median Line
    canvas.drawLine(
      Offset(xMedian, centerY - boxHeight / 2),
      Offset(xMedian, centerY + boxHeight / 2),
      paint..strokeWidth = 3,
    );

    // Draw Outliers
    final outlierPaint = Paint()
      ..color = colorScheme.error
      ..style = PaintingStyle.fill;

    for (var outlier in outliers) {
      final xOut = normalize(outlier);
      canvas.drawCircle(Offset(xOut, centerY), 3, outlierPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
