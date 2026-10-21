<p align="center">
  <img src="assets/mascot/sprout_cooking.png" alt="Chef Sprout Mascot" width="120" />
</p>

<h1 align="center">🌱 Sprout — AI Recipe & Smart Kitchen Companion</h1>

<p align="center">
  <b>Cook smarter, eat healthier, and minimize food waste with multimodal AI vision, voice-guided cooking, smart meal planning, and intelligent pantry matching.</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-v3.13+-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-v3.13+-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://github.com/Krishh19/Sprout-Recipe-app/releases"><img src="https://img.shields.io/badge/Release-v1.1.1-4CAF50?logo=github&logoColor=white" alt="Release"></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Backend%20%26%20Edge%20Functions-3ECF8E?logo=supabase&logoColor=white" alt="Supabase"></a>
  <a href="https://groq.com"><img src="https://img.shields.io/badge/Groq-Qwen%2027B%20Inference-F05A28" alt="Groq"></a>
  <a href="https://ai.google.dev"><img src="https://img.shields.io/badge/Gemini-Multimodal%20Vision-4285F4?logo=google&logoColor=white" alt="Gemini"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
  <a href="https://github.com/Krishh19/Sprout-Recipe-app/actions"><img src="https://img.shields.io/badge/Tests-199%20Passing-brightgreen" alt="Tests"></a>
</p>

---

## 📖 Table of Contents

