import 'dart:convert' as convert;
import 'dart:io';
import 'gemini-api.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class ChatService {
  askGemini(List<Map<String, Object>> chatHistory) async {
    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent",
      ),
      headers: {
        'Content-Type': 'application/json',
        "x-goog-api-key": Gemini.key,
      },
      body: convert.jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": """You are a chef who know how to prepare food"""},
          ],
        },
        "contents": chatHistory,
        "generationConfig": {
          "thinkingConfig": {"thinkingLevel": "low"},
        },
      }),
    );
    print(response.body.toString());
    if (response.statusCode == 200) {
      final jsaonData = convert.jsonDecode(response.body);
      final jsonCanArray = jsaonData['candidates'];
      if (jsonCanArray != null && jsonCanArray.isNotEmpty) {
        return jsonCanArray[0]['content']['parts'][0]['text'];
      } else {
        return "sorry!! There is some error! ${response.statusCode}";
      }
    }else {
      return "There is some error! ${response.statusCode}";
    }
  }

  generateImage(prompt) async {
    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
      ),
      headers: {
        'Content-Type': 'application/json',
        "x-goog-api-key": Gemini.key,
      },
      body: convert.jsonEncode({
        "model": "gemini-3.1-flash-image",
        "input": [
          {"type": "text", "text": prompt},
        ],
      }),
    );

    print(response.body.toString());
    if (response.statusCode == 200) {
      return "Sorry!! we don't have this feature right now";
    } else {
      return "There is some error! " + response.statusCode.toString();
    }
  }

  editImage(String prompt, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = convert.base64Encode(bytes);
    final mimeType = lookupMimeType(imageFile.path)?? 'image/jpeg';


    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
      ),
      headers: {
        'Content-Type': 'application/json',
        "x-goog-api-key": Gemini.key,
      },
      body: convert.jsonEncode({
        "model": "gemini-3.1-flash-image",
        "input": [
          {
            "type": "text",
            "text":
                prompt,
          },
          {
            "type": "image",
            "mime_type": mimeType,
            "data": base64Image,
          },
        ],
      }),
    );

    print(response.body.toString());
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "There is some error! " + response.statusCode.toString();
    }
  }

  understandImage(String prompt, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = convert.base64Encode(bytes);
    final mimeType = lookupMimeType(imageFile.path)?? 'image/jpeg';

    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
      ),
      headers: {
        'Content-Type': 'application/json',
        "x-goog-api-key": Gemini.key,
      },
      body: convert.jsonEncode({
        "model": "gemini-3.1-flash-image",
        "input": [
          {
            "type": "text",
            "text":
            prompt,
          },
          {
            "type": "image",
            "mime_type": mimeType,
            "data": base64Image,
          },
        ],
      }),
    );
    print(response.body.toString());
    if (response.statusCode == 200) {
      final jsaonData = convert.jsonDecode(response.body);
      final jsonCanArray = jsaonData['candidates'];
      if (jsonCanArray != null && jsonCanArray.isNotEmpty) {
        return jsonCanArray[0]['content']['parts'][0]['text'];
      } else {
        return "sorry!! There is some error! ${response.statusCode}";
      }
    }else {
      return "There is some error! ${response.statusCode}";
    }
  }

  understandDocument(String prompt, File file) async {
    print("before bytes");
    final bytes = await file.readAsBytes();
    print("after bytes");
    final base64Image = convert.base64Encode(bytes);
    final mimeType = lookupMimeType(file.path)?? 'application/pdf';
    print("before response");
    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
      ),
      headers: {
        'Content-Type': 'application/json',
        "x-goog-api-key": Gemini.key,
      },
      body: convert.jsonEncode({
        "model": "gemini-3.5-flash",
        "input": [
          {
            "type": "document",
            "mime_type": mimeType,
            "data": base64Image,
          },
          {
            "type": "text",
            "text": prompt,
          },
        ],
      }),
    );
    print(response.body.toString());
    if (response.statusCode == 200) {
      final jsaonData = convert.jsonDecode(response.body);
      final jsonCanArray = jsaonData['candidates'];
      if (jsonCanArray != null && jsonCanArray.isNotEmpty) {
        return jsonCanArray[0]['content']['parts'][0]['text'];
      } else {
        return "sorry!! There is some error! ${response.statusCode}";
      }
    }else {
      return "There is some error! ${response.statusCode}";
    }
  }

  Future<String> understandAudio(File audioFile, String prompt) async {
    final mimeType = lookupMimeType(audioFile.path) ?? 'audio/mpeg';
    final fileLength = await audioFile.length();

    // Step 1: Upload audio file to Files API
    final uploadResponse = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/files?key=${Gemini.key}",
      ),
      headers: {
        "Content-Type": mimeType,
      },
      body: await audioFile.readAsBytes(),
    );
    print(uploadResponse.body);

    final fileInfo = convert.jsonDecode(uploadResponse.body);
    final fileUri = fileInfo["file"]?["uri"];

// Step 2: Use file_uri in generateContent
    final generateResponse = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/interactions"),
      headers: {"Content-Type": "application/json", "x-goog-api-key": Gemini.key},
      body: convert.jsonEncode({
        "model": "gemini-3.5-flash",
        "input": [
          {"type": "text", "text": prompt},
          {
            "type": "audio",
            "uri": fileUri,
            "mime_type": mimeType,
          }
        ]
      }),
    );

    print(generateResponse.body);
    if (generateResponse.statusCode == 200) {
      final jsonData = convert.jsonDecode(generateResponse.body);
      final candidates = jsonData['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]["content"]["parts"][0]["text"];
      } else {
        return "No response content.";
      }
    }

    return "Failed to understand audio. Response: ${generateResponse.body}";
  }

  Future<String> understandVideo(File videoFile, String prompt) async {
      final apiKey = Gemini.key;
      final mimeType = lookupMimeType(videoFile.path) ?? "video/mp4";
      final fileLength = await videoFile.length();

      // Step 1: Start resumable upload
      final startUploadResponse = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/upload/v1beta/files"),
        headers: {
          "x-goog-api-key": apiKey,
          "X-Goog-Upload-Protocol": "resumable",
          "X-Goog-Upload-Command": "start",
          "X-Goog-Upload-Header-Content-Length": fileLength.toString(),
          "X-Goog-Upload-Header-Content-Type": mimeType,
          "Content-Type": "application/json",
        },
        body: convert.jsonEncode({
          "file": {"display_name": "VIDEO"}
        }),
      );

      final uploadUrl = startUploadResponse.headers["x-goog-upload-url"];
      if (uploadUrl == null) {
        return "Failed to get upload URL.";
      }

      // Step 2: Upload video binary
      final videoBytes = await videoFile.readAsBytes();
      final uploadResponse = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          "X-Goog-Upload-Command": "upload, finalize",
          "X-Goog-Upload-Offset": "0",
          "Content-Length": fileLength.toString(),
        },
        body: videoBytes,
      );

      if (uploadResponse.statusCode != 200) {
        return "Video upload failed: ${uploadResponse.body}";
      }

      final fileInfo = convert.jsonDecode(uploadResponse.body);
      final fileUri = fileInfo["file"]?["uri"];
      final fileName = fileInfo["file"]?["name"];
      if (fileUri == null || fileName == null) {
        return "Upload failed: No file URI.";
      }

      // Step 3: Poll until file is ACTIVE
      while (true) {
        final statusResponse = await http.get(
          Uri.parse("https://generativelanguage.googleapis.com/v1beta/$fileName"),
          headers: {"x-goog-api-key": apiKey},
        );

        final statusJson = convert.jsonDecode(statusResponse.body);
        final state = statusJson["state"];
        if (state == "ACTIVE") break;
        if (state == "FAILED") return "File processing failed.";
        await Future.delayed(Duration(seconds: 5));
      }

      // Step 4: Generate content from video
      final generateResponse = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/interactions"),
        headers: {
          "x-goog-api-key": apiKey,
          "Content-Type": "application/json",
        },
        body: convert.jsonEncode({
          "model": "gemini-3.5-flash",
          "input": [
            {"type": "video", "uri": fileUri, "mime_type": mimeType},
            {"type": "text", "text": prompt}
          ]
        }),
      );

      if (generateResponse.statusCode == 200) {
        final jsonData = convert.jsonDecode(generateResponse.body);
        final steps = jsonData["steps"];
        if (steps != null && steps.isNotEmpty) {
          final content = steps[0]["content"];
          if (content != null && content.isNotEmpty) {
            return content[0]["text"];
          }
        }
        return "No response content.";
      }

      return "Failed to generate content: ${generateResponse.body}";

  }
}
