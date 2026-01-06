import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'dart:math' as math;
import '../widgets/code_snippet.dart';
import '../widgets/additional_tests_explanation.dart';

enum TestType { tTest, zTest }

enum TestTail { twoSided, leftSided, rightSided }

/// Inferential Statistics page with interactive learning elements
class InferentialStatsPage extends StatefulWidget {
  const InferentialStatsPage({super.key});

  @override
  State<InferentialStatsPage> createState() => _InferentialStatsPageState();
}

class _InferentialStatsPageState extends State<InferentialStatsPage> {
  // Confidence Interval signals
  late final Signal<double> _sampleMean;
  late final Signal<double> _sampleStdDev;
  late final Signal<int> _sampleSize;
  late final Signal<double> _confidenceLevel;

  // Computed confidence interval
  late final Computed<({double lower, double upper, double marginOfError})?>
  _confidenceInterval;

  // Sample size calculator signals
  late final Signal<double> _desiredMarginOfError;
  late final Signal<double> _populationStdDev;
  late final Signal<double> _desiredConfidence;
  late final Computed<int?> _requiredSampleSize;

  // Hypothesis testing signals
  late final Signal<TestType> _testType;
  late final Signal<TestTail> _testTail;
  late final Signal<double> _hypothesisMean;
  late final Signal<double> _testSampleMean;
  late final Signal<double> _testStdDev; // Used for T-test (s)
  late final Signal<double> _testPopulationStdDev; // Used for Z-test (sigma)
  late final Signal<int> _testSampleSize;
  late final Computed<
    ({double statistic, double pValue, String conclusion, String formula})?
  >
  _hypothesisResult;

