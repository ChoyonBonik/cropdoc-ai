import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service responsible for communicating with the Gemini Vision API
/// to analyze tomato plant leaf diseases.
class GeminiDiseaseService {
  /// Analyzes the provided tomato leaf image using the Gemini Vision API.
  ///
  /// Defaults to `gemini-3.8-flash` with graceful fallback to alternative
  /// models if a specific model version is unavailable on the endpoint.
  Future<String> analyzeLeaf(File imageFile) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.isEmpty) {
      debugPrint('[GeminiService] Error: GEMINI_API_KEY is empty.');
      return 'Error: GEMINI_API_KEY is not set.\n\n'
          'Please run the app with your API key:\n'
          'flutter run --dart-define-from-file=keys.json\n'
          'or\n'
          'flutter run --dart-define=GEMINI_API_KEY="your_api_key"';
    }

    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imageFile.path);
      debugPrint('[GeminiService] Image size: ${imageBytes.length} bytes, type: $mimeType');

      const prompt =
          'Perform a meticulous plant pathology examination of this leaf image:\n\n'
          '## 1. PRIMARY DIAGNOSIS\n'
          '- **Disease / Condition**: [Specify exact common name and scientific name, e.g., Early Blight (Alternaria solani), Late Blight (Phytophthora infestans), Septoria Leaf Spot (Septoria lycopersici), Bacterial Spot (Xanthomonas), Tomato Yellow Leaf Curl Virus, Leaf Mold, Powdery Mildew, or Healthy Leaf]\n'
          '- **Severity Level**: [Healthy / Mild / Moderate / Critical]\n'
          '- **Confidence Score**: [e.g., 95%]\n\n'
          '## 2. OBSERVED PATHOLOGY & SYMPTOMS\n'
          '- Detail the visual symptoms: spot shapes, colors, concentric target rings, chlorotic yellow halos, margins, or curling.\n'
          '- Explain the key diagnostic features differentiating this from similar lookalikes.\n\n'
          '## 3. IMMEDIATE TREATMENT PLAN\n'
          '- **Cultural & Organic Remedies**: (Pruning infected tissue, drip irrigation, sunlight/airflow).\n'
          '- **Chemical & Fungicidal Interventions**: (Specific active ingredients: e.g. Copper hydroxide, Chlorothalonil, Mancozeb, Azoxystrobin, or Bacillus subtilis).\n\n'
          '## 4. PREVENTIVE MEASURES\n'
          '- Long-term sanitation, crop rotation, and preventative care to protect remaining yield.\n\n'
          'Format with clear markdown headings and bullet points.';

      const configuredModel = String.fromEnvironment('GEMINI_MODEL');
      final candidateModels = [
        if (configuredModel.isNotEmpty) configuredModel,
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.8-flash',
      ];

      String? lastError;

      for (final modelName in candidateModels) {
        try {
          debugPrint('[GeminiService] Attempting diagnosis with model: $modelName...');
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: Content.system(
              'You are a senior plant pathologist and agricultural disease expert. '
              'Your mission is to accurately diagnose plant foliar diseases from imagery. '
              'Inspect every quadrant of the leaf blade for subtle lesions, fungal spores, '
              'chlorotic halos, necrotic margins, water-soaked patches, leaf curling, or viral mosaics. '
              'Never overlook minor lesions or assume a leaf is healthy if any abnormal foliar symptoms are visible.'
            ),
            generationConfig: GenerationConfig(
              maxOutputTokens: 1000,
              temperature: 0.2,
            ),
          );

          final promptPart = TextPart(prompt);
          final imagePart = DataPart(mimeType, imageBytes);

          debugPrint('[GeminiService] Sending request to Gemini Vision API ($modelName)...');
          final response = await model.generateContent([
            Content.multi([promptPart, imagePart]),
          ]);

          final text = response.text;
          debugPrint('[GeminiService] Diagnosis received from $modelName.');
          if (text == null || text.trim().isEmpty) {
            return 'No diagnosis could be extracted from the response. Please try taking a clearer photo of the leaf.';
          }

          return text.trim();
        } on GenerativeAIException catch (e) {
          debugPrint('[GeminiService] Exception with $modelName: ${e.message}');
          final errorMessage = e.message.toLowerCase();

          // If the model is retired or not supported on this endpoint, try next candidate
          if (errorMessage.contains('not found') ||
              errorMessage.contains('not supported')) {
            lastError = e.message;
            continue;
          }

          if (errorMessage.contains('429') ||
              errorMessage.contains('quota') ||
              errorMessage.contains('resource has been exhausted') ||
              errorMessage.contains('rate limit')) {
            return 'Rate Limit Exceeded (HTTP 429):\n\n'
                'The Gemini API quota or rate limit has been reached. '
                'Please wait a few moments and try your scan again.';
          }

          return 'Gemini AI Error:\n${e.message}';
        }
      }

      return 'Gemini AI Error:\n$lastError';
    } on SocketException catch (e) {
      debugPrint('[GeminiService] SocketException: $e');
      return 'Network Error:\nUnable to connect to Gemini API. Please verify your internet connection and try again.';
    } catch (e, stackTrace) {
      debugPrint('[GeminiService] Unexpected error: $e\n$stackTrace');
      return 'An unexpected error occurred while analyzing the image:\n$e';
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
