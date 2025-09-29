import 'dart:convert'; // Import for jsonDecode and LineSplitter
import 'package:classroom_mini/app/core/utils/logger.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Import flutter_gemini

class GeminiService {
  // No longer need Dio or _apiKey here as flutter_gemini handles it

  GeminiService(); // No longer needs Dio in constructor

  Stream<String> generateDescription(String prompt) async* {
    // Changed return type to Stream<String>
    // API Key check is now handled by Gemini.init()

    try {
      final responseStream = Gemini.instance.promptStream(
        parts: [
          Part.text(
              'Generate a detailed assignment description for students based on the following prompt: "$prompt". Focus on clarity, requirements, and expected outcomes. The description should be in Vietnamese.')
        ],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
        model: 'models/gemini-2.0-flash', // Specify the model
      );

      await for (var candidate in responseStream) {
        if (candidate?.output != null) {
          yield candidate?.output ?? '';
          AppLogger.debug('Streamed chunk: ${candidate?.output}');
        }
      }

      AppLogger.info('Gemini API stream completed.');
    } catch (e, st) {
      AppLogger.error('Error during Gemini API stream call',
          error: e, stackTrace: st);
      yield 'An unexpected error occurred during description generation: $e';
    }
  }

  Stream<String> generateQuiz(String prompt, int numberOfQuestions) async* {
    AppLogger.info('Generating quiz questions with Gemini API...');
    try {
      final responseStream = Gemini.instance.promptStream(
        parts: [
          Part.text(
              'Generate $numberOfQuestions quiz questions based on the following topic: "$prompt". ' +
              'Each question should be in JSON format, as an array of objects. ' +
              'Each question object must have: ' +
              '- `question_text`: string\n' +
              '- `question_type`: string (\'text\' or \'multiple_choice\')\n' +
              '- `points`: integer (e.g., 1)\n' +
              '- `is_required`: boolean (e.g., true)\n' +
              '- `options`: array of objects (only for \'multiple_choice\' type). Each option object must have:\n' +
              '    - `option_text`: string\n' +
              '    - `is_correct`: boolean\n' +
              'Example JSON structure for a multiple-choice question:\n' +
              '```json\n' +
              '{\n' +
              '  "question_text": "What is the capital of France?",\n' +
              '  "question_type": "multiple_choice",\n' +
              '  "points": 1,\n' +
              '  "is_required": true,\n' +
              '  "options": [\n' +
              '    {"option_text": "Berlin", "is_correct": false},\n' +
              '    {"option_text": "Paris", "is_correct": true},\n' +
              '    {"option_text": "Rome", "is_correct": false}\n' +
              '  ]\n' +
              '}\n' +
              '```\n' +
              'Example JSON structure for a text question:\n' +
              '```json\n' +
              '{\n' +
              '  "question_text": "Explain the concept of polymorphism.",\n' +
              '  "question_type": "text",\n' +
              '  "points": 2,\n' +
              '  "is_required": true\n' +
              '}\n' +
              '```\n' +
              'Ensure the output is a single JSON array of question objects. Do not include any introductory or concluding text outside the JSON array.')
        ],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 4096, // Increased for potentially more questions
        ),
        model: 'models/gemini-2.0-flash', // Specify the model
      );

      await for (var candidate in responseStream) {
        if (candidate?.output != null) {
          yield candidate?.output ?? '';
          AppLogger.debug('Streamed quiz chunk: ${candidate?.output}');
        }
      }

      AppLogger.info('Gemini Quiz API stream completed.');
    } catch (e, st) {
      AppLogger.error('Error during Gemini Quiz API stream call',
          error: e, stackTrace: st);
      yield 'An unexpected error occurred during quiz generation: $e';
    }
  }
}