  @override
  void initState() {
    super.initState();

    // Initialize confidence interval signals
    _sampleMean = signal(50.0);
    _sampleStdDev = signal(10.0);
    _sampleSize = signal(30);
    _confidenceLevel = signal(0.95);

    // Z-scores for common confidence levels
    double getZScore(double confidence) {
      if (confidence >= 0.99) return 2.576;
      if (confidence >= 0.95) return 1.96;
      if (confidence >= 0.90) return 1.645;
      return 1.28;
    }

    _confidenceInterval = computed(() {
      final mean = _sampleMean.value;
      final stdDev = _sampleStdDev.value;
      final n = _sampleSize.value;
      final confidence = _confidenceLevel.value;

      if (n <= 0 || stdDev < 0) return null;

      final z = getZScore(confidence);
      final standardError = stdDev / math.sqrt(n);
      final marginOfError = z * standardError;

      return (
        lower: mean - marginOfError,
        upper: mean + marginOfError,
        marginOfError: marginOfError,
      );
    });

    // Sample size calculator
    _desiredMarginOfError = signal(5.0);
    _populationStdDev = signal(15.0);
    _desiredConfidence = signal(0.95);

    _requiredSampleSize = computed(() {
      final e = _desiredMarginOfError.value;
      final sigma = _populationStdDev.value;
      final confidence = _desiredConfidence.value;

      if (e <= 0 || sigma <= 0) return null;

      final z = getZScore(confidence);
      final n = math.pow((z * sigma) / e, 2);

      return n.ceil();
    });

    // Hypothesis testing
    _testType = signal(TestType.tTest);
    _testTail = signal(TestTail.twoSided);
    _hypothesisMean = signal(100.0);
    _testSampleMean = signal(105.0);
    _testStdDev = signal(15.0);
    _testPopulationStdDev = signal(15.0);
    _testSampleSize = signal(30);

    _hypothesisResult = computed(() {
      final type = _testType.value;
      final tail = _testTail.value;
      final mu0 = _hypothesisMean.value;
      final xBar = _testSampleMean.value;
      final s = _testStdDev.value;
      final sigma = _testPopulationStdDev.value;
      final n = _testSampleSize.value;

      if (n <= 1) return null;
      if (type == TestType.tTest && s <= 0) return null;
      if (type == TestType.zTest && sigma <= 0) return null;

      double statistic;
      double standardError;
      String formulaStr;

      if (type == TestType.tTest) {
        standardError = s / math.sqrt(n);
        statistic = (xBar - mu0) / standardError;
        formulaStr = 't = (x̄ - μ₀) / (s / √n)';
      } else {
        standardError = sigma / math.sqrt(n);
        statistic = (xBar - mu0) / standardError;
        formulaStr = 'z = (x̄ - μ₀) / (σ / √n)';
      }

      // Approximate p-value (Normal distribution approximation for simplicity)
      // Note: For educational purposes, using Normal approx for T-test is acceptable
      // for large N, but for small N it's less accurate.
      // We'll use a standard Normal CDF approximation.
      double normalCdf(double x) {
        // Constants
        const a1 = 0.254829592;
        const a2 = -0.284496736;
        const a3 = 1.421413741;
        const a4 = -1.453152027;
        const a5 = 1.061405429;
        const p = 0.3275911;

        // Save the sign of x
        int sign = 1;
        if (x < 0) {
          sign = -1;
        }
        x = x.abs() / math.sqrt(2.0);

        // A&S formula 7.1.26
        double t = 1.0 / (1.0 + p * x);
        double y =
            1.0 -
            (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
                t *
                math.exp(-x * x);

        return 0.5 * (1.0 + sign * y);
      }

      double pValue;
      if (tail == TestTail.twoSided) {
        pValue = 2 * (1 - normalCdf(statistic.abs()));
      } else if (tail == TestTail.leftSided) {
        pValue = normalCdf(statistic);
      } else {
        // rightSided
        pValue = 1 - normalCdf(statistic);
      }

      // Clamp p-value
      if (pValue < 0) pValue = 0;
      if (pValue > 1) pValue = 1;

      final conclusion = pValue < 0.05
          ? 'Reject H0: Significant evidence against the null hypothesis'
          : 'Fail to reject H0: Not enough evidence against the null hypothesis';

      return (
        statistic: statistic,
        pValue: pValue,
        conclusion: conclusion,
        formula: formulaStr,
      );
    });
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
        title: const Text('Inferential Statistics'),
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
                    colorScheme.secondaryContainer,
                    colorScheme.secondary.withValues(alpha: 0.2),
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
                    'Predict the future... with math!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use sample data to make predictions about entire populations.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // What is Inferential Statistics?
            _buildInfoCard(
              context,
              title: 'What is Inferential Statistics?',
              content:
                  'Inferential statistics helps us make predictions and draw conclusions about a population based on a sample. Instead of studying everyone, we study a smaller group and use math to estimate what the whole population might look like.',
              icon: Icons.psychology_rounded,
            ),

            const SizedBox(height: 24),

            // Confidence Interval Section
            Text(
              'Confidence Interval Calculator',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimate a range where the true population value likely falls.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildConfidenceIntervalSection(context),

            const SizedBox(height: 32),

            // Sample Size Calculator Section
            Text(
              'Sample Size Calculator',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find out how many observations you need for reliable results.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildSampleSizeSection(context),

            const SizedBox(height: 32),

            // T-Test vs Z-Test Section
            Text(
              'T-Test vs. Z-Test',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Which one should you use?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildTvsZCard(context),

            const SizedBox(height: 32),

            // Hypothesis Testing Section
            Text(
              'Hypothesis Testing',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test if a claim about a population is likely to be true.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildHypothesisTestingSection(context),

            const SizedBox(height: 32),

            // Advanced Tests (ANOVA, ChiSq)
            const AdditionalTestsExplanation(),

            const SizedBox(height: 32),

            // Python code preview
            _buildCodePreview(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHypothesisTestingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Type Selector
            Text('Test Type:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch((context) {
              return SizedBox(
                width: double.infinity,
                child: SegmentedButton<TestType>(
                  segments: const [
                    ButtonSegment(
                      value: TestType.tTest,
                      label: Text('T-Test'),
                      icon: Icon(Icons.show_chart_rounded),
                    ),
                    ButtonSegment(
                      value: TestType.zTest,
                      label: Text('Z-Test'),
                      icon: Icon(Icons.bar_chart_rounded),
                    ),
                  ],
                  selected: {_testType.value},
                  onSelectionChanged: (v) => _testType.value = v.first,
                ),
              );
            }),

            const SizedBox(height: 16),

            // Tail Selector
            Text('Test Tail:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch((context) {
              return SizedBox(
                width: double.infinity,
                child: SegmentedButton<TestTail>(
                  segments: const [
                    ButtonSegment(
                      value: TestTail.twoSided,
                      label: Text('Two-Sided (≠)'),
                    ),
                    ButtonSegment(
                      value: TestTail.leftSided,
                      label: Text('Left (<)'),
                    ),
                    ButtonSegment(
                      value: TestTail.rightSided,
                      label: Text('Right (>)'),
                    ),
                  ],
                  selected: {_testTail.value},
                  onSelectionChanged: (v) => _testTail.value = v.first,
                ),
              );
            }),

            const SizedBox(height: 16),

            // Dynamic Use Case
            Watch((context) {
              final type = _testType.value;
              final tail = _testTail.value;
              String text;
              if (type == TestType.tTest) {
                if (tail == TestTail.twoSided) {
                  text =
                      'Example: Is the average height of students DIFFERENT from 170cm? (σ unknown)';
                } else if (tail == TestTail.leftSided) {
                  text =
                      'Example: Do students sleep LESS than 8 hours? (σ unknown)';
                } else {
                  text =
                      'Example: Do new batteries last LONGER than average? (σ unknown)';
                }
              } else {
                if (tail == TestTail.twoSided) {
                  text =
                      'Example: Is the machine filling bags INCORRECTLY (too full or empty)? (σ known)';
                } else if (tail == TestTail.leftSided) {
                  text =
                      'Example: Is the defect rate LOWER than target? (σ known)';
                } else {
                  text =
                      'Example: Is the yield HIGHER than benchmark? (σ known)';
                }
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: colorScheme.primary, width: 4),
                  ),
                ),
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Null hypothesis input
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Null Hypothesis (H0)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message:
                      'The "default" assumption (e.g., "Nothing has changed" or "No difference").\nWe assume this is true unless data proves otherwise.',
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('Population mean =', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _hypothesisMean.value,
                min: 0,
                max: 200,
                onChanged: (v) => _hypothesisMean.value = v,
                label: 'μ₀ = ${_hypothesisMean.value.toStringAsFixed(1)}',
              ),
            ),

            const SizedBox(height: 16),

            // Sample mean input
            Text('Sample Mean:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _testSampleMean.value,
                min: 0,
                max: 200,
                onChanged: (v) => _testSampleMean.value = v,
                label: 'x̄ = ${_testSampleMean.value.toStringAsFixed(1)}',
              ),
            ),

            const SizedBox(height: 16),

            // Conditionally show Std Dev slider
            Watch((context) {
              final isZTest = _testType.value == TestType.zTest;
              if (isZTest) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Population Std Dev (Known):',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    _buildNumberSlider(
                      value: _testPopulationStdDev.value,
                      min: 1,
                      max: 50,
                      onChanged: (v) => _testPopulationStdDev.value = v,
                      label:
                          'σ = ${_testPopulationStdDev.value.toStringAsFixed(1)}',
                      compact: true,
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Std Dev (Calculated from sample):',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    _buildNumberSlider(
                      value: _testStdDev.value,
                      min: 1,
                      max: 50,
                      onChanged: (v) => _testStdDev.value = v,
                      label: 's = ${_testStdDev.value.toStringAsFixed(1)}',
                      compact: true,
                    ),
                  ],
                );
              }
            }),

            const SizedBox(height: 16),

            // Sample Size
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sample Size:', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Watch(
                  (context) => _buildNumberSlider(
                    value: _testSampleSize.value.toDouble(),
                    min: 2,
                    max: 200,
                    onChanged: (v) => _testSampleSize.value = v.round(),
                    label: 'n = ${_testSampleSize.value}',
                    compact: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Results
            Watch((context) {
              final result = _hypothesisResult.value;
              final isZTest = _testType.value == TestType.zTest;

              if (result == null) {
                return const Text('Enter valid values to see results');
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: result.pValue < 0.05
                      ? colorScheme.errorContainer.withValues(alpha: 0.3)
                      : colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZTest ? 'Z-Test Results' : 'T-Test Results',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.formula,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultItem(
                            label: isZTest ? 'z-statistic' : 't-statistic',
                            value: result.statistic.toStringAsFixed(3),
                          ),
                        ),
                        Expanded(
                          child: _ResultItem(
                            label: 'p-value',
                            value: result.pValue < 0.001
                                ? '< 0.001'
                                : result.pValue.toStringAsFixed(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.conclusion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIntervalSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sample mean input
            Text('Sample Mean:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _sampleMean.value,
                min: 0,
                max: 100,
                onChanged: (v) => _sampleMean.value = v,
                label: 'x̄ = ${_sampleMean.value.toStringAsFixed(1)}',
              ),
            ),

            const SizedBox(height: 16),

            // Sample std dev
            Text(
              'Sample Standard Deviation:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _sampleStdDev.value,
                min: 1,
                max: 30,
                onChanged: (v) => _sampleStdDev.value = v,
                label: 's = ${_sampleStdDev.value.toStringAsFixed(1)}',
              ),
            ),

            const SizedBox(height: 16),

            // Sample size
            Text('Sample Size:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _sampleSize.value.toDouble(),
                min: 2,
                max: 200,
                onChanged: (v) => _sampleSize.value = v.round(),
                label: 'n = ${_sampleSize.value}',
              ),
            ),

            const SizedBox(height: 16),

            // Confidence level
            Text('Confidence Level:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch((context) {
              return SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0.90, label: Text('90%')),
                  ButtonSegment(value: 0.95, label: Text('95%')),
                  ButtonSegment(value: 0.99, label: Text('99%')),
                ],
                selected: {_confidenceLevel.value},
                onSelectionChanged: (v) => _confidenceLevel.value = v.first,
              );
            }),

            const SizedBox(height: 20),

            // Result
            Watch((context) {
              final ci = _confidenceInterval.value;
              if (ci == null) {
                return const Text('Enter valid values to see results');
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Confidence Interval',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '[${ci.lower.toStringAsFixed(2)}, ${ci.upper.toStringAsFixed(2)}]',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Margin of Error: ±${ci.marginOfError.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleSizeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desired margin of error
            Text('Desired Margin of Error:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _desiredMarginOfError.value,
                min: 1,
                max: 20,
                onChanged: (v) => _desiredMarginOfError.value = v,
                label: 'E = ${_desiredMarginOfError.value.toStringAsFixed(1)}',
              ),
            ),

            const SizedBox(height: 16),

            // Population std dev
            Text(
              'Estimated Population Std Dev:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Watch(
              (context) => _buildNumberSlider(
                value: _populationStdDev.value,
                min: 1,
                max: 50,
                onChanged: (v) => _populationStdDev.value = v,
                label: 'σ = ${_populationStdDev.value.toStringAsFixed(1)}',
              ),
            ),

            const SizedBox(height: 16),

            // Confidence level
            Text('Confidence Level:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Watch((context) {
              return SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 0.90, label: Text('90%')),
                  ButtonSegment(value: 0.95, label: Text('95%')),
                  ButtonSegment(value: 0.99, label: Text('99%')),
                ],
                selected: {_desiredConfidence.value},
                onSelectionChanged: (v) => _desiredConfidence.value = v.first,
              );
            }),

            const SizedBox(height: 20),

            // Result
            Watch((context) {
              final n = _requiredSampleSize.value;
              if (n == null) {
                return const Text('Enter valid values to see results');
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Required Sample Size',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'n = $n',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You need at least $n observations',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberSlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String label,
    bool compact = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(
          height: compact ? 30 : 40,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
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
        title: const Text('Python Code Reference'),
        children: [
          DefaultTabController(
            length: 2,
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  TabBar(
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Live Preview'),
                      Tab(text: 'Cheat Sheet'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildLiveCodeInternal(context),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCodeRefSection(
                                context,
                                '1. One-Sample Mean T-Test (Two-Sided)',
                                '''stats.ttest_1samp(data, popmean, alternative='two-sided')''',
                              ),
                              _buildCodeRefSection(
                                context,
                                '2. One-Sample Mean T-Test (One-Sided)',
                                '''# Check if mean > popmean (Right Tailed)
stats.ttest_1samp(data, popmean, alternative='greater')

# Check if mean < popmean (Left Tailed)
stats.ttest_1samp(data, popmean, alternative='less')''',
                              ),
                              _buildCodeRefSection(
                                context,
                                '3. One-Sample Mean Z-Test (Two-Sided)',
                                '''z_stat = (x_bar - mu_0) / (sigma / np.sqrt(n))
p_val = 2 * stats.norm.sf(abs(z_stat)) # 2 * (1 - cdf)''',
                              ),
                              _buildCodeRefSection(
                                context,
                                '4. One-Sample Mean Z-Test (One-Sided)',
                                '''# Check if mean > mu_0 (Right Tailed)
p_val = stats.norm.sf(z_stat)

# Check if mean < mu_0 (Left Tailed)
p_val = stats.norm.cdf(z_stat)''',
                              ),
                              _buildCodeRefSection(
                                context,
                                '5. One-Way ANOVA (Compare 3+ Means)',
                                '''f_stat, p_val = stats.f_oneway(group1, group2, group3)\n# Null Hypothesis: All means are equal''',
                              ),
                              _buildCodeRefSection(
                                context,
                                '6. Chi-Squared Test (Independence)',
                                '''chi2, p_val = stats.chisquare(f_obs=[50, 30], f_exp=[40, 40])\n# Null Hypothesis: Observed matches Expected''',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRefSection(BuildContext context, String title, String code) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CodeSnippet(code: code),
        ],
      ),
    );
  }

  Widget _buildLiveCodeInternal(BuildContext context) {
    return Watch((context) {
      final type = _testType.value;
      final tail = _testTail.value;

      String alternative;
      if (tail == TestTail.twoSided) {
        alternative = 'two-sided';
      } else if (tail == TestTail.leftSided) {
        alternative = 'less';
      } else {
        alternative = 'greater';
      }

      String code;
      if (type == TestType.tTest) {
        code =
            '''import numpy as np
from scipy import stats

# Sample data parameters
sample_mean = ${_testSampleMean.value}
sample_std = ${_testStdDev.value}
sample_size = ${_testSampleSize.value}
pop_mean = ${_hypothesisMean.value}

# Generate dummy data matching stats for demo
data = np.random.normal(sample_mean, sample_std, sample_size)

# One-Sample T-Test
# alternative: 'two-sided', 'less', or 'greater'
t_stat, p_val = stats.ttest_1samp(data, pop_mean, alternative='$alternative')

print(f"T-statistic: {t_stat:.3f}")
print(f"P-value: {p_val:.3f}")''';
      } else {
        code =
            '''import numpy as np
from scipy import stats

# Z-Test Parameters
x_bar = ${_testSampleMean.value}
sigma = ${_testPopulationStdDev.value}  # Known population std dev
n = ${_testSampleSize.value}
mu_0 = ${_hypothesisMean.value}

# Calculate Z-statistic
std_error = sigma / np.sqrt(n)
z_stat = (x_bar - mu_0) / std_error

# Calculate P-value based on tail
# Survival function (sf) is 1 - cdf
if '$alternative' == 'two-sided':
    p_val = 2 * stats.norm.sf(abs(z_stat))
elif '$alternative' == 'less':
    p_val = stats.norm.cdf(z_stat)
else: # greater
    p_val = stats.norm.sf(z_stat)

print(f"Z-statistic: {z_stat:.3f}")
print(f"P-value: {p_val:.3f}")''';
      }

      return CodeSnippet(code: code);
    });
  }

  Widget _buildTvsZCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.compare_arrows_rounded,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The Main Difference: Do you know Std Dev (σ)?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'T-Test',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint(
                        context,
                        'Population Std Dev (σ) is UNKNOWN',
                      ),
                      _buildBulletPoint(context, 'Uses Sample Std Dev (s)'),
                      _buildBulletPoint(
                        context,
                        'Common for small samples (n < 30)',
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 120,
                  color: colorScheme.outlineVariant,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Z-Test',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint(
                        context,
                        'Population Std Dev (σ) is KNOWN',
                      ),
                      _buildBulletPoint(context, 'Uses Population Std Dev (σ)'),
                      _buildBulletPoint(
                        context,
                        'Common for large samples (n > 30)',
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

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResultItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
