// Stub file for web platform to avoid File class conflicts
// This file is only used when compiling for web

/// Stub File class for web platform
/// This class should never be instantiated on web
class File {
  final String path;
  
  File(this.path);
  
  Future<List<int>> readAsBytes() {
    throw UnsupportedError('File operations are not supported on web platform');
  }
}
