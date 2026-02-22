import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static const String _rapidApiKey = Config.rapidApiKey;
  static const String _geminiApiKey = Config.geminiApiKey;

  // --- Judge0 API (Kod Çalıştırma) ---
  Future<Map<String, dynamic>> executeCode(
      String sourceCode, int languageId) async {
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
          'language_id': languageId,
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

  // --- Gemini API (Direkt HTTP) ---
  Future<String> getAiHelp(
      String promptTemplate, String code, String errorMsg) async {
    final finalPrompt = promptTemplate
        .replaceAll('{CODE}', code)
        .replaceAll('{ERROR}', errorMsg);

    print('=== GEMİNİ ÇAĞRILIYOR ===');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$_geminiApiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': finalPrompt}
              ]
            }
          ]
        }),
      );

      print('=== GEMİNİ DURUM KODU: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']['parts']?[0]['text'];
        print('=== GEMİNİ CEVAP GELDİ ===');
        return text ?? 'Üzgünüm, şu an tavsiye veremiyorum.';
      } else {
        print('=== GEMİNİ HATA DETAYI: ${response.body} ===');
        return 'AI Servis Hatası: ${response.statusCode}';
      }
    } catch (e) {
      print('=== GEMİNİ HATA: $e ===');
      return 'AI Servis Hatası: $e';
    }
  }
}