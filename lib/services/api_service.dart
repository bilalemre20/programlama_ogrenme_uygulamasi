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

  // --- Gemini API (Yaşa Göre Kişiselleştirilmiş) ---
  Future<String> getAiHelp(
      String promptTemplate, String code, String errorMsg,
      {String ageRange = '18-25'}) async {

    // Yaş aralığına göre ton belirle
    final String ageTone = _getAgeTone(ageRange);

    final finalPrompt = '''
$ageTone

${promptTemplate.replaceAll('{CODE}', code).replaceAll('{ERROR}', errorMsg)}

Öğrencinin kodu:
$code

Hata/Çıktı:
$errorMsg
''';

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]['content']['parts']?[0]['text'];
        return text ?? 'Üzgünüm, şu an tavsiye veremiyorum.';
      } else {
        return 'AI Servis Hatası: ${response.statusCode}';
      }
    } catch (e) {
      return 'AI Servis Hatası: $e';
    }
  }

  String _getAgeTone(String ageRange) {
    switch (ageRange) {
      case '7-12':
        return '''Sen çok sevecen ve sabırlı bir öğretmensin. 
7-12 yaş arası bir çocuğa anlatıyorsun.
Çok basit kelimeler kullan, günlük hayattan örnekler ver (oyuncak, renk, hayvan gibi).
Emojiler kullan 😊. Kısa cümleler yaz. Asla teknik terim kullanma.
Hataları "Aferin, neredeyse doğruydu!" gibi pozitif bir dille anlat.''';

      case '13-17':
        return '''Sen enerjik ve anlayışlı bir öğretmensin.
13-17 yaş arası bir gence anlatıyorsun.
Günlük dil kullan, çok resmi olma. Oyun veya sosyal medya örnekleri verebilirsin.
Teknik terimleri kullanabilirsin ama kısaca açıkla.
Motivasyonel ol, "Neredeyse oldu!" gibi ifadeler kullan.''';

      case '18-25':
        return '''Sen açık ve net bir öğretmensin.
18-25 yaş arası bir genç yetişkine anlatıyorsun.
Teknik terimleri rahatça kullanabilirsin.
Direkt ve pratik ol, gereksiz açıklama yapma.
Kısa ve öz cevap ver.''';

      case '26+':
        return '''Sen profesyonel ve saygılı bir danışmansın.
26 yaş üstü bir yetişkine anlatıyorsun.
Tamamen teknik ve direkt ol. Zaman kaybettirme.
Hatanın tam olarak ne olduğunu ve nasıl düzeltileceğini söyle.
Gereksiz motivasyon cümleleri ekleme.''';

      default:
        return 'Net ve anlaşılır bir dille açıkla.';
    }
  }
}