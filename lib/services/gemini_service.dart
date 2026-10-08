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
          'You are an expert agricultural plant pathologist and agronomist specializing in tomato crops. '
          'Carefully inspect this tomato leaf image:\n'
          '1. Identify the disease or issue (e.g., Early Blight, Late Blight, Septoria Leaf Spot, Tomato Yellow Leaf Curl Virus, Bacterial Spot, or Healthy).\n'
          '2. State your confidence level and the primary visual symptoms observed.\n'
          '3. Provide an actionable, concise treatment and management plan (including organic/cultural controls and chemical treatments if applicable).\n'
          '4. Provide preventive measures for future crops.\n\n'
          'Format your response cleanly with clear headings and bullet points.';

      const configuredModel = String.fromEnvironment('GEMINI_MODEL');
      final candidateModels = [
        if (configuredModel.isNotEmpty) configuredModel,
        'gemini-3.8-flash',
        'gemini-3.5-flash',
        'gemini-1.5-flash',
      ];

      String? lastError;

      for (final modelName in candidateModels) {
        try {
          debugPrint('[GeminiService] Attempting diagnosis with model: $modelName...');
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
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
