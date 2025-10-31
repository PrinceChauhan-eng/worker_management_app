import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Save image to local storage and return path
  static Future<String> _saveImage(XFile image) async {
    try {
      if (kIsWeb) {
        // For web, we need to read the image as bytes and create a data URL
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        // Return data URL that can be used in NetworkImage
        return 'data:image/jpeg;base64,$base64String';
      } else {
        // For mobile/desktop, save to app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final String localPath = path.join(appDir.path, 'images', fileName);

        // Create directory if it doesn't exist
        final Directory imageDir = Directory(path.join(appDir.path, 'images'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        // Copy file to app directory
        final File localFile = File(localPath);
        await File(image.path).copy(localFile.path);

        return localFile.path;
      }
    } catch (e) {
      print('Error saving image: $e');
      return image.path;
    }
  }

  /// Show image source selection dialog
  static Future<String?> pickImage({
    required bool fromCamera,
  }) async {
    if (fromCamera) {
      return await pickImageFromCamera();
    } else {
      return await pickImageFromGallery();
    }
  }

  /// Delete image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      if (!kIsWeb && imagePath.isNotEmpty) {
        final File file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
