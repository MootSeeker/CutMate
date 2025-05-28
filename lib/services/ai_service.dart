import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for handling AI API requests using AIML API
class AiService {
  // AIML API endpoint
  static const String _apiEndpoint = 'https://api.aimlapi.com/v1/chat/completions';
  
  // API key - should be stored securely in a real app
  static const String _apiKey = '2985705c7b234020b911dc60006e0531';
    /// Send a request to the AI model and get a response
  static Future<String> generateText({
    required String prompt,
    String model = 'deepseek/deepseek-prover-v2',
    double temperature = 0.7,
    double topP = 0.7,
    int frequencyPenalty = 1,
    int maxOutputTokens = 512,
    int topK = 50,
  }) async {
    try {
      debugPrint('Sending request to AIML API...');
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': temperature,
          'top_p': topP,
          'frequency_penalty': frequencyPenalty,
          'max_output_tokens': maxOutputTokens,
          'top_k': topK,
        }),
      );
      
      if (response.statusCode != 200) {
        debugPrint('AIML API returned error status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to get response from AIML API: ${response.body}');
      }
      
      debugPrint('AIML API returned successfully with status code: ${response.statusCode}');
      
      // Safely parse JSON data
      final String responseBody = response.body;
      if (responseBody.isEmpty) {
        throw Exception('Empty response from AIML API');
      }
      
      try {
        final data = jsonDecode(responseBody);
        
        if (data == null || !data.containsKey('choices') || 
            data['choices'] == null || data['choices'].isEmpty) {
          debugPrint('Missing choices in API response: $data');
          throw Exception('Invalid API response structure, missing choices');
        }
        
        final choices = data['choices'];
        
        if (!choices[0].containsKey('message') || 
            choices[0]['message'] == null || 
            !choices[0]['message'].containsKey('content')) {
          debugPrint('Missing message content in API response: ${choices[0]}');
          throw Exception('Invalid API response structure, missing message content');
        }
        
        final content = choices[0]['message']['content'];
        return content;
      } catch (parseError) {
        debugPrint('Error parsing AIML API response: $parseError');
        debugPrint('Response body was: $responseBody');
        throw Exception('Error parsing AIML API response: $parseError');
      }
    } catch (e) {
      debugPrint('Error generating text from AIML API: $e');
      throw Exception('Error generating text: $e');
    }
  }
}
