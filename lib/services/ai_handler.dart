import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIHandler {
  final String baseUrl =
      "https://8001-idx-ai-chatbot-1741200952471.cluster-a3grjzek65cxex762e4mwrzl46.cloudworkstations.dev";

  final StringBuffer _responseBuffer = StringBuffer();

  void decodeStream(Uint8List streamData) {
    final decodedData = utf8.decode(streamData);
    String correctedJsonString = decodedData.replaceAll("'", "\"");
    // Split the stream into separate lines
    final lines = const LineSplitter().convert(correctedJsonString);

    for (var line in lines) {
      print("😭 ${line}");
      try {
        final data = json.decode(line);
        print("🩻 ${data['choices'][0]['message']['content']}");
        //final contentData = json.decode(data['choices'][0]);
        //print("🩻 ${contentData}");
        if (data is Map<String, dynamic> && data.containsKey('choices')) {
          // Append the response field to the StringBuffer
          //_responseBuffer.write(data['response']);
          _responseBuffer.write(data['choices'][0]['message']['content']);
        }
      } catch (e) {
        print('Error decoding JSON line: $e');
      }
    }
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? "guest";
  }

  Future<String?> createThread() async {
    String userId = await _getUserId();
    final response =
        await http.get(Uri.parse("$baseUrl/create_thread?user_id=$userId"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["thread_id"];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getThreadInfo(String threadId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/get_thread_info?thread_id=$threadId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> deleteThread(String threadId) async {
    final response = await http
        .delete(Uri.parse("$baseUrl/delete_thread?thread_id=$threadId"));
    return response.statusCode == 200;
  }

//<Map<String, dynamic>?>
  Future<String> generateResponse(String threadId, String message) async {
    String userId = await _getUserId();

    final body = jsonEncode({
      "messages": [
        {
          "role": "user",
          "content": message,
          "timestamp": DateTime.now().toIso8601String()
        }
      ],
      "user_id": userId,
      "thread_id": threadId //threadId
    });

    print("🤚${body}");
    _responseBuffer.clear();
    final response = await http.post(
      Uri.parse("$baseUrl/generate"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print("🤚${response.body}");

    // if (response.statusCode == 200) {
    //   print("❤️${response.body}");
    //   return response.body; //jsonDecode(response.body);
    // }
    if (response.statusCode == 200) {
      final stream = response.bodyBytes;
      decodeStream(stream);

      // Return the concatenated response as a string
      return _responseBuffer.toString();
    }
    return ""; //null;
  }
}
