import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AiService {
  static const String apiUrl = 'https://api.example.com/enhance';

  Future<Uint8List> enhanceImage(File imageFile) async {
    try {
      final http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(apiUrl))
            ..files.add(
              await http.MultipartFile.fromPath('image', imageFile.path),
            );

      final http.StreamedResponse response = await request.send();
      final Uint8List responseBytes = await response.stream.toBytes();

      if (response.statusCode == 200) {
        return responseBytes;
      }

      throw AiServiceException(
        'Enhancement failed (HTTP ${response.statusCode}). '
        'Please check your API and try again.',
      );
    } on SocketException {
      throw AiServiceException(
        'No internet connection. Please connect and try again.',
      );
    } on http.ClientException {
      throw AiServiceException(
        'Network error while calling enhancement API.',
      );
    } catch (_) {
      throw AiServiceException(
        'Unexpected error occurred while enhancing image.',
      );
    }
  }

  Future<String> saveEnhancedImage(Uint8List imageBytes) async {
    try {
      Directory targetDirectory;

      if (Platform.isAndroid) {
        targetDirectory =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        targetDirectory = await getApplicationDocumentsDirectory();
      }

      final String fileName =
          'enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File outputFile = File('${targetDirectory.path}/$fileName');

      await outputFile.writeAsBytes(imageBytes);
      return outputFile.path;
    } catch (_) {
      throw AiServiceException('Unable to save enhanced image.');
    }
  }
}

class AiServiceException implements Exception {
  AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}