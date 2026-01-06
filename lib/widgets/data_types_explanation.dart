import 'package:flutter/material.dart';
import 'dart:math' as math;

enum DiscreteType { bernoulli, uniform, poisson }

enum ContinuousType { normal, tStudent, exponential, chiSquared }

class DataTypesExplanation extends StatefulWidget {
  const DataTypesExplanation({super.key});

  @override
  State<DataTypesExplanation> createState() => _DataTypesExplanationState();
}

class _DataTypesExplanationState extends State<DataTypesExplanation> {
  DiscreteType _selectedDiscrete = DiscreteType.bernoulli;
  ContinuousType _selectedContinuous = ContinuousType.normal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.category_rounded, color: colorScheme.primary),
        title: Text(
          'Data Types: Discrete vs Continuous',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Touch the chips to see distribution examples'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDiscreteSection(theme, colorScheme),
                const Divider(height: 32),
                _buildContinuousSection(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscreteSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discrete Data',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Countable values with gaps. Select an example:',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: DiscreteType.values.map((type) {
                  return ChoiceChip(
                    label: Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _selectedDiscrete == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDiscrete = type);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _getDiscreteDescription(_selectedDiscrete),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _DiscretePainter(
                type: _selectedDiscrete,
                color: colorScheme.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinuousSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Continuous Data',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Measurable values on a continuum. Select an example:',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ContinuousType.values.map((type) {
                  String label = type.name;
                  if (type == ContinuousType.tStudent) {
                    label = 'T-Student';
                  } else if (type == ContinuousType.chiSquared) {
                    label = 'Chi-Square';
                  } else {
                    label = label[0].toUpperCase() + label.substring(1);
                  }

                  return ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    selected: _selectedContinuous == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedContinuous = type);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _getContinuousDescription(_selectedContinuous),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _ContinuousPainter(
                type: _selectedContinuous,
                color: colorScheme.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDiscreteDescription(DiscreteType type) {
    switch (type) {
      case DiscreteType.bernoulli:
        return 'Bernoulli: Success (1) vs Failure (0). Like a coin flip.';
      case DiscreteType.uniform:
        return 'Uniform: All outcomes equally likely. Like a die roll.';
      case DiscreteType.poisson:
        return 'Poisson: Number of events in fixed time. lambda=4.';
    }
  }

  String _getContinuousDescription(ContinuousType type) {
    switch (type) {
      case ContinuousType.normal:
        return 'Normal: The Bell Curve. Symmetric, prevalent in nature.';
      case ContinuousType.tStudent:
        return 'T-Student: Similar to Normal but with heavier tails (df=2).';
      case ContinuousType.exponential:
        return 'Exponential: Time between events. Rapid decay.';
      case ContinuousType.chiSquared:
        return 'Chi-Squared: Sum of squared normals. Skewed right (k=3).';
    }
  }
}

class _DiscretePainter extends CustomPainter {
  final DiscreteType type;
  final Color color;

  _DiscretePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    final bottomY = size.height;
    final w = size.width;
    final h = size.height * 0.8;

    switch (type) {
      case DiscreteType.bernoulli:
        _drawBar(canvas, paint, 0.2 * w, bottomY, h * 0.4, "0");
        _drawBar(canvas, paint, 0.7 * w, bottomY, h * 0.6, "1");
        break;

      case DiscreteType.uniform:
        for (int i = 0; i < 6; i++) {
          double x = (i + 0.5) * (w / 6);
          _drawBarCenter(canvas, paint, x, bottomY, h * 0.6, 15, "${i + 1}");
        }
        break;

      case DiscreteType.poisson:
        for (int k = 0; k <= 10; k++) {
          double prob = (math.pow(4, k) * math.exp(-4)) / _factorial(k);
          double barH = (prob / 0.2) * h;
          double x = (k + 0.5) * (w / 11);
          _drawBarCenter(canvas, paint, x, bottomY, barH, 8, "");
        }
        break;
    }
  }

  void _drawBar(
    Canvas canvas,
    Paint paint,
    double x,
    double bottomY,
    double height,
    String label,
  ) {
    canvas.drawRect(Rect.fromLTWH(x, bottomY - height, 20, height), paint);
  }

  void _drawBarCenter(
    Canvas canvas,
    Paint paint,
    double cx,
    double bottomY,
    double height,
    double width,
    String label,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(cx - width / 2, bottomY - height, width, height),
      paint,
    );
    canvas.drawCircle(Offset(cx, bottomY - height), 2, paint);
  }

  int _factorial(int n) {
    if (n <= 1) {
      return 1;
    }
    return n * _factorial(n - 1);
  }

  @override
  bool shouldRepaint(covariant _DiscretePainter oldDelegate) =>
      oldDelegate.type != type;
}

class _ContinuousPainter extends CustomPainter {
  final ContinuousType type;
  final Color color;

  _ContinuousPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    final path = Path();
    final w = size.width;
    final h = size.height * 0.9;

    double minX = -4, maxX = 4, maxY = 0.5;

    if (type == ContinuousType.exponential) {
      minX = -0.5;
      maxX = 5;
      maxY = 1.0;
    }
    if (type == ContinuousType.chiSquared) {
      minX = 0;
      maxX = 12;
      maxY = 0.25;
    }

    for (double px = 0; px <= w; px += 2) {
      double x = minX + (px / w) * (maxX - minX);
      double yVal = 0;

      switch (type) {
        case ContinuousType.normal:
          yVal = (1 / math.sqrt(2 * math.pi)) * math.exp(-0.5 * x * x);
          break;

        case ContinuousType.tStudent:
          yVal = 0.353 * math.pow(1 + (x * x) / 2, -1.5);
          break;

        case ContinuousType.exponential:
          if (x < 0) {
            yVal = 0;
          } else {
            yVal = math.exp(-x);
          }
          break;

        case ContinuousType.chiSquared:
          if (x <= 0) {
            yVal = 0;
          } else {
            yVal = (math.pow(x, 0.5) * math.exp(-x / 2)) / 2.5066;
          }
          break;
      }

      double py = size.height - (yVal / maxY) * h;
      if (py < 0) {
        py = 0;
      }

      if (px == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    path.lineTo(w, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ContinuousPainter oldDelegate) =>
      oldDelegate.type != type;
}