- [About Sprout](#-about-sprout)
- [Key Features](#-key-features)
- [App Showcase](#-app-showcase)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Supabase Edge Functions Backend](#-supabase-edge-functions-backend)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Security Model](#-security-model)
- [Release Notes & Tagging](#-release-notes--tagging)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌿 About Sprout

**Sprout** is an intelligent Flutter culinary companion designed to turn whatever you have in your fridge or pantry into delicious, nutritious meals. 

By pairing **multimodal computer vision** (Google Gemini) with **ultra-fast language inference** (Groq Qwen 27B) and a **cloud-synced pantry database** (Supabase), Sprout eliminates mealtime indecision, tracks real-time nutrition, plans your weekly diet, and coaches you step-by-step through every recipe completely hands-free.

---

## ✨ Key Features

### 🔍 Explore & Smart Search
- **Animated Typewriter Suggestions**: Typewriter animation with blinking cursor rotating through realistic prompts (*"Search high-protein recipes..."*, *"Try Indian dinner recipes..."*, *"Find quick breakfast ideas..."*). Smoothly suspends on user focus and respects reduced-motion accessibility.
- **Bilingual Voice Search**: Integrated Speech-to-Text (STT) supporting English (`en_IN`, `en_US`) and Hindi (`hi_IN`) with pulsing microphone feedback, cancelable listening, and automatic typed fallback.
- **Dedicated Discovery Shortcuts**: 6 quick-intent pills (`All`, `Indian`, `Quick`, `High Protein`, `Healthy`, `Vegetarian`) cleanly separated from advanced filters.
- **Comprehensive Filter Sheet**: Deep multi-parameter filtering across cuisines, dietary preferences, max cooking time slider, calorie ceilings, and included/excluded pantry items.
- **Structured Feed**: Categorized sections including *Recommended for You ✨* (with working full-catalog navigation), *Browse by Cuisine 🌍*, and complete recipe explore listings.

### 📸 Unified AI Ingredient & Barcode Scanner
- **Symmetrical Vision Overlay**: Redesigned viewfinder overlay (`SproutScannerOverlay`) featuring 4 mathematically symmetrical clockwise-arc corner brackets in botanical green (`#69F0AE`).
- **Clean Camera Viewfinder**: Clear instructions (*"Point at ingredients"*) without decorative mock badges or deceptive radar effects.
- **Ergonomic Capture Control Bar**: Ergonomic bottom bar with Gallery photo picker, prominent 76×76 shutter button, and flashlight toggle.
- **Genuine AI Verification Flow**: Review recognized ingredients, remove false detections, type in staples, and query matching recipes.
- **Packaged Food Barcodes**: Built-in barcode scanner integrated with **Open Food Facts API** to fetch certified nutritional facts, brand details, and allergen warnings in real-time.

### 📅 Smart Pantry & Weekly Meal Planner
- **Hand-Drawn Mascot Empty State**: Artisan colored-pencil illustration of Sprout with an open planner notebook, yellow pencil, and botanical doodles in warm cream and sage (zero pink).
- **Compact Dual Home Cards**: Streamlined side-by-side action cards (*"Scan your ingredients"* & *"Plan your week"*) with full-card touch targets and zero layout overflow.
- **Interactive Day-by-Day Calendar**: Calendar carousel with clean, unclipped date pills and zero shadow artifacts.
- **Auto-Generated Grocery Export**: Export individual days or the entire week's meal schedule directly into your interactive shopping list.

### ⚡ Ultra-Fast AI Culinary Intelligence (Groq Qwen 27B)
- **Smart Substitutions**: Out of butter, buttermilk, or eggs? Get context-aware, culinary-accurate substitutions with custom baking/cooking ratios in milliseconds.
- **Instant Multilingual Translation**: Translate entire ingredient lists and cooking instructions into Hindi, Spanish, French, and regional languages without lag.
- **Nutrition Decomposition**: Instant calculation of calories, protein, carbs, fats, fiber, and micronutrients tailored to your exact serving sizes.

### 🍳 Hands-Free Voice-Guided Cooking Mode
- **Step-by-Step Focus**: Clean, high-contrast, distraction-free cards highlighting the active instruction.
- **Voice Control & Audio Feedback**: Hands-free navigation ("Next", "Back", "Repeat") and custom Text-to-Speech (TTS) reading steps aloud with offline TTS fallback.
- **Independent Step Timers**: Audio countdown timers synced directly to individual recipe steps with soothing completion chimes.

### 🎨 Artisan Design System & Edge-to-Edge Material 3
- **Edge-to-Edge System Bars**: Transparent status and navigation bars with adaptive icon contrast across light and dark modes.
- **Chef Sprout Mascot**: Contextual mascot reactions that cheer you on, celebrate completed meals, and guide newcomers.
- **Double-Back-to-Exit Safety**: SnackBar confirmation on the home screen prevents accidental app dismissal.

---

## 📱 App Showcase

| 🏠 Home & Feed | 📸 AI Vision Scanner | 🥗 Recipe & Nutrition |
| :---: | :---: | :---: |
| <img src="screenshots/01_home_screen.png" alt="Home Screen" width="240"/> | <img src="screenshots/02_ingredient_scanner.png" alt="Ingredient Scanner" width="240"/> | <img src="screenshots/03_recipe_details.png" alt="Recipe Details" width="240"/> |

<br/>

| 🍳 Voice Cooking Mode | 📅 Meal Planner | 👨‍🍳 Chef Sprout Profile |
| :---: | :---: | :---: |
| <img src="screenshots/04_cooking_mode.png" alt="Cooking Assistant" width="240"/> | <img src="screenshots/06_meal_planner.png" alt="Meal Planner" width="240"/> | <img src="screenshots/05_profile_dietary.png" alt="Profile Screen" width="240"/> |

> *Note: Place your screenshots in the [`screenshots/`](screenshots/) directory to render the previews on GitHub.*

---

## 🛠️ Architecture & Tech Stack

```
                        ┌──────────────────────────────────────┐
                        │             Flutter App              │
                        │ (Riverpod State + Material 3 Design) │
                        └──────────────────┬───────────────────┘
                                           │
                        ┌──────────────────┴───────────────────┐
                        │        Supabase Edge Function        │
                        │           (sprout-ai / Deno)         │
                        └───────┬──────────────────────┬───────┘
                                │                      │
                 ┌──────────────▼──────────┐   ┌───────▼─────────────┐
                 │    Groq Fast Cloud      │   │  Google Gemini AI   │
                 │   (Qwen 27B LLM Engine) │   │ (Multimodal Vision) │
                 └─────────────────────────┘   └─────────────────────┘
```

| Layer | Technologies |
| :--- | :--- |
| **Frontend Framework** | [Flutter 3.13+](https://flutter.dev) (Dart 3.13+) |
| **State Management** | [flutter_riverpod 3.4+](https://riverpod.dev) |
| **Backend & Database** | [Supabase](https://supabase.com) (PostgreSQL, Row Level Security, Edge Functions) |
| **Fast AI Inference** | [Groq Cloud](https://groq.com) (`qwen/qwen3.8-27b`) for nutrition, substitution, and translation |
| **Vision AI** | [Google Gemini 2.5 Flash](https://ai.google.dev) for multimodal image and ingredient recognition |
| **Camera & Barcode** | [mobile_scanner 7.4+](https://pub.dev/packages/mobile_scanner) & [image_picker](https://pub.dev/packages/image_picker) |
| **Speech & Audio** | [speech_to_text](https://pub.dev/packages/speech_to_text), [flutter_tts](https://pub.dev/packages/flutter_tts), [audioplayers](https://pub.dev/packages/audioplayers) |
| **Secure Storage** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (Android Keystore / iOS Keychain) |
| **Walkthrough** | [showcaseview](https://pub.dev/packages/showcaseview) for interactive spotlight tours |

---

## 📂 Project Structure

```text
sprout/
├── .github/
│   ├── workflows/ci.yml           # Automated lint, test, and build CI
│   ├── ISSUE_TEMPLATE/            # Bug report & feature request templates
│   └── PULL_REQUEST_TEMPLATE.md   # Standardized PR checklist
├── assets/
│   ├── brand/                     # App icons & brand assets
│   ├── cooking/                   # Cooking mode visual assets
│   ├── empty_scans/               # Empty state illustrations
│   ├── ingredients/               # 38 optimized ingredient icon assets
│   ├── mascot/                    # Chef Sprout mascot expressions
│   ├── onboarding/                # Intro slider illustrations
│   ├── spotlight tour/            # Tutorial coach mark assets
│   └── styling/                   # Decorative stickers & backdrop elements
├── lib/
│   ├── core/                      # Global configuration, routes & tutorial steps
│   ├── design/                    # Design tokens, typography, radii & components
│   │   └── components/
│   │       ├── sprout_typewriter_hint.dart   # Animated typewriter search placeholder
│   │       └── ...
│   ├── features/
│   │   ├── cooking/               # Interactive cooking assistant screen
│   │   ├── home/                  # Home recipe feed & pantry highlights
│   │   │   └── widgets/
│   │   │       └── sprout_weekly_planner_card.dart  # Hand-drawn empty state card
│   │   ├── onboarding/            # First-run welcome carousel
│   │   ├── planner/               # Meal planning features & calendar
│   │   ├── profile/               # Chef Sprout profile, preferences & legal
│   │   ├── recipes/               # Recipe detail, nutrition & substitutions
│   │   ├── saved/                 # Bookmarks & custom collections
│   │   ├── scanner/               # AI Vision & Barcode ingredient scanner
│   │   │   └── widgets/
│   │   │       └── sprout_scanner_overlay.dart      # Unified symmetrical viewfinder
│   │   ├── search/                # Smart search, voice STT & multi-filter sheet
│   │   └── shopping/              # Smart grocery shopping list
│   ├── models/                    # Data models (Recipe, Pantry, Nutrition, etc.)
│   ├── providers/                 # Riverpod state providers
│   ├── repositories/              # Supabase & Open Food Facts data layer
│   └── services/                  # Voice STT/TTS and AI services
│       └── sprout_voice_search_service.dart         # Bilingual speech recognition
├── screenshots/                   # App screenshots for documentation
├── supabase/
│   └── functions/sprout-ai/       # Secure Edge Function (Groq + Gemini proxy)
└── test/                          # Unit, widget, and integration tests (198 tests across 35 suites)
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.0`)
- [Git](https://git-scm.com/)
- Android Studio / Xcode

### 2. Clone the Repository
```bash
git clone https://github.com/Krishh19/Sprout-Recipe-app.git
cd Sprout-Recipe-app
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configuration
Sprout connects to your Supabase backend. Client keys are safe for public distribution because sensitive inference keys (`GEMINI_API_KEY`, `GROQ_API_KEY`) reside exclusively in your Supabase Edge Function secrets.

You can configure keys via environment flags at compile time:
```bash
flutter run \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-supabase-publishable-key"
```

---

## ⚡ Supabase Edge Functions Backend

Sprout's AI capabilities are powered by the `sprout-ai` Edge Function located in `supabase/functions/sprout-ai/index.ts`.

### Deploying the Edge Function:
```bash
# 1. Login to Supabase CLI
supabase login

# 2. Link your Supabase project
supabase link --project-ref your-project-id

# 3. Set Edge Function Secrets
supabase secrets set GEMINI_API_KEY="your-gemini-key"
supabase secrets set GROQ_API_KEY="your-groq-key"

# 4. Deploy the function
supabase functions deploy sprout-ai
```

---

## 🧪 Testing & Quality Assurance

Sprout maintains 100% test pass rates across 199 unit and widget tests:

```bash
# Run Dart analyzer (ensures 0 lints, 0 warnings, 0 errors)
dart analyze

# Run all test suites
flutter test

# Generate test coverage report
flutter test --coverage
```

### Building the Release APK
To build a standalone production release APK:
```bash
flutter build apk --release
# The APK is generated at build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔒 Security Model

- **No Secrets in Client Builds**: All Groq and Gemini API keys are processed server-side in Supabase Edge Functions. Client decompilation reveals zero AI secret tokens.
- **Row Level Security (RLS)**: Enforced across all Supabase database tables ensuring users can only read and write their own data.
- **Hardware-Backed Encryption**: On-device tokens and settings are encrypted via `flutter_secure_storage` utilizing Android Keystore and iOS Keychain.

For vulnerability disclosure, please refer to our [Security Policy](SECURITY.md).

---

## 🏷️ Release Notes & Tagging

Detailed release notes and changelogs are published on GitHub Releases:
- **Latest Release:** [v1.1.0](https://github.com/Krishh19/Sprout-Recipe-app/releases/tag/v1.1.0)
- **Tag:** `v1.1.0`

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are warmly welcomed! 

1. Review the [Code of Conduct](CODE_OF_CONDUCT.md).
2. Check the [Contributing Guide](CONTRIBUTING.md) for branch and commit conventions.
3. Open a Pull Request or create an issue using our GitHub templates.

---

## 📄 License

This project is licensed under the terms of the [MIT License](LICENSE).

<p align="center">
  Made with ❤️ and passion by <a href="https://github.com/Krishh19"><b>Krish</b></a>.
</p>
