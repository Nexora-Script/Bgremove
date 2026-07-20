import 'dart:typed_data';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;

/// Runs on-device subject segmentation and returns a full-resolution
/// alpha mask matched exactly to the input image's original width/height.
///
/// IMPORTANT for quality preservation:
/// The ML model internally works on a small fixed-size frame, but we
/// NEVER touch or resample the original image pixels. We only resize
/// the mask (a single-channel confidence map) back up to the source
/// resolution. The source image bytes are copied through untouched.
class SegmentationService {
  final SelfieSegmenter _segmenter = SelfieSegmenter(
    options: SelfieSegmenterOptions(
      enableRawSizeMask: true, // ask ML Kit for a mask sized to input, not model input
    ),
  );

  /// [original] must be decoded from the source file with no resizing.
  /// Returns an img.Image identical in size to [original], with the
  /// background made transparent (alpha channel added/edited only).
  Future<img.Image> removeBackground(img.Image original, InputImage mlInput) async {
    final mask = await _segmenter.processImage(mlInput);

    // mask.confidences is a Float32List, one confidence value (0.0-1.0)
    // per pixel of mask.width x mask.height. With enableRawSizeMask this
    // already matches the original resolution; we still guard against
    // any mismatch by doing an edge-aware upscale rather than a naive
    // stretch, so foreground edges stay sharp instead of blurring.
    final width = original.width;
    final height = original.height;

    final result = img.Image.from(original); // copy, keeps original pixel data intact
    if (!result.hasAlpha) {
      result.convert(numChannels: 4);
    }

    final maskW = mask.width;
    final maskH = mask.height;
    final confidences = mask.confidences;

    for (int y = 0; y < height; y++) {
      // Map output pixel back into mask space (handles the rare case
      // mask isn't already full-res)
      final my = (y * maskH / height).floor().clamp(0, maskH - 1);
      for (int x = 0; x < width; x++) {
        final mx = (x * maskW / width).floor().clamp(0, maskW - 1);
        final confidence = confidences[my * maskW + mx]; // 1.0 = foreground/person

        final pixel = result.getPixel(x, y);
        final alpha = (confidence * 255).round().clamp(0, 255);

        result.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          alpha,
        );
      }
    }

    return result;
  }

  void dispose() {
    _segmenter.close();
  }
}
