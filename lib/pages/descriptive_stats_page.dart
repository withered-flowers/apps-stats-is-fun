import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'dart:math' as math;
import '../widgets/code_snippet.dart';
import '../widgets/box_plot.dart';
import '../widgets/distribution_chart.dart';
import '../widgets/data_types_explanation.dart';
import '../widgets/outlier_explanation.dart';
import '../widgets/correlation_explanation.dart';

/// Descriptive Statistics page with interactive calculators
class DescriptiveStatsPage extends StatefulWidget {
  const DescriptiveStatsPage({super.key});

  @override
  State<DescriptiveStatsPage> createState() => _DescriptiveStatsPageState();
}

class _DescriptiveStatsPageState extends State<DescriptiveStatsPage> {
  final TextEditingController _inputController = TextEditingController();

  // Signals for reactive state management
  late final Signal<List<double>> _dataPoints;
  late final Signal<String> _inputError;

  // Computed values using signals
  late final Computed<double?> _mean;
  late final Computed<double?> _median;
  late final Computed<List<double>> _mode;
  late final Computed<double?> _range;
  late final Computed<double?> _variance;
  late final Computed<double?> _stdDev;
  late final Computed<double?> _min;
  late final Computed<double?> _max;

  // Advanced statistics
  late final Computed<double?> _q1;
  late final Computed<double?> _q3;
  late final Computed<double?> _iqr;
  late final Computed<double?> _skewness;
  late final Computed<double?> _kurtosis;
  late final Computed<List<double>> _outliers;
  late final Computed<(double, double)?> _normalityTest; // (statistic, pValue)

