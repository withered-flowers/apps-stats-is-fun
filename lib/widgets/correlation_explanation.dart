import 'package:flutter/material.dart';

class CorrelationExplanation extends StatefulWidget {
  const CorrelationExplanation({super.key});

  @override
  State<CorrelationExplanation> createState() => _CorrelationExplanationState();
}

class _CorrelationExplanationState extends State<CorrelationExplanation> {
  int _selectedMethodIndex = 0; // 0=Pearson, 1=Spearman, 2=Kendall

  final List<Map<String, dynamic>> _methods = [
    {
      'name': 'Pearson (r)',
      'desc': 'Measures linear relationship strength.',
      'formula': 'Cov(X,Y) / (σx * σy)',
      'useCase':
          'Use when data is Continuous, Normally Distributed, and Linear.',
      'icon': Icons.show_chart_rounded,
      'sampleX': '[1, 2, 3, 4, 5]',
      'sampleY': '[2, 4, 6, 8, 10]',
      'result': 'r = 1.0',
      'reason':
          'Perfect Linear Relationship. Y increases by exactly 2 for every 1 unit of X.',
      'plotType': 0, // 0=Linear
    },
    {
      'name': 'Spearman (ρ)',
      'desc': 'Measures monotonic relationship (rank-based).',
      'formula': 'Pearson correlation of ranks',
      'useCase': 'Use when data is Ordinal or Non-Linear/Skewed.',
      'icon': Icons.graphic_eq_rounded,
      'sampleX': '[1, 2, 3, 4, 100]',
      'sampleY': '[10, 100, 1000, 10000, 100000]',
      'result': 'ρ = 1.0 vs r = 0.5',
      'reason':
          'Monotonic but Non-Linear. Pearson fails due to the outlier (100) and curve. Spearman ranks them 1-5 perfectly.',
      'plotType': 1, // 1=Monotonic
    },
    {
      'name': 'Kendall (τ)',
      'desc': 'Measures ordinal association (concordant pairs).',
      'formula': '(Concordant - Discordant) / Total Pairs',
      'useCase': 'Best for small sample sizes or many tied ranks.',
      'icon': Icons.compare_arrows_rounded,
      'sampleX': '[A, B, C, D, E]',
      'sampleY': '[A, C, B, E, D]',
      'result': 'τ = 0.6',
      'reason':
          'Concordance. 2 pairs are discordant (C-B swapped, E-D swapped). Robust to small swaps.',
      'plotType': 2, // 2=Kendall
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final method = _methods[_selectedMethodIndex];

    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(Icons.hub_rounded, color: colorScheme.secondary),
        title: Text(
          'Correlation Analysis',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Pearson, Spearman, Kendall'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a technique to analyze:'),
                const SizedBox(height: 12),
                ToggleButtons(
                  isSelected: List.generate(
                    3,
                    (index) => index == _selectedMethodIndex,
                  ),
                  onPressed: (index) {
                    setState(() {
                      _selectedMethodIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    minWidth: 80,
                  ),
                  children: _methods
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(m['name']),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            method['desc'],
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(theme, 'Use Case:', method['useCase']),

                          const Divider(height: 24),

                          // Analysis Section
                          Text(
                            "Analysis Example:",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "X: ${method['sampleX']}",
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "Y: ${method['sampleY']}",
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Result: ${method['result']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method['reason'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 160,
                        child: CustomPaint(
                          painter: _CorrelationPainter(
                            mode: method['plotType'],
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall,
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _CorrelationPainter extends CustomPainter {
  final int mode;
  final Color color;

  _CorrelationPainter({required this.mode, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw Axis
    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h), Offset(w, h), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, h), axisPaint);

    // Draw visual metaphor
    switch (mode) {
      case 0: // Pearson - Linear
        // Perfect Line
        for (int i = 0; i < 5; i++) {
          double x = w * (0.2 + i * 0.15);
          double y = h * (0.8 - i * 0.15);
          canvas.drawCircle(Offset(x, y), 4, paint);
        }
        // Line
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(w * 0.2, h * 0.8),
          Offset(w * 0.8, h * 0.2),
          linePaint,
        );
        break;

      case 1: // Spearman - Monotonic Curve
        // Exponential Curve
        for (int i = 0; i < 6; i++) {
          double t = i / 5.0;
          double x = w * (0.1 + t * 0.8);
          double y = h * (0.9 - (t * t * t) * 0.8);
          canvas.drawCircle(Offset(x, y), 4, paint);
        }
        break;

      case 2: // Kendall - Swaps
        // A, B, C, D, E mapped to 1, 2, 3, 4, 5
        // Y = 1, 3, 2, 5, 4
        List<double> ys = [0.1, 0.5, 0.3, 0.9, 0.7]; // Normalized heights
        for (int i = 0; i < 5; i++) {
          double x = w * (0.2 + i * 0.15);
          double y = h * (1.0 - ys[i]); // flip y
          canvas.drawCircle(Offset(x, y), 4, paint);

          // Connect next
          if (i < 4) {
            final linkPaint = Paint()
              ..color = color.withValues(alpha: 0.3)
              ..strokeWidth = 1;
            double nextX = w * (0.2 + (i + 1) * 0.15);
            double nextY = h * (1.0 - ys[i + 1]);
            canvas.drawLine(Offset(x, y), Offset(nextX, nextY), linkPaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CorrelationPainter oldDelegate) =>
      oldDelegate.mode != mode;
}
