# CropDoc AI 🌿🩺

**CropDoc AI: Plant Disease Doctor** — An intelligent Flutter mobile application for rapid diagnosis of crop and plant leaf diseases powered by Google's Gemini Vision API. Built for farmers, agricultural officers, and growers to identify pathogens early, track field history offline, and follow structured treatment plans.

---

## 🌟 Key Features

- 📸 **Instant Scan & Diagnose:** Capture live photos using the camera or select existing leaf images from the device gallery.
- 🧠 **Gemini Multimodal Vision AI:** Expert plant pathology system prompt targeting foliar lesions (blights, spots, mosaics, curling, mold) with rapid multi-model fallback resilience (`gemini-3.5-flash` → `gemini-3.5-flash-lite` → `gemini-3.8-flash`).
- 🩺 **Clinical Prescription UI:** Highlights disease name, color-coded severity badges (🟢 Healthy, 🟠 Moderate, 🔴 Critical), and full formatted markdown pathology reports.
- ✅ **Interactive Treatment Checklist:** Automatically extracts actionable treatment & preventative tasks into checkable tasks with a real-time progress meter.
- 💾 **Offline Scan History & Archive:** Automatically saves all diagnoses and local image copies to persistent storage. Review past reports, search by disease name, and filter by severity without requiring internet.
- 🛡️ **Resilient Architecture:** Automatic rate-limit (HTTP 429) backoff handling, endpoint version migration resilience, and offline/network failure recovery.

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

Run with the included runner script:

```bash
./run.sh
```

Or pass `keys.json` directly:

```bash
flutter run --dart-define-from-file=keys.json
```

---

## 📁 Architecture & Structure

```text
lib/
├── main.dart                      # CropDocApp initialization & theme setup
├── models/
│   └── scan_record.dart           # Offline scan history data model
├── screens/
│   ├── dashboard_screen.dart      # Main scan dashboard & camera/gallery workflow
│   └── history_screen.dart        # Offline history browser, search & archive
├── services/
│   ├── gemini_service.dart        # Gemini Vision AI service, fallback & recovery
│   └── history_service.dart       # Local persistent storage & image copy manager
└── widgets/
    └── diagnosis_report_view.dart # Clinical report tabs & interactive checklist
```

---

## 📄 License

This project is licensed under the MIT License.
