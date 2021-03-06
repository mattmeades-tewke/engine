// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit', () {
    setUpCanvasKitTest();

    // Regression test for https://github.com/flutter/flutter/issues/63715
    test('TransformLayer prerolls correctly', () async {
      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      final CkPicture picture =
          paintPicture(ui.Rect.fromLTRB(0, 0, 30, 30), (CkCanvas canvas) {
        canvas.drawRect(ui.Rect.fromLTRB(0, 0, 30, 30),
            CkPaint()..style = ui.PaintingStyle.fill);
      });

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushClipRect(ui.Rect.fromLTRB(15, 15, 30, 30));

      // Intentionally use a perspective transform, which triggered the
      // https://github.com/flutter/flutter/issues/63715 bug.
      sb.pushTransform(
          Float64List.fromList(Matrix4.identity().storage
            ..[15] = 2,
      ));

      sb.addPicture(ui.Offset.zero, picture);
      final LayerTree layerTree = sb.build().layerTree;
      dispatcher.rasterizer!.draw(layerTree);
      final ClipRectLayer clipRect = layerTree.rootLayer as ClipRectLayer;
      expect(clipRect.paintBounds, ui.Rect.fromLTRB(15, 15, 30, 30));

      final TransformLayer transform = clipRect.debugLayers.single as TransformLayer;
      expect(transform.paintBounds, ui.Rect.fromLTRB(0, 0, 30, 30));
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
