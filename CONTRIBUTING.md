# Contributing to Sprout

First off, thank you for considering contributing to **Sprout**! Community contributions help make Sprout the best companion for mindful, delicious cooking.

---

## Code of Conduct

This project and everyone participating in it is governed by the [Sprout Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## Development Workflow

### 1. Prerequisites

Make sure you have installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13.0 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code with Flutter extensions
- [Supabase CLI](https://supabase.com/docs/guides/cli) (optional, for edge function development)

### 2. Fork and Clone

1. Fork the repository on GitHub: `https://github.com/Krishh19/Sprout-Recipe-app`
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/Sprout-Recipe-app.git
   cd Sprout-Recipe-app
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```

### 3. Branching Strategy

Create a feature branch from `main`:
```bash
git checkout -b feature/your-feature-name
# or for bug fixes:
git checkout -b fix/issue-description
```

---

## Code Quality & Standards

Before opening a pull request, ensure all linting checks and test suites pass:

```bash
# 1. Run static analysis (must report zero warnings/errors)
dart analyze

# 2. Run unit and widget test suite
flutter test

# 3. Optional: Verify release build compilation
flutter build apk --release
```

### Coding Guidelines

- **Architecture**: We follow a clean layered architecture (`lib/core`, `lib/design`, `lib/features`, `lib/models`, `lib/repositories`, `lib/services`).
- **State Management**: Use `flutter_riverpod` providers for reactive state.
- **Design Tokens**: Rely on design system constants in `lib/design/` (`SproutColors`, `SproutTextStyles`, `SproutRadii`, `SproutAssets`).
- **Accessibility**: Ensure tap targets are at least 48x48dp, contrast ratios meet WCAG AA, and interactive controls provide semantic labels.
- **AI Keys**: Never commit client-side API keys or secrets to git.

---

## Submitting Pull Requests

1. Commit your changes with clear, descriptive commit messages following the Conventional Commits specification:
   ```bash
   git commit -m "feat(scanner): add auto-focus animation on viewfinder tap"
   git commit -m "fix(nutrition): handle missing micronutrient fields safely"
   ```
2. Push your branch to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```
3. Open a Pull Request against the `main` branch.
4. Fill out the PR template with context, screenshots (if UI changes), and testing details.

---

## Need Help?

Feel free to open an issue or reach out via GitHub discussions. Happy cooking and coding!
