import 'package:flutter/material.dart';
import 'dart:math' as math;

class DistributionChart extends StatelessWidget {
  final List<double> data;
  final double mean;
  final double stdDev;
  final int binCount;

  const DistributionChart({
    super.key,
    required this.data,
    required this.mean,
    required this.stdDev,
    this.binCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || stdDev == 0) {
      return Center(
        child: Text(
          'Enter data to see distribution',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, 200),
          painter: _DistributionPainter(
            data: data,
            mean: mean,
            stdDev: stdDev,
            binCount: binCount,
            colors: Theme.of(context).colorScheme,
          ),
        );
      },
    );
  }
}

class _DistributionPainter extends CustomPainter {
  final List<double> data;
  final double mean;
  final double stdDev;
  final int binCount;
  final ColorScheme colors;

  _DistributionPainter({
    required this.data,
    required this.mean,
    required this.stdDev,
    required this.binCount,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final min = data.reduce(math.min);
    final max = data.reduce(math.max);
    // Add small padding to range
    final range = max - min;
    final chartMin = min - (range * 0.1);
    final chartMax = max + (range * 0.1);
    final chartRange = chartMax - chartMin;

    if (chartRange == 0) return;

    // 1. Calculate Histogram Bins
    final bins = List<int>.filled(binCount, 0);
    final binWidth = chartRange / binCount;

    for (var x in data) {
      final binIndex = ((x - chartMin) / binWidth).floor();
      if (binIndex >= 0 && binIndex < binCount) {
        bins[binIndex]++;
      }
    }

    final maxBinCount = bins.reduce(math.max);

    // We need to scale both histogram and PDF to fit the height.
    // PDF max value is 1 / (stdDev * sqrt(2*pi))
    // To overlay them nicely, we usually scale the PDF to match the histogram's max height roughly,
    // or normalize the histogram to area=1 (density).
    // Let's normalize everything to fit the drawable area height.

    // Max PDF y value
    final pdfMaxY = 1 / (stdDev * math.sqrt(2 * math.pi));

    // 2. Draw Histogram
    final barPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final barOutlinePaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Scale factor for generic Y axis (0 to 1 mapping)
    // We map 0..maxBinCount to 0..size.height * 0.8

    final bottomY = size.height;

    for (int i = 0; i < binCount; i++) {
      final count = bins[i];
      final binLeft = i * (size.width / binCount);
      final binRight = (i + 1) * (size.width / binCount);

      final barHeightRatio =
          count / maxBinCount; // 0.0 to 1.0 relative to max bin
      final barHeight =
          barHeightRatio * (size.height * 0.85); // occupy 85% height max

      final rect = Rect.fromLTRB(
        binLeft,
        bottomY - barHeight,
        binRight,
        bottomY,
      );

      canvas.drawRect(rect, barPaint);
      canvas.drawRect(rect, barOutlinePaint);
    }

    // 3. Draw Normal Distribution Curve (PDF)
    // We simply overlay the curve centered at 'mean' with 'stdDev' width.
    // The curve Y scaling is arbitrary since histogram is count-based.
    // We scale the curve peak to matching height of the histogram peak * (pdfPeak / simulatedPdfOfBinMode)
    // Actually, simplest visual: Scale curve peak to match histogram peak (or slightly higher)
    // so users can compare shape relative to the peak.

    final curvePaint = Paint()
      ..color = colors.tertiary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Plot PDF points
    // x pixels maps to value: chartMin + (x / width) * chartRange
    for (double px = 0; px <= size.width; px += 2) {
      final xVal = chartMin + (px / size.width) * chartRange;

      // Gaussian function
      final z = (xVal - mean) / stdDev;
      final pdf =
          (1 / (stdDev * math.sqrt(2 * math.pi))) * math.exp(-0.5 * z * z);

      // Scale Y:
      // We equate the Peak of PDF (pdfMaxY) to the Peak of Histogram (size.height * 0.85)
      // This forces the "Normal" shape to align with the dominant data mode for skew comparison.
      final yRatio = pdf / pdfMaxY;
      final yPx = bottomY - (yRatio * (size.height * 0.85));

      if (px == 0) {
        path.moveTo(px, yPx);
      } else {
        path.lineTo(px, yPx);
      }
    }

    canvas.drawPath(path, curvePaint);

    // Draw Mean Line
    final meanPx = ((mean - chartMin) / chartRange) * size.width;
    final meanPaint = Paint()
      ..color = colors.tertiary.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (meanPx >= 0 && meanPx <= size.width) {
      canvas.drawLine(Offset(meanPx, bottomY), Offset(meanPx, 0), meanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
