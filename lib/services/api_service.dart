import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // NOT: Bu anahtarları gerçek projede güvenli bir yerde saklamalısın (.env dosyası gibi)
  static const String _rapidApiKey = '9ddc3b684amshf677c7eabfcb160p1b1e17jsn8740a20734b0';
  static const String _geminiApiKey = 'AIzaSyALcLqzpgevtVe0Re26EMQ5W8gTL4yM0bI';

  // --- Judge0 API (Kod Çalıştırma) ---
  Future<Map<String, dynamic>> executeCode(String sourceCode, int languageId) async {
    final url = Uri.parse(
        'https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true');

    try {
      final response = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': _rapidApiKey,
          'X-RapidAPI-Host': 'judge0-ce.p.rapidapi.com',
        },
        body: jsonEncode({
          'source_code': sourceCode,
          'language_id': languageId, // Python için 71
          'stdin': '',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Judge0 API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı Hatası: $e');
    }
  }

  // --- Gemini API (Orkestratör Mantığı) ---
  // PDF Modül 5: Görev + Kod + Hata birleştirilip gönderilir [cite: 54, 136]
  Future<String> getAiHelp(
      String promptTemplate, String code, String errorMsg) async {
    
    // Prompt Mühendisliği: Şablondaki yer tutucuları dolduruyoruz
    final finalPrompt = promptTemplate
        .replaceAll('{CODE}', code)
        .replaceAll('{ERROR}', errorMsg);

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiApiKey);
      final content = [Content.text(finalPrompt)];
      final response = await model.generateContent(content);

      return response.text ?? "Üzgünüm, şu an tavsiye veremiyorum.";
    } catch (e) {
      return "AI Servis Hatası: $e";
    }
  }
}