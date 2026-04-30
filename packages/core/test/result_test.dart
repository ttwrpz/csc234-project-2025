import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.fold', () {
    test('Ok runs the ok branch and returns its value', () {
      final Result<int, String> r = const Ok(7);
      final out = r.fold(ok: (v) => 'ok=$v', err: (e) => 'err=$e');
      expect(out, 'ok=7');
    });

    test('Err runs the err branch and returns its value', () {
      final Result<int, String> r = const Err('boom');
      final out = r.fold(ok: (v) => 'ok=$v', err: (e) => 'err=$e');
      expect(out, 'err=boom');
    });
  });

  group('Result.map', () {
    test('Ok maps the success value', () {
      final Result<int, String> r = const Ok(3);
      final mapped = r.map((v) => v * 2);
      expect(mapped, isA<Ok<int, String>>());
      expect((mapped as Ok<int, String>).value, 6);
    });

    test('Err passes through unchanged', () {
      final Result<int, String> r = const Err('nope');
      final mapped = r.map((v) => v * 2);
      expect(mapped, isA<Err<int, String>>());
      expect((mapped as Err<int, String>).failure, 'nope');
    });
  });

  group('Result.mapErr', () {
    test('Ok passes through unchanged', () {
      final Result<int, String> r = const Ok(5);
      final mapped = r.mapErr((e) => e.length);
      expect(mapped, isA<Ok<int, int>>());
      expect((mapped as Ok<int, int>).value, 5);
    });

    test('Err maps the failure value', () {
      final Result<int, String> r = const Err('boom');
      final mapped = r.mapErr((e) => e.length);
      expect(mapped, isA<Err<int, int>>());
      expect((mapped as Err<int, int>).failure, 4);
    });
  });

  group('Result.getOrNull', () {
    test('returns the value for Ok', () {
      final Result<int, String> r = const Ok(42);
      expect(r.getOrNull(), 42);
    });

    test('returns null for Err', () {
      final Result<int, String> r = const Err('nope');
      expect(r.getOrNull(), isNull);
    });
  });

  group('Result.errOrNull', () {
    test('returns null for Ok', () {
      final Result<int, String> r = const Ok(42);
      expect(r.errOrNull(), isNull);
    });

    test('returns the failure for Err', () {
      final Result<int, String> r = const Err('boom');
      expect(r.errOrNull(), 'boom');
    });
  });
}
