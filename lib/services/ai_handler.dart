import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AIHandler {
  final String baseUrl =
      "https://8001-idx-ai-chatbot-1741200952471.cluster-a3grjzek65cxex762e4mwrzl46.cloudworkstations.dev";

  final StringBuffer _responseBuffer = StringBuffer();

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bearer_token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getBearerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bearer_token');
    await prefs.remove('username');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPassword');
    await prefs.remove('userProfile');
  }

  void decodeStream(Uint8List streamData) {
    final decodedData = utf8.decode(streamData);
    String correctedJsonString = decodedData.replaceAll("'", "\"");
    // Split the stream into separate lines
    final lines = const LineSplitter().convert(correctedJsonString);

    for (var line in lines) {
      print("😭 $line");
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

  Future<String?> _getUserId() async {
    print("USER ID IS CREATED");
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? "guest";
  }

  Future<bool> signUp(String email, String password) async {
    try {
      print('Attempting signup with email: $email');
      final username = email.split('@')[0]; // Using part before @ as username

      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'username': email,
          'password': password,
          'full_name': username,
          'img_path': 'string',
          'grant_type': 'password',
          'scope': '',
          'client_id': 'string',
          'client_secret': 'string',
        },
      );

      print('Signup response status: ${response.statusCode}');
      print('Signup response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', data['email']);
        await prefs.setString('username', data['username']);
        await prefs.setString(
            'userName', data['full_name']); // Store full_name as userName
        if (data['picture_url'] != null) {
          await prefs.setString('userProfile', data['picture_url']);
        }
        // Clear chat history for new user signup
        await prefs.remove('chatHistory');
        await prefs.remove('chatTitles');
        await prefs.remove('lastSelectedChat');
        return true;
      } else {
        // Handle specific error cases
        final errorBody = jsonDecode(response.body);
        print('Signup failed with error: $errorBody');

        // If user already exists, try to login instead
        if (response.statusCode == 409) {
          print('User already exists, attempting login...');
          return await login(email, password);
        }

        return false;
      }
    } catch (e) {
      print('Error during signup: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/auth/get_user"),
        headers: headers,
      );

      print('Get user details response status: ${response.statusCode}');
      print('Get user details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      final prefs = await SharedPreferences.getInstance();
      final currentEmail = prefs.getString('userEmail');

      final response = await http.post(
        Uri.parse("$baseUrl/auth/token"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'grant_type': 'password',
          'username': email,
          'password': password,
          'scope': '',
          'client_id': 'string',
          'client_secret': 'string',
        },
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] == null) {
          print('No access token in response');
          return false;
        }

        // Only clear chat history if logging in with a different account
        if (currentEmail != email) {
          await prefs.remove('chatHistory');
          await prefs.remove('chatTitles');
          await prefs.remove('lastSelectedChat');
        }

        // Store the access token first
        await prefs.setString('bearer_token', data['access_token']);
        await prefs.setString('userEmail', email);

        // Get user details using the new endpoint
        final userDetails = await getUserDetails();
        if (userDetails != null) {
          final fullName = userDetails['full_name'] ?? email.split('@')[0];
          await prefs.setString('userName', fullName);
          await prefs.setString(
              'username', fullName); // Store in username field as well
          if (userDetails['picture_url'] != null) {
            await prefs.setString('userProfile', userDetails['picture_url']);
          }
          print('Stored user details - full_name: $fullName');
        } else {
          print('Failed to get user details from backend');
        }

        print('Login successful, token and user details stored');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        print('Login failed with error: $errorBody');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      // First, get the Google OAuth URL from the backend
      final response = await http.get(
        Uri.parse("$baseUrl/auth/login/google"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authUrl = data['url'];

        // Launch the URL in browser
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);

          // Wait for the callback with the access token
          final callbackResponse = await http.get(
            Uri.parse("$baseUrl/auth/callback/google"),
          );

          if (callbackResponse.statusCode == 200) {
            final tokenData = jsonDecode(callbackResponse.body);
            final prefs = await SharedPreferences.getInstance();

            // Store the access token
            await prefs.setString('bearer_token', tokenData['access_token']);

            // Get user details using the token
            final userDetails = await getUserDetails();
            if (userDetails != null) {
              await prefs.setString('userEmail', userDetails['email'] ?? '');
              await prefs.setString('userName', userDetails['full_name'] ?? '');
              await prefs.setString('username', userDetails['username'] ?? '');
              if (userDetails['picture_url'] != null) {
                await prefs.setString(
                    'userProfile', userDetails['picture_url']);
              }
            }

            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error during Google login: $e');
      return false;
    }
  }

  Future<bool> loginWithGithub() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth/login/github"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bearer_token', data['access_token']);
        await prefs.setString(
            'userEmail', data['username']); // Using email from response
        return true;
      }
      return false;
    } catch (e) {
      print('Error during Github login: $e');
      return false;
    }
  }

  Future<String?> createThread() async {
    String userId = await _getUserId() ?? "guest";
    print("CREATE THREAD IS WORKING");
    final headers = await _getAuthHeaders();

    final response = await http.get(
      Uri.parse("$baseUrl/create_thread?user_id=$userId"),
      headers: headers,
    );

    print(
        "🐱‍🚀${response.body} ${response.statusCode} url${"$baseUrl/create_thread?user_id=$userId"}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["thread_id"];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getThreadInfo(String threadId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/get_thread_info?thread_id=$threadId"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> deleteThread(String threadId) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse("$baseUrl/delete_thread?thread_id=$threadId"),
      headers: headers,
    );
    return response.statusCode == 200;
  }

//<Map<String, dynamic>?>
  Future<String> generateResponse(String threadId, String message) async {
    String userId = await _getUserId() ?? "guest";
    final headers = await _getAuthHeaders();

    final body = jsonEncode({
      "messages": [
        {
          "role": "user",
          "content": message,
          "timestamp": DateTime.now().toIso8601String()
        }
      ],
      "user_id": userId,
      "thread_id": threadId
    });

    print("🤚$body");
    _responseBuffer.clear();
    final response = await http.post(
      Uri.parse("$baseUrl/generate"),
      headers: headers,
      body: body,
    );

    print("🤚${response.body}");

    if (response.statusCode == 200) {
      final stream = response.bodyBytes;
      decodeStream(stream);

      // Return the concatenated response as a string
      return _responseBuffer.toString();
    }
    return ""; //null;
  }
}
