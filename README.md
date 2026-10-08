# Tomato Leaf Doctor 🍅🍃

An intelligent Flutter mobile application for detecting tomato plant leaf diseases using Google's Gemini Vision API. Designed for farmers, agronomists, and home gardeners to diagnose plant pathogens and receive immediate, actionable treatment plans.

---

## 🌟 Features

- **Instant Diagnosis:** Capture live plant leaf photos via camera or select existing photos from the gallery.
- **Multimodal AI Pathology:** Powered by Gemini Vision models with automatic fallback resilience (`gemini-3.8-flash` & `gemini-3.5-flash`).
- **Actionable Treatment Plans:** Delivers comprehensive reports including pathogen identification, visual symptoms, confidence level, organic/cultural controls, and chemical treatments.
- **Resilient Error Handling:** Built-in mitigation for API rate limits (HTTP 429), offline conditions, and endpoint versioning.
- **Material 3 Design:** Clean, modern interface optimized for mobile workflows.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13+ or higher)
- A Google Gemini API key from [Google AI Studio](https://aistudio.google.com/)

### 1. Clone the Repository

```bash
git clone git@github.com:ChoyonBonik/gemini_disease_detector.git
cd gemini_disease_detector
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Key

Copy `keys.json.example` to `keys.json` (this file is excluded from git):

```bash
cp keys.json.example keys.json
```

Add your Gemini API key in `keys.json`:
```json
{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}
```

### 4. Run the App

Run on your connected Android or iOS device:

```bash
flutter run --dart-define-from-file=keys.json
```

Alternatively, supply the key directly in the command line:

```bash
flutter run --dart-define=GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

---

## 📁 Project Structure

```text
lib/
├── main.dart                      # Application entry point & theme configuration
├── screens/
│   └── dashboard_screen.dart      # Primary dashboard UI & image picking workflow
└── services/
    └── gemini_service.dart        # Gemini Vision AI service & error resilience
```

---

## 🛡️ License

This project is licensed under the MIT License.
