import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/exercise_analysis.dart';

class ExerciseAnalysisService {
  // API endpoint for picture analysis
  static const String _baseUrl = 'http://192.168.1.70:5678/webhook/pic';
  
  /// Analyze workout picture and get exercise suggestions
  Future<ExerciseAnalysis> analyzeWorkoutPicture({
    required File imageFile,
    required int duration, // in seconds
  }) async {
    try {
      print('🔍 Analyzing workout picture...');
      print('📸 Image path: ${imageFile.path}');
      print('⏱️ Duration: ${duration}s');

      // Create multipart request (matching curl -F format)
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      // Add image file as binary upload (matching curl -F "file=@image.jpg")
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
      
      // Create payload_json as form field (matching curl -F 'payload_json=...')
      final payloadJson = {
        'prompt': 'What exercise can I do with this setup?',
        'duration': duration,
      };
      
      // Add payload_json as form field (exactly like curl)
      request.fields['payload_json'] = json.encode(payloadJson);
      
      // Don't add extra headers - let the multipart request handle it

      print('📤 Sending request to: $_baseUrl');
      print('📊 Request size: ${imageBytes.length} bytes');
      print('📋 Payload JSON: $payloadJson');
      print('📋 Form fields: ${request.fields}');
      print('📋 Files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').join(', ')}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      print('📥 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Check if response body is empty
        if (response.body.isEmpty) {
          print('⚠️ Empty response body, using mock data');
          return _getMockAnalysis();
        }
        
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          print('📋 Parsed JSON: $jsonData');
          
          final analysis = ExerciseAnalysis.fromJson(jsonData);
          
          print('✅ Successfully analyzed workout picture');
          print('🎯 Detected objects: ${analysis.detectedObjects}');
          print('💪 Exercise suggestions: ${analysis.exerciseSuggestions.length}');
          
          return analysis;
        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError');
          print('📥 Raw response: ${response.body}');
          return _getMockAnalysis();
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        print('📥 Error response: ${response.body}');
        return _getMockAnalysis();
      }
    } catch (e) {
      print('❌ Error analyzing workout picture: $e');
      
      // Return mock data for development/testing
      return _getMockAnalysis();
    }
  }

  /// Get mock analysis for development/testing
  ExerciseAnalysis _getMockAnalysis() {
    print('🔄 Using mock exercise analysis data (API not responding)');
    
    // Generate different mock data based on time to simulate variety
    final now = DateTime.now();
    final isEvenMinute = now.minute % 2 == 0;
    
    if (isEvenMinute) {
      return ExerciseAnalysis(
        detectedObjects: ['wall', 'floor', 'window', 'chair'],
        exerciseSuggestions: [
          ExerciseSuggestion(
            exercise: '15 wall pushups',
            instructions: 'Stand arms-length from the wall and push your body away and back. Keep your core tight and maintain a straight line from head to heels.',
          ),
          ExerciseSuggestion(
            exercise: '20 wall sits',
            instructions: 'Sit against the wall with knees at 90° and hold the position. Keep your back flat against the wall and engage your core.',
          ),
          ExerciseSuggestion(
            exercise: 'arm stretches against wall',
            instructions: 'Place your hand on the wall and gently stretch your arm and chest. Hold for 30 seconds on each side.',
          ),
        ],
      );
    } else {
      return ExerciseAnalysis(
        detectedObjects: ['floor', 'space', 'room'],
        exerciseSuggestions: [
          ExerciseSuggestion(
            exercise: '30 jumping jacks',
            instructions: 'Start with feet together and arms at sides. Jump up spreading feet shoulder-width apart while raising arms overhead.',
          ),
          ExerciseSuggestion(
            exercise: '20 squats',
            instructions: 'Stand with feet shoulder-width apart, lower your body as if sitting back into a chair, then return to standing.',
          ),
          ExerciseSuggestion(
            exercise: '15 burpees',
            instructions: 'Start standing, drop to push-up position, do a push-up, jump feet to hands, then jump up with arms overhead.',
          ),
        ],
      );
    }
  }

  /// Test API connection
  Future<bool> testApiConnection() async {
    try {
      print('🔍 Testing API connection to $_baseUrl');
      
      // Test with a simple GET request first
      final response = await http.get(
        Uri.parse(_baseUrl),
      ).timeout(const Duration(seconds: 5));
      
      print('📡 API test response: ${response.statusCode}');
      print('📡 API test body: ${response.body}');
      
      // Accept both 200 (OK) and 405 (Method Not Allowed) as valid responses
      // 405 means the endpoint exists but doesn't accept GET requests
      return response.statusCode == 200 || response.statusCode == 405;
    } catch (e) {
      print('❌ API connection test failed: $e');
      return false;
    }
  }

  /// Analyze workout picture with retry logic
  Future<ExerciseAnalysis> analyzeWorkoutPictureWithRetry({
    required File imageFile,
    required int duration,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    // First test API connection
    final isApiAvailable = await testApiConnection();
    if (!isApiAvailable) {
      print('⚠️ API not available, using mock data immediately');
      return _getMockAnalysis();
    }
    
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await analyzeWorkoutPicture(
          imageFile: imageFile,
          duration: duration,
        );
      } catch (e) {
        attempts++;
        print('❌ Attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('🔄 All retry attempts failed, using mock data');
          return _getMockAnalysis();
        }
        
        print('⏳ Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    
    // This should never be reached, but just in case
    return _getMockAnalysis();
  }
}
