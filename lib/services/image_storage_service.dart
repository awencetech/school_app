abstract class ImageStorageService {
  Future<String?> uploadImage(String fileName, String mimeType, List<int> bytes);
}

class DefaultImageStorageService implements ImageStorageService {
  @override
  Future<String?> uploadImage(String fileName, String mimeType, List<int> bytes) async {
    return null;
  }
}
