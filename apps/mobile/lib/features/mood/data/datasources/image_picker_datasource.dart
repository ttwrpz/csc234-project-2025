import 'package:image_picker/image_picker.dart';

/// Thin `ImagePicker` wrapper. The repository decides when to call which
/// method based on [MoodMediaSource]; this datasource only exposes the four
/// concrete picker operations we need.
class ImagePickerDatasource {
  ImagePickerDatasource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<XFile>> pickFromGallery({required bool allowMultiple}) async {
    if (allowMultiple) {
      return _picker.pickMultiImage();
    }
    final single = await _picker.pickImage(source: ImageSource.gallery);
    return single == null ? const <XFile>[] : <XFile>[single];
  }

  Future<XFile?> takePhoto() {
    return _picker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> recordVideo() {
    return _picker.pickVideo(source: ImageSource.camera);
  }
}
