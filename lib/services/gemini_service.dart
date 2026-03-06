import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDtXSu88QtI9raArK5jMf-EdYGwLJVFTy0';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  Future<String> explainScanResult({
    required String verdict,
    required String detectedMedicine,
    required String selectedMedicine,
    required bool isAuthentic,
    required bool isFresh,
    required bool medicineMatches,
    required double spectralMatch,
    required double aiConfidence,
  }) async {
    try {
      final prompt = '''
You are a pharmaceutical AI assistant for VeriScan, 
a medicine authentication system.

A NIR spectral scan was performed on a tablet with 
these results:
- Medicine selected by user: $selectedMedicine
- Medicine detected by AI: $detectedMedicine
- AI model verdict: $verdict
- Is medicine fresh/authentic condition: $isFresh
- Medicine type matches selection: $medicineMatches
- Spectral similarity score: ${(spectralMatch * 100).toStringAsFixed(1)}%
- AI model confidence: ${(aiConfidence * 100).toStringAsFixed(1)}%
- Final result: ${isAuthentic ? 'AUTHENTIC' : 'COUNTERFEIT/DANGEROUS'}

Write a clear, simple 3-sentence explanation for a 
pharmacist or lab technician explaining:
1. What the scan found
2. Why it is authentic or fake
3. What action they should take

Use simple English. Do not use bullet points. 
Do not use markdown. Maximum 80 words.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 
          'Analysis complete. Please consult a pharmacist for further verification.';
    } catch (e) {
      return 'AI explanation unavailable. '
          'Result is based on spectral analysis: '
          '${isAuthentic ? "Medicine appears authentic." : "Medicine may be counterfeit."}';
    }
  }
}
