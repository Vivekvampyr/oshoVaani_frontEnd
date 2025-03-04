import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:oshovaani/services/ai_key.dart';

class AIHandler {
  final String _baseUrl = baseUrl;

  final StringBuffer _responseBuffer = StringBuffer();

  void decodeStream(Uint8List streamData) {
    final decodedData = utf8.decode(streamData);

    // Split the stream into separate lines
    final lines = const LineSplitter().convert(decodedData);

    for (var line in lines) {
      try {
        final data = json.decode(line);
        if (data is Map<String, dynamic> && data.containsKey('response')) {
          // Append the response field to the StringBuffer
          _responseBuffer.write(data['response']);
        }
      } catch (e) {
        print('Error decoding JSON line: $e');
      }
    }
  }

  Future<String> getResponse(String message) async {
    try {
      // Clear the response buffer for a fresh start
      _responseBuffer.clear();

      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3.1:latest',
          'prompt': message,
          'max_tokens': 150,
        }),
      );
      if (response.statusCode == 200) {
        final stream = response.bodyBytes;
        decodeStream(stream);

        // Return the concatenated response as a string
        return _responseBuffer.toString();
      } else {
        return 'Error: ${response.reasonPhrase}';
      }
    } catch (e) {
      return "Ollama is currently out of reach. Please try again later.";
    }
  }
}
