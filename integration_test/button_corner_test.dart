import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// How far the visible corner curve runs along the top edge, and the gap on the diagonal, as % of the width.
/// Drawn on the device, since the continuous (superellipse) corner is only drawn as such by the device renderer;
/// a plain `flutter test` draws it as an ordinary circular corner.
Future<(double, double)> measureCorner(WidgetTester tester, ShapeBorder shape, double width, String name) async {
  const scale = 10.0;
  final key = GlobalKey();
  await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Align(alignment: Alignment.topLeft,
    child: RepaintBoundary(key: key, child: Container(width: width, height: width,
      decoration: ShapeDecoration(color: Colors.black, shape: shape))))));
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await boundary.toImage(pixelRatio: scale);
  final raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  const dir = String.fromEnvironment('CORNER_SCREENSHOT_DIR');
  if (dir.isNotEmpty) {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$dir/$name.png').writeAsBytes(png!.buffer.asUint8List());
  }
  final px = image.width;
  int alpha(int x, int y) => raw.getUint8((y * px + x) * 4 + 3);
  var edge = 0;
  while (edge < px ~/ 2 && alpha(edge, 0) < 128) {
    edge++;
  }
  var diag = 0;
  while (diag < px ~/ 2 && alpha(diag, diag) < 128) {
    diag++;
  }
  return (edge / px * 100, diag / px * 100);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the buttons' continuous corner really is drawn as one on the device", (tester) async {
    // 874pt and 667pt button widths; the radius ratio matches floatingButtonRadius()
    for (final (width, tag) in [(874 * 0.07, '874'), (667 * 0.07, '667')]) {
      final radius = width * 0.2237;
      final before = await measureCorner(tester, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))), width, 'before_$tag');
      final circular = await measureCorner(tester, RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)), width, 'circular_$tag');
      final continuous = await measureCorner(tester, RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)), width, 'continuous_$tag');
      debugPrint("CORNER $tag width=${width.toStringAsFixed(1)} "
        "before(circular 16pt) edge=${before.$1.toStringAsFixed(1)}% diag=${before.$2.toStringAsFixed(1)}% | "
        "circular 22.37% edge=${circular.$1.toStringAsFixed(1)}% diag=${circular.$2.toStringAsFixed(1)}% | "
        "continuous 22.37% edge=${continuous.$1.toStringAsFixed(1)}% diag=${continuous.$2.toStringAsFixed(1)}%");
      // A continuous corner leaves the straight edge earlier than a circular one of the same radius
      expect(continuous.$1, greaterThan(circular.$1), reason: "$tag: the corner was drawn as a plain circular arc");
    }
  });
}