  @override
  void initState() {
    super.initState();
    _dataPoints = signal<List<double>>([]);
    _inputError = signal<String>('');

    // Compute mean
    _mean = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      return data.reduce((a, b) => a + b) / data.length;
    });

    // Compute median
    _median = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      final sorted = List<double>.from(data)..sort();
      final mid = sorted.length ~/ 2;
      if (sorted.length.isOdd) {
        return sorted[mid];
      }
      return (sorted[mid - 1] + sorted[mid]) / 2;
    });

    // Compute mode
    _mode = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return <double>[];

      final frequency = <double, int>{};
      for (final value in data) {
        frequency[value] = (frequency[value] ?? 0) + 1;
      }

      final maxFreq = frequency.values.reduce((a, b) => a > b ? a : b);
      if (maxFreq == 1) return <double>[]; // No mode if all values appear once

      return frequency.entries
          .where((e) => e.value == maxFreq)
          .map((e) => e.key)
          .toList()
        ..sort();
    });

    // Compute range
    _range = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      final sorted = List<double>.from(data)..sort();
      return sorted.last - sorted.first;
    });

    // Compute min
    _min = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      return data.reduce((a, b) => a < b ? a : b);
    });

    // Compute max
    _max = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      return data.reduce((a, b) => a > b ? a : b);
    });

    // Compute variance
    _variance = computed(() {
      final data = _dataPoints.value;
      final mean = _mean.value;
      if (data.isEmpty || mean == null) return null;

      final sumSquaredDiff = data
          .map((x) => math.pow(x - mean, 2))
          .reduce((a, b) => a + b);
      return sumSquaredDiff / data.length;
    });

    // Compute standard deviation
    _stdDev = computed(() {
      final variance = _variance.value;
      if (variance == null) return null;
      return math.sqrt(variance);
    });

    // Compute Quartiles (Q1, Q3) and IQR
    _q1 = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      final sorted = List<double>.from(data)..sort();
      final n = sorted.length;
      final pos = (n + 1) / 4;
      final intPos = pos.toInt();
      final frac = pos - intPos;

      if (intPos <= 0) return sorted.first;
      if (intPos >= n) return sorted.last;

      // Interpolation
      return sorted[intPos - 1] + (sorted[intPos] - sorted[intPos - 1]) * frac;
    });

    _q3 = computed(() {
      final data = _dataPoints.value;
      if (data.isEmpty) return null;
      final sorted = List<double>.from(data)..sort();
      final n = sorted.length;
      final pos = 3 * (n + 1) / 4;
      final intPos = pos.toInt();
      final frac = pos - intPos;

      if (intPos <= 0) return sorted.first;
      if (intPos >= n) return sorted.last;

      return sorted[intPos - 1] + (sorted[intPos] - sorted[intPos - 1]) * frac;
    });

    _iqr = computed(() {
      final q1 = _q1.value;
      final q3 = _q3.value;
      if (q1 == null || q3 == null) return null;
      return q3 - q1;
    });

    // Compute Outliers (1.5 * IQR rule)
    _outliers = computed(() {
      final data = _dataPoints.value;
      final q1 = _q1.value;
      final q3 = _q3.value;
      final iqr = _iqr.value;

      if (data.isEmpty || q1 == null || q3 == null || iqr == null) return [];

      final lowerBound = q1 - 1.5 * iqr;
      final upperBound = q3 + 1.5 * iqr;

      return data.where((x) => x < lowerBound || x > upperBound).toList()
        ..sort();
    });

    // Compute Skewness (Fisher-Pearson coefficient of skewness)
    _skewness = computed(() {
      final data = _dataPoints.value;
      final n = data.length;
      final mean = _mean.value;
      final stdDev = _stdDev
          .value; // This is population std dev in current implementation?
      // Note: Currently _variance uses / N (population).
      // Standard skewness formula typically uses sample standard deviation or adjusts for bias.
      // We'll stick to the standard moment definition for consistency with Population variance currently used.
      // g1 = m3 / m2^(3/2)

      if (n < 3 || mean == null || stdDev == null || stdDev == 0) return null;

      double m3 = 0;
      for (var x in data) {
        m3 += math.pow(x - mean, 3);
      }
      m3 /= n;

      final m2 = math.pow(stdDev, 2);
      return m3 / math.pow(m2, 1.5);
    });

    // Compute Kurtosis (Excess Kurtosis)
    _kurtosis = computed(() {
      final data = _dataPoints.value;
      final n = data.length;
      final mean = _mean.value;
      final stdDev = _stdDev.value;

      if (n < 4 || mean == null || stdDev == null || stdDev == 0) return null;

      double m4 = 0;
      for (var x in data) {
        m4 += math.pow(x - mean, 4);
      }
      m4 /= n;

      final m2 = math.pow(stdDev, 2);
      return (m4 / (m2 * m2)) - 3; // Excess kurtosis
    });

    // Compute D'Agostino's K^2 Test
    _normalityTest = computed(() {
      final data = _dataPoints.value;
      final n = data.length;
      if (n < 8) return null; // Requires at least 8 samples for valid test

      final mean = data.reduce((a, b) => a + b) / n;

      double m2 = 0;
      double m3 = 0;
      double m4 = 0;

      for (var x in data) {
        final delta = x - mean;
        m2 += math.pow(delta, 2);
        m3 += math.pow(delta, 3);
        m4 += math.pow(delta, 4);
      }
      m2 /= n;
      m3 /= n;
      m4 /= n;

      final g1 = m3 / math.pow(m2, 1.5);
      final g2 = m4 / (m2 * m2);

      // Transformation for Skewness (Z1)
      // D’Agostino, R. B. (1970)
      final y = g1 * math.sqrt(((n + 1) * (n + 3)) / (6 * (n - 2)));
      final beta2 =
          (3 * (n * n + 27 * n - 70) * (n + 1) * (n + 3)) /
          ((n - 2) * (n + 5) * (n + 7) * (n + 9));
      final w2 = -1 + math.sqrt(2 * (beta2 - 1));
      final delta = 1 / math.sqrt(math.log(math.sqrt(w2)));
      final alpha = math.sqrt(2 / (w2 - 1));
      final z1 =
          delta * math.log(y / alpha + math.sqrt(math.pow(y / alpha, 2) + 1));

      // Transformation for Kurtosis (Z2)
      // Anscombe, F. J., & Glynn, W. J. (1983)
      final meanG2 = 3 * (n - 1) / (n + 1);
      final varG2 =
          24 * n * (n - 2) * (n - 3) / (math.pow(n + 1, 2) * (n + 3) * (n + 5));
      final x = (g2 - meanG2) / math.sqrt(varG2);
      final sqrtBeta1 =
          6 *
          (n * n - 5 * n + 2) /
          ((n + 7) * (n + 9)) *
          math.sqrt(6 * (n + 3) * (n + 5) / (n * (n - 2) * (n - 3)));
      final a =
          6 +
          8 /
              sqrtBeta1 *
              (2 / sqrtBeta1 + math.sqrt(1 + 4 / (sqrtBeta1 * sqrtBeta1)));
      final z2 =
          (1 -
              2 / (9 * a) -
              math.pow((1 - 2 / a) / (1 + x * math.sqrt(2 / (a - 4))), 1 / 3)) /
          math.sqrt(2 / (9 * a));

      final k2 = (z1 * z1) + (z2 * z2);
      final pVal = math.exp(-k2 / 2); // Approximation for ChiSq(2)

      return (k2, pVal);
    });
  }

  void _generateRandomData() {
    final rng = math.Random();
    // Box-Muller transform for Normal Distribution
    // Mean 50, Std Dev 15
    final List<double> newData = [];
    for (int i = 0; i < 50; i++) {
      final u1 = rng.nextDouble();
      final u2 = rng.nextDouble();
      // Avoid 0 to prevent log(0)
      final u1S = u1 == 0 ? 0.0000001 : u1;

      final z0 = math.sqrt(-2.0 * math.log(u1S)) * math.cos(2.0 * math.pi * u2);
      final z1 = math.sqrt(-2.0 * math.log(u1S)) * math.sin(2.0 * math.pi * u2);

      newData.add(50 + z0 * 15);
      newData.add(50 + z1 * 15);
    }
    _inputController.text = newData.map((e) => e.toStringAsFixed(2)).join(', ');
    _parseInput(_inputController.text);
  }

  void _generateChaosData() {
    final rng = math.Random();
    final newData = <double>[];

    // Randomize the distribution shape
    // Exponent > 1 => Right Skewed
    // 0 < Exponent < 1 => Left Skewed (if applied directly) or Broad
    // Let's mix it up to guarantee "Random Value" distribution.

    final exponent = 0.5 + rng.nextDouble() * 3.5; // 0.5 to 4.0
    final isRightSkew = rng.nextBool();

    for (int i = 0; i < 100; i++) {
      double val = math.pow(rng.nextDouble(), exponent).toDouble();
      if (!isRightSkew) val = 1.0 - val;

      // Add some random scaling/noise
      val = val * 100 + (rng.nextDouble() * 5);
      newData.add(val);
    }

    _inputController.text = newData.map((e) => e.toStringAsFixed(2)).join(', ');
    _parseInput(_inputController.text);
  }

  void _parseInput(String input) {
    if (input.trim().isEmpty) {
      _dataPoints.value = [];
      _inputError.value = '';
      return;
    }

    try {
      final parts = input.split(RegExp(r'[,\s]+'));
      final numbers = <double>[];

      for (final part in parts) {
        if (part.trim().isEmpty) continue;
        final num = double.tryParse(part.trim());
        if (num == null) {
          _inputError.value = 'Invalid number: "$part"';
          return;
        }
        numbers.add(num);
      }

      _dataPoints.value = numbers;
      _inputError.value = '';
    } catch (e) {
      _inputError.value = 'Error parsing input';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Descriptive Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primary.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numbers tell stories!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your data below to see statistics calculated in real-time.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Educational: Data Types (Top as requested)
            const DataTypesExplanation(),

            const SizedBox(height: 24),

            // Data input section
            Text(
              'Enter Your Data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText:
                    'Enter numbers separated by commas (e.g., 1, 2, 3, 4, 5)',
                prefixIcon: Icon(Icons.data_array_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: _parseInput,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _generateRandomData,
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Random (Normal)'),
                  ),
                  TextButton.icon(
                    onPressed: _generateChaosData,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Random (Chaos)'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            Watch((context) {
              final error = _inputError.value;
              if (error.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error, style: TextStyle(color: colorScheme.error)),
              );
            }),

            const SizedBox(height: 16),

            // Data chips display
            Watch((context) {
              final data = _dataPoints.value;
              if (data.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    'Your data will appear here...',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data
                    .map(
                      (n) => Chip(
                        label: Text(
                          n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2),
                        ),
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    )
                    .toList(),
              );
            }),

            const SizedBox(height: 32),

            // Statistics results
            Text(
              'Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            _buildStatsGrid(context),

            const SizedBox(height: 32),

            // Spreadness & Visuals
            _buildSpreadnessSection(context),

            const SizedBox(height: 32),

            // Normality & Distribution
            _buildNormalitySection(context),

            const SizedBox(height: 24),

            const CorrelationExplanation(),

            const SizedBox(height: 24),

            // Python code preview
            _buildCodePreview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Mean',
                description: 'The average of all values',
                valueSignal: _mean,
                icon: Icons.functions_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Median',
                description: 'The middle value',
                valueSignal: _median,
                icon: Icons.align_vertical_center_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Watch((context) {
                final modes = _mode.value;
                final displayText = modes.isEmpty
                    ? '-'
                    : modes.length == 1
                    ? modes.first.toStringAsFixed(
                        modes.first.truncateToDouble() == modes.first ? 0 : 2,
                      )
                    : modes
                          .map(
                            (m) => m.toStringAsFixed(
                              m.truncateToDouble() == m ? 0 : 2,
                            ),
                          )
                          .join(', ');

                return _StatCardCustom(
                  title: 'Mode',
                  description: 'Most frequent value(s)',
                  displayText: displayText,
                  icon: Icons.repeat_rounded,
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Range',
                description: 'Max - Min spread',
                valueSignal: _range,
                icon: Icons.swap_horiz_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Variance',
                description: 'Measure of spread',
                valueSignal: _variance,
                icon: Icons.scatter_plot_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Std Dev',
                description: 'Square root of variance',
                valueSignal: _stdDev,
                icon: Icons.show_chart_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Min',
                description: 'Smallest value',
                valueSignal: _min,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Max',
                description: 'Largest value',
                valueSignal: _max,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodePreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.code_rounded, color: colorScheme.primary),
        title: const Text('Python Code (scipy/numpy)'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Watch((context) {
              final data = _dataPoints.value;
              final dataStr = data.isEmpty
                  ? '[1, 2, 3, 4, 5]'
                  : '[${data.map((d) => d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2)).join(', ')}]';

              final code =
                  '''import numpy as np
from scipy import stats

data = $dataStr

mean = np.mean(data)
median = np.median(data)
mode = stats.mode(data, keepdims=True)
range_val = np.ptp(data)  # peak-to-peak
variance = np.var(data)
std_dev = np.std(data)

print(f"Mean: {mean}")
print(f"Median: {median}")
print(f"Mode: {mode.mode[0]}")
print(f"Range: {range_val}")
print(f"Variance: {variance}")
print(f"Std Dev: {std_dev}")

# Advanced
q1 = np.percentile(data, 25)
q3 = np.percentile(data, 75)
iqr = stats.iqr(data)
skew = stats.skew(data)
kurt = stats.kurtosis(data)

print(f"Q1: {q1}")
print(f"Q3: {q3}")
print(f"IQR: {iqr}")
print(f"Skewness: {skew}")
print(f"Kurtosis: {kurt}")

# Normality Test (D'Agostino's K^2)
stat, p = stats.normaltest(data)
print(f"K^2 Statistic: {stat}")
print(f"P-value: {p}")
if p > 0.05:
    print("Likely Normal")
else:
    print("Not Normal")

# Generate Random Normal Data (Example)
# data = np.random.normal(loc=50, scale=15, size=100)

# Generate Random Skewed Data (Chaos)
# a = 5.0 # shape parameter
# data = np.random.power(a, 100) * 100

# Correlation Analysis (Bivariate)
# x = [1, 2, 3, 4, 5]
# y = [2, 4, 5, 4, 5]
# r, p = stats.pearsonr(x, y)   # Linear
# rho, p = stats.spearmanr(x, y) # Rank-based
# tau, p = stats.kendalltau(x, y) # Concordance''';

              return CodeSnippet(code: code);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSpreadnessSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spreadness & Outliers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Quartiles Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Q1',
                description: '25th Percentile',
                valueSignal: _q1,
                icon: Icons.pie_chart_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Median (Q2)',
                description: '50th Percentile',
                valueSignal: _median,
                icon: Icons.pie_chart_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Q3',
                description: '75th Percentile',
                valueSignal: _q3,
                icon: Icons.pie_chart_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'IQR',
                description: 'Interquartile Range (Q3 - Q1)',
                valueSignal: _iqr,
                icon: Icons.space_bar_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Box Plot
        Watch((context) {
          final q1 = _q1.value;
          final q3 = _q3.value;
          final med = _median.value;
          final min = _min.value;
          final max = _max.value;
          final outliers = _outliers.value;

          if (q1 == null ||
              q3 == null ||
              med == null ||
              min == null ||
              max == null) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BoxPlotWidget(
                min: min,
                q1: q1,
                median: med,
                q3: q3,
                max: max,
                outliers: outliers,
              ),
              if (outliers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Outliers detected (IQR): ${outliers.join(', ')}',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              // Outlier Methods Comparison
              OutlierExplanation(
                data: _dataPoints.value,
                mean: _mean.value,
                stdDev: _stdDev.value,
                q1: q1,
                q3: q3,
                iqr: _iqr.value,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildNormalitySection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Normality & Distribution',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Watch((context) {
                final s = _skewness.value;
                String desc = 'Measure of Asymmetry';
                if (s != null) {
                  if (s > 1) {
                    desc = 'Highly Right Skewed (Tail >>)';
                  } else if (s > 0.5) {
                    desc = 'Moderately Right Skewed';
                  } else if (s > -0.5) {
                    desc = 'Approx. Symmetric';
                  } else if (s > -1) {
                    desc = 'Moderately Left Skewed';
                  } else {
                    desc = 'Highly Left Skewed (Tail <<)';
                  }
                }
                return _StatCard(
                  title: 'Skewness',
                  description: desc,
                  valueSignal: _skewness,
                  icon: Icons.waves_rounded,
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Watch((context) {
                final k = _kurtosis.value;
                String desc = 'Tail Heaviness (Excess)';
                if (k != null) {
                  if (k > 1) {
                    desc = 'Leptokurtic (Sharp Peak)';
                  } else if (k < -1) {
                    desc = 'Platykurtic (Flat Top)';
                  } else {
                    desc = 'Mesokurtic (Normal-like)';
                  }
                }
                return _StatCard(
                  title: 'Kurtosis',
                  description: desc,
                  valueSignal: _kurtosis,
                  icon: Icons.vertical_align_center_rounded,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Distribution Visualization
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribution Shape',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Histogram (Bars) vs Normal Curve (Line). Look for skewness (leaning) or kurtosis (peakedness).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Watch((context) {
                  final data = _dataPoints.value;
                  final mean = _mean.value;
                  final std = _stdDev.value;

                  if (data.isEmpty || mean == null || std == null) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: Text('Enter data...')),
                    );
                  }

                  return DistributionChart(
                    data: data,
                    mean: mean,
                    stdDev: std,
                    binCount: math.max(
                      5,
                      math.min(20, math.sqrt(data.length).ceil() * 2),
                    ), // Dynamic bin count
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Normality Tests Info Card
        Card(
          child: ExpansionTile(
            title: const Text('Normality Tests (Cheatsheet)'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live D'Agostino Test Result
                    Watch((context) {
                      final result = _normalityTest.value;
                      if (result == null) return const SizedBox.shrink();

                      final (stat, p) = result;
                      final isNormal = p > 0.05;
                      final color = isNormal ? Colors.green : Colors.orange;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isNormal
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_rounded,
                                  color: color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Live Result: D'Agostino's K² Test",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Statistic: ${stat.toStringAsFixed(3)}"),
                            Text("P-value: ${p.toStringAsFixed(4)}"),
                            const SizedBox(height: 4),
                            Text(
                              isNormal
                                  ? "Conclusion: Likely Normal (p > 0.05)"
                                  : "Conclusion: Not Normal (p <= 0.05)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Text(
                      '1. Shapiro-Wilk Test (n < 50)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const CodeSnippet(
                      code:
                          'stat, p = stats.shapiro(data)\n# if p > 0.05, data is Normal',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "2. D'Agostino's K^2 Test (n >= 8)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const CodeSnippet(
                      code:
                          'stat, p = stats.normaltest(data)\n# Checks skewness + kurtosis',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '3. Kolmogorov-Smirnov Test',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const CodeSnippet(
                      code:
                          "stat, p = stats.kstest(data, 'norm')\n# Compares against Normal CDF",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stat card widget for displaying computed values
class _StatCard extends StatelessWidget {
  final String title;
  final String description;
  final Computed<double?> valueSignal;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.description,
    required this.valueSignal,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Watch((context) {
              final value = valueSignal.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  value == null
                      ? '-'
                      : value.toStringAsFixed(
                          value.truncateToDouble() == value ? 0 : 4,
                        ),
                  key: ValueKey(value),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Custom stat card for displaying text values (like mode with multiple values)
class _StatCardCustom extends StatelessWidget {
  final String title;
  final String description;
  final String displayText;
  final IconData icon;

  const _StatCardCustom({
    required this.title,
    required this.description,
    required this.displayText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                displayText,
                key: ValueKey(displayText),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
