import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/mood/data/repositories/mood_media_repository_impl.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_media.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';

void main() {
  group('MoodMediaRepositoryImpl.validate', () {
    MoodMedia media({
      int sizeBytes = 1024,
      String mimeType = 'image/jpeg',
    }) => MoodMedia(
      localPath: '/tmp/x.jpg',
      kind: MoodMediaKind.image,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
    );

    test('accepts a 1KB JPEG', () {
      expect(MoodMediaRepositoryImpl.validate(media()), isNull);
    });

    test('rejects a 26MB file as mediaTooLarge', () {
      final oversized = media(sizeBytes: 26 * 1024 * 1024);
      final f = MoodMediaRepositoryImpl.validate(oversized);
      expect(f, isNotNull);
      expect((f! as Object).runtimeType.toString(), '_MediaTooLarge');
    });

    test('rejects exactly 25MB (rule is strict <)', () {
      // The Storage rule is `< 25 * 1024 * 1024`, so 25MB exactly is denied.
      final atCap = media(sizeBytes: kMaxMediaBytes);
      final f = MoodMediaRepositoryImpl.validate(atCap);
      expect(f, isA<MoodFailure>());
      expect((f! as Object).runtimeType.toString(), '_MediaTooLarge');
    });

    test('accepts one byte under the cap', () {
      final justUnder = media(sizeBytes: kMaxMediaBytes - 1);
      expect(MoodMediaRepositoryImpl.validate(justUnder), isNull);
    });

    test('rejects application/pdf as mediaUnsupportedType', () {
      final pdf = media(mimeType: 'application/pdf');
      final f = MoodMediaRepositoryImpl.validate(pdf);
      expect(f, isNotNull);
      expect((f! as Object).runtimeType.toString(), '_MediaUnsupportedType');
    });

    test('rejects empty mimeType as mediaUnsupportedType', () {
      final unknown = media(mimeType: '');
      final f = MoodMediaRepositoryImpl.validate(unknown);
      expect((f! as Object).runtimeType.toString(), '_MediaUnsupportedType');
    });

    test('accepts video/mp4', () {
      expect(
        MoodMediaRepositoryImpl.validate(media(mimeType: 'video/mp4')),
        isNull,
      );
    });

    test('accepts image/png', () {
      expect(
        MoodMediaRepositoryImpl.validate(media(mimeType: 'image/png')),
        isNull,
      );
    });
  });
}
