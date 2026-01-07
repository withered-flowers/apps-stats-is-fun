# Stats Is Fun

Stats Is Fun is interactive, feels modern, and actually makes learning statistics halfway decent. We're ditching the dry textbooks for something that moves and reacts as fast as you think.

---

## The Vibe

We're aiming to bridge the gap between boring theory and actually doing stuff. whether you're in high school, grinding through a college Intro to Stats course, or just trying to brush up on data science, this app is built for you. It's designed to look good and feel good to use.

## What can it do?

### Descriptive Statistics

*Understand data without falling asleep.*

* **Real-time Calculators**: Type in numbers and watch the Mean, Median, Mode, Variance, and Standard Deviation update instantly. No waiting.
* **Visualizations**:
  * **Distribution Chart**: Histograms with Normal Curves that shift when your data does.
  * **Box Plots**: See the spread, quartiles, and outliers clearly.
* **Advanced Stuff**:
  * **Outlier Detection**: Check Z-Score vs. Tukey's Fences.
  * **Normality Tests**: Run D'Agostino's K^2 Test.
  * **Correlation Playground**: Mess around with Pearson, Spearman, and Kendall correlations to see how they work.

### Inferential Statistics

*Make predictions and draw conclusions.*

* **Hypothesis Testing**: One-Sample T-Tests and Z-Tests that come with dynamic real-world examples.
* **Interactive Playgrounds**:
  * **ANOVA**: Compare 3 groups and watch the F-stat move.
  * **Chi-Squared**: Flip coins instantly and see the Chi2-stats.
* **Code Generation**: The app shows you the actual Python `scipy.stats` code for whatever you are doing on screen.

## Under the Hood

This project is built with **Flutter** and uses a modern, reactive architecture to keep things snappy.

* **Framework**: Flutter
* **State Management**: signals (this is why everything updates instantly)
* **Navigation**: go_router
* **Typography**: google_fonts
* **Linting**: flutter_lints

## How to run it

This is a standard Flutter project. Here is how you get it running on your machine:

1. **Prerequisites**: Make sure you have the Flutter SDK installed.

2. **Clone the repo**:

    ```bash
    git clone <repository-url>
    cd apps-stats-is-fun
    ```

3. **Install dependencies**:

    ```bash
    flutter pub get
    ```

4. **Run the app**:

    ```bash
    flutter run
    ```
