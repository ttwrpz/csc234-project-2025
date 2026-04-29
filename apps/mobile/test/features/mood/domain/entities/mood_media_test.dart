import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_media.dart';

void main() {
  group('MoodMedia', () {
    const a = MoodMedia(
      localPath: '/tmp/photo.jpg',
      kind: MoodMediaKind.image,
      sizeBytes: 1024,
      mimeType: 'image/jpeg',
    );

    test('value equality holds for identical fields', () {
      const b = MoodMedia(
        localPath: '/tmp/photo.jpg',
        kind: MoodMediaKind.image,
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
      );
      expect(a, equals(b));
    });

    test('copyWith replaces only the named field', () {
      final b = a.copyWith(sizeBytes: 2048);
      expect(b.sizeBytes, 2048);
      expect(b.localPath, a.localPath);
      expect(b.mimeType, a.mimeType);
      expect(b.kind, a.kind);
    });

    test('video kind round-trips through copyWith', () {
      final b = a.copyWith(kind: MoodMediaKind.video, mimeType: 'video/mp4');
      expect(b.kind, MoodMediaKind.video);
      expect(b.mimeType, 'video/mp4');
    });
  });
}
