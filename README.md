# CropDoc AI 🌿🩺

**CropDoc AI: Plant Disease Doctor** — An intelligent Flutter mobile application for rapid diagnosis of crop and plant leaf diseases powered by Google's Gemini Vision API. Built for farmers, agricultural officers, and growers to identify pathogens early and receive actionable, structured treatment plans.

---

## 🌟 Key Features

- 📸 **Instant Scan & Diagnose:** Capture live photos using the camera or select existing leaf images from the device gallery.
- 🧠 **Gemini Multimodal AI:** Powered by the latest Gemini Flash vision models (`gemini-3.8-flash` with automatic fallback to `gemini-3.5-flash`).
- 💊 **Actionable Treatment Plans:** Delivers precise diagnosis, confidence levels, visual symptoms, organic/cultural controls, chemical remedies, and prevention tips.
- 🛡️ **Resilient Architecture:** Automatic rate-limit (HTTP 429) backoff handling, endpoint version migration resilience, and offline/network failure recovery.
- 🎨 **Modern Material 3 UI:** Clean, intuitive interface optimized for high visibility outdoors and single-handed mobile use.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13+ or higher)
- A Google Gemini API key from [Google AI Studio](https://aistudio.google.com/)

### 1. Clone the Repository

```bash
git clone git@github.com:ChoyonBonik/cropdoc-ai.git
cd cropdoc-ai
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Key

Copy the example keys configuration (the real `keys.json` is protected and ignored by Git):

```bash
cp keys.json.example keys.json
```

Add your Gemini API key in `keys.json`:
```json
{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}
```

### 4. Run the Application

Run on your connected Android or iOS device:

```bash
flutter run --dart-define-from-file=keys.json
```

Or pass the key directly:

```bash
flutter run --dart-define=GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

---

## 📁 Architecture & Structure

```text
lib/
├── main.dart                      # CropDocApp initialization & theme setup
├── screens/
│   └── dashboard_screen.dart      # Main dashboard, camera/gallery picker & report UI
└── services/
    └── gemini_service.dart        # Gemini Vision integration, multi-model fallback & error recovery
```

---

## 📄 License

This project is licensed under the MIT License.
