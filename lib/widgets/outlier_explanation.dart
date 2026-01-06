import 'package:flutter/material.dart';

class OutlierExplanation extends StatelessWidget {
  final List<double> data;
  final double? mean;
  final double? stdDev;
  final double? q1;
  final double? q3;
  final double? iqr;

  const OutlierExplanation({
    super.key,
    required this.data,
    required this.mean,
    required this.stdDev,
    required this.q1,
    required this.q3,
    required this.iqr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate Z-Score Outliers Live
    final zOutliers = <double>[];
    if (data.isNotEmpty && mean != null && stdDev != null && stdDev! > 0) {
      for (final x in data) {
        final z = (x - mean!) / stdDev!;
        if (z.abs() > 3) {
          zOutliers.add(x);
        }
      }
    }

    // Calculate Tukey Outliers Live
    final tukeyOutliers = <double>[];
    if (q1 != null && q3 != null && iqr != null) {
      final lower = q1! - 1.5 * iqr!;
      final upper = q3! + 1.5 * iqr!;
      for (final x in data) {
        if (x < lower || x > upper) {
          tukeyOutliers.add(x);
        }
      }
    }

    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(Icons.warning_amber_rounded, color: colorScheme.error),
        title: Text(
          'Outlier Detection Methods',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text("Z-Score vs Tukey's Fences (IQR)"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMethodSection(
                  context,
                  title: "1. Tukey's Fences (IQR Method)",
                  desc: "Uses quartiles. Robust to extreme values.",
                  formula: "Lower: Q1 - 1.5*IQR\nUpper: Q3 + 1.5*IQR",
                  useCase:
                      "✅ Best for Skewed Data or small datasets.\n✅ Robust (Median-based).\n✅ Used in Box Plots.",
                  outliers: tukeyOutliers,
                ),
                const Divider(height: 32),
                _buildMethodSection(
                  context,
                  title: "2. Z-Score Method",
                  desc: "Uses Standard Deviations from Mean.",
                  formula: "Z = (X - Mean) / StdDev\nThreshold: |Z| > 3",
                  useCase:
                      "✅ Best for Normal Distributions.\n❌ Sensitive (Mean affected by outliers).\n❌ Needs N > 12.",
                  outliers: zOutliers,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Which one to use?",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Use Tukey's (IQR) by default, especially for real-world data which is often skewed. "
                        "Only use Z-Score if you are certain the data should be Gaussian (Normal).",
                        style: theme.textTheme.bodySmall,
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

  Widget _buildMethodSection(
    BuildContext context, {
    required String title,
    required String desc,
    required String formula,
    required String useCase,
    required List<double> outliers,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            if (outliers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${outliers.length} detected",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(desc, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Formula:",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formula,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "When to use:",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(useCase, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        if (outliers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            "Found: ${outliers.map((e) => e.toStringAsFixed(2)).join(', ')}",
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
