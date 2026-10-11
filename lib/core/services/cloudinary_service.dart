import 'package:cloudinary_public/cloudinary_public.dart';
import '../constants/app_constants.dart';

/// Cloudinary Service for direct unsigned image uploads
class CloudinaryService {
  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(
      AppConstants.cloudinaryCloudName,
      AppConstants.cloudinaryUploadPreset,
      cache: false,
    );
  }

  /// Uploads product image file directly to Cloudinary without backend server requirement
  Future<String?> uploadImage(String filePath) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'al_asad_traders/products',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  /// Uploads image bytes directly (for web platform support)
  Future<String?> uploadImageBytes(List<int> bytes, String fileName) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          resourceType: CloudinaryResourceType.Image,
          folder: 'al_asad_traders/products',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }
}
