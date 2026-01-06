# App Specifications: Stats Is Fun

## 1. Product Vision

**"Stats Is Fun"** is a modern, interactive, and Gen-Z friendly mobile application designed to make learning statistics engaging and intuitive. It moves away from dry textbooks and embraces interactivity, visualization, and instant feedback.

## 2. Target Audience

- **Students**: High school and college students taking Intro to Stats.
- **Self-Learners**: Data Science aspirants brushing up on fundamentals.
- **Design Style**: "Gen-Z Friendly" - Vibrant colors, emojis, casual language, and modern Material 3 aesthetics.

## 3. Core Features

### 3.1 Home Page

- **Navigation Hub**: Access to "Descriptive Statistics" and "Inferential Statistics".
- **Visual Design**: Uses gradient cards and Hero animations for smooth transitions.

### 3.2 Descriptive Statistics

**Goal**: Understand data summarization and distribution.

- **Basic Calculators**:
  - Interactive input field (comma-separated numbers).
  - Live calculation cards for: **Mean, Median, Mode, Range, Variance, Standard Deviation, Min, Max**.
- **Advanced Metrics**:
  - **Quartiles & IQR**: Q1, Q3, Interquartile Range.
  - **Shape**: Skewness (Tail direction) and Kurtosis (Peakedness).
- **Visualizations**:
  - **Distribution Chart**: Histogram with overlayed Normal Curve.
  - **Box Plot**: Visual representation of spread and outliers.
- **Analysis Tools**:
  - **Outlier Detection**: Comparison of Z-Score (Normal) vs. Tukey's Fences (IQR/Robust) methods.
  - **Normality Test**: D'Agostino's K^2 Test with P-value interpretation.
  - **Correlation Analysis**: Interactive playground for Pearson, Spearman, and Kendall correlations with visual metaphors.
- **Data Generation**:
  - "Random (Normal)" and "Random (Chaos)" buttons to quickly test different distributions.

### 3.3 Inferential Statistics

**Goal**: Make predictions and draw conclusions from data.

- **Logical Learning Flow**:
  1. **Estimation**:
      - **Confidence Interval**: slider-based calculator for Margin of Error.
      - **Sample Size**: Calculator for required N based on confidence/error.
  2. **Theory**:
      - **T-Test vs Z-Test**: Interactive card explaining when to use which (Known vs Unknown Sigma).
  3. **Hypothesis Testing**:
      - Supports **One-Sample T-Test** and **Z-Test**.
      - Supports **Two-Sided**, **Left-Sided**, and **Right-Sided** tails.
      - Dynamic "Real World Example" text based on selection.
  4. **Advanced Tests**:
      - **ANOVA Playground**: Interactive 3-group mean comparison with live F-stat.
      - **Chi-Squared Playground**: Interactive Coin Flip simulation with live Chi2-stat.
- **Code Reference**:
  - **Live Preview**: Generates Python (`scipy.stats`) code matching the current user input.
  - **Cheat Sheets**: Static reference for common `scipy` syntax (T-Test, ANOVA, Chi2).

## 4. Non-Functional Requirements

- **Performance**: instant calculation updates (<16ms) using reactive signals.
- **Responsiveness**: Layout adapts to screen size (responsive typography).
- **Accessibility**: High contrast text, clear labeling.
