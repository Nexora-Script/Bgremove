import 'dart:typed_data';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;

class SegmentationService {
  final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
    enableRawSizeMask: true,
  );

  Future<img.Image> removeBackground(img.Image original, InputImage mlInput) async {
    final mask = await _segmenter.processImage(mlInput);
    if (mask == null) {
      throw Exception('Segmentation failed — no mask returned for this image.');
    }

    final width = original.width;
    final height = original.height;

    final result = img.Image.from(original);
    if (!result.hasAlpha) {
      result.convert(numChannels: 4);
    }

    final maskW = mask.width;
    final maskH = mask.height;
    final confidences = mask.confidences;

    for (int y = 0; y < height; y++) {
      final my = (y * maskH / height).floor().clamp(0, maskH - 1);
      for (int x = 0; x < width; x++) {
        final mx = (x * maskW / width).floor().clamp(0, maskW - 1);
        final confidence = confidences[my * maskW + mx];

        final pixel = result.getPixel(x, y);
        final alpha = (confidence * 255).round().clamp(0, 255);

        result.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), alpha);
      }
    }

    return result;
  }

  void dispose() {
    _segmenter.close();
  }
}
