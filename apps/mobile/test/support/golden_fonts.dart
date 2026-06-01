import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Offline-safe google_fonts support for golden tests.
///
/// MoodBloom's design system renders copy through `MbFonts.nunito` /
/// `MbFonts.fraunces`, which delegate to `GoogleFonts.*`. Those families
/// are normally fetched over HTTP at runtime (they are NOT bundled
/// pubspec assets), so in an offline test environment the fetch either
/// hangs on a network retry or throws an async "font not found" error
/// that fails the golden even though the frame painted fine.
///
/// [installOfflineGoogleFonts] removes the network dependency entirely:
///   1. `allowRuntimeFetching = false` - google_fonts never hits HTTP.
///   2. The `flutter/assets` channel is mocked so that every Nunito /
///      Fraunces `*.ttf` variant google_fonts probes for resolves to a
///      real local TTF (the Flutter SDK's bundled Roboto). google_fonts'
///      asset-load path performs NO hash check (only the HTTP path
///      does), so any valid TTF satisfies it and the family loads
///      cleanly with zero throw and zero network.
///
/// Glyphs render as Roboto rather than the real Nunito/Fraunces, so the
/// committed baselines are generated against Roboto. That is a
/// deliberate, fully deterministic, platform-independent choice (the SDK
/// ships the same Roboto everywhere, including Linux CI), and the
/// tolerant comparator in `flutter_test_config.dart` (<=4%) absorbs any
/// residual sub-pixel skew. Call once at the top of a golden test's
/// `main`.
void installOfflineGoogleFonts() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final roboto = _loadLocalRobotoBytes();
  if (roboto == null) return;

  // google_fonts matches an asset whose path ENDS WITH the family's API
  // filename prefix (e.g. `Nunito-Regular`). One TTF key per family +
  // weight/style covers every variant the design system requests.
  const families = <String>['Nunito', 'Fraunces'];
  const variants = <String>[
    'Regular',
    'Italic',
    'Medium',
    'MediumItalic',
    'SemiBold',
    'SemiBoldItalic',
    'Bold',
    'BoldItalic',
    'ExtraBold',
    'Black',
  ];
  final fontKeys = <String>{
    for (final family in families)
      for (final variant in variants) 'assets/fonts/$family-$variant.ttf',
  };

  final manifestEntries = <Object?, Object?>{
    for (final key in fontKeys)
      key: <Object?>[
        <Object?, Object?>{'asset': key},
      ],
  };
  final manifestBytes = const StandardMessageCodec().encodeMessage(
    manifestEntries,
  );

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // The asset channel speaks raw keys (UTF-8) -> raw bytes. We answer
  // the manifest + our font keys and return null for everything else so
  // the framework's default asset loader handles real assets.
  messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;
    final key = utf8Decode(message);
    if (key == 'AssetManifest.bin') {
      return manifestBytes;
    }
    if (fontKeys.contains(key)) {
      return ByteData.view(roboto.buffer, roboto.offsetInBytes, roboto.length);
    }
    return null;
  });
}

/// Decodes a raw asset-channel key message (a UTF-8 string with no codec
/// framing) into a Dart string.
String utf8Decode(ByteData data) {
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  return String.fromCharCodes(bytes);
}

/// Best-effort lookup of a real Roboto TTF shipped with the local
/// Flutter SDK, so the shim never depends on the network or a
/// checked-in binary.
Uint8List? _loadLocalRobotoBytes() {
  final root = _flutterRoot();
  if (root == null) return null;
  final candidates = <String>[
    '$root/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto/'
        'Roboto-Regular.ttf',
    '$root/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file.readAsBytesSync();
  }
  // Fall back to scanning the material_fonts artifact dir.
  final artifacts = Directory('$root/bin/cache/artifacts/material_fonts');
  if (artifacts.existsSync()) {
    for (final entity in artifacts.listSync(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.ttf')) {
        return entity.readAsBytesSync();
      }
    }
  }
  return null;
}

/// Resolves the Flutter SDK root from the running executable. The golden
/// suite runs under `flutter_tester.exe`
/// (`<flutter>/bin/cache/artifacts/engine/<host>/flutter_tester[.exe]`),
/// while a plain `dart test` runs under
/// `<flutter>/bin/cache/dart-sdk/bin/dart[.exe]`. Both share the
/// `/bin/cache` boundary, so split there.
String? _flutterRoot() {
  final exe = Platform.resolvedExecutable.replaceAll('\\', '/');
  const marker = '/bin/cache';
  final idx = exe.indexOf(marker);
  if (idx < 0) return null;
  return exe.substring(0, idx);
}
