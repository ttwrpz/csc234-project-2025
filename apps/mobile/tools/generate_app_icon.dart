// Generates the MoodBloom app icon (full-bleed + adaptive foreground).
// Run: `cd apps/mobile && dart run tools/generate_app_icon.dart`.
// Output:
//   - assets/icon/app_icon.png            (1024x1024, peach bg)
//   - assets/icon/app_icon_foreground.png (1024x1024, transparent bg)
//
// Composition: peach background -> soft-mint disc -> 5 coral petals
// (rotated ovals at 72 deg intervals) -> amber center -> sage leaf
// at lower-left of the disc for the garden cue.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int _size = 1024;
final _peach = img.ColorRgb8(0xFF, 0xE4, 0xD1);
final _mint = img.ColorRgb8(0xE8, 0xF3, 0xED);
final _coral = img.ColorRgb8(0xE7, 0x7A, 0x8C);
final _amber = img.ColorRgb8(0xE8, 0xA2, 0x3B);
final _sage = img.ColorRgb8(0x5C, 0x9A, 0x78);
final _stem = img.ColorRgb8(0x4A, 0x82, 0x62);
final _transparent = img.ColorRgba8(0, 0, 0, 0);

void main() {
  final full = img.Image(width: _size, height: _size);
  img.fill(full, color: _peach);
  _drawFlower(full, withDisc: true);
  _save(full, 'assets/icon/app_icon.png');

  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(fg, color: _transparent);
  _drawFlower(fg, withDisc: false);
  _save(fg, 'assets/icon/app_icon_foreground.png');

  stdout.writeln('Wrote app_icon.png and app_icon_foreground.png');
}

void _drawFlower(img.Image canvas, {required bool withDisc}) {
  final cx = _size / 2;
  final cy = _size / 2;

  if (withDisc) {
    img.fillCircle(
      canvas,
      x: cx.toInt(),
      y: cy.toInt(),
      radius: 440,
      color: _mint,
    );
  }

  // Stem hidden behind the leaf for depth on the foreground variant.
  _drawLeaf(canvas, cx: cx - 230, cy: cy + 260);

  // 5 petals as filled rotated ovals. Each petal is centered ~180 px out
  // from the disc center along its axis.
  const petalCount = 5;
  const petalRadius = 200.0;
  const petalOffset = 200.0;
  for (var i = 0; i < petalCount; i++) {
    final angle = (math.pi * 2 / petalCount) * i - math.pi / 2;
    final px = cx + math.cos(angle) * petalOffset;
    final py = cy + math.sin(angle) * petalOffset;
    _drawRotatedEllipse(
      canvas,
      cx: px,
      cy: py,
      rx: 110,
      ry: petalRadius,
      angle: angle + math.pi / 2,
      color: _coral,
    );
  }

  img.fillCircle(
    canvas,
    x: cx.toInt(),
    y: cy.toInt(),
    radius: 110,
    color: _amber,
  );
}

// Filled ellipse rotated around its own center. The image package only
// ships axis-aligned ellipse primitives, so we rasterize by sampling
// every pixel inside the bounding box and testing the rotated-ellipse
// inequality (cos*dx+sin*dy)^2/rx^2 + (-sin*dx+cos*dy)^2/ry^2 <= 1.
void _drawRotatedEllipse(
  img.Image canvas, {
  required double cx,
  required double cy,
  required double rx,
  required double ry,
  required double angle,
  required img.Color color,
}) {
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);
  final r = math.max(rx, ry).ceil();
  final xMin = math.max(0, (cx - r).floor());
  final xMax = math.min(canvas.width - 1, (cx + r).ceil());
  final yMin = math.max(0, (cy - r).floor());
  final yMax = math.min(canvas.height - 1, (cy + r).ceil());
  for (var y = yMin; y <= yMax; y++) {
    for (var x = xMin; x <= xMax; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final rxp = (cosA * dx + sinA * dy) / rx;
      final ryp = (-sinA * dx + cosA * dy) / ry;
      if (rxp * rxp + ryp * ryp <= 1.0) {
        canvas.setPixel(x, y, color);
      }
    }
  }
}

// Tiny sage-green leaf: a tilted ellipse with a darker stem stub.
void _drawLeaf(img.Image canvas, {required double cx, required double cy}) {
  _drawRotatedEllipse(
    canvas,
    cx: cx,
    cy: cy,
    rx: 50,
    ry: 110,
    angle: -math.pi / 4,
    color: _sage,
  );
  _drawRotatedEllipse(
    canvas,
    cx: cx + 60,
    cy: cy + 60,
    rx: 8,
    ry: 80,
    angle: -math.pi / 4,
    color: _stem,
  );
}

void _save(img.Image image, String path) {
  final bytes = img.encodePng(image);
  File(path).writeAsBytesSync(bytes);
}
