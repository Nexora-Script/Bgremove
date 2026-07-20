import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'segmentation_service.dart';

class VideoProcessor {
  final SegmentationService _segmentationService = SegmentationService();

  Future<String> processVideo(
    String inputPath, {
    void Function(int done, int total)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final workDir = Directory(p.join(tempDir.path, 'bgremove_${DateTime.now().millisecondsSinceEpoch}'));
    await workDir.create(recursive: true);

    final framesDir = Directory(p.join(workDir.path, 'frames'));
    final mattedDir = Directory(p.join(workDir.path, 'matted'));
    await framesDir.create();
    await mattedDir.create();

    final probeSession = await FFmpegKit.execute('-i "$inputPath" -hide_banner');
    final probeOutput = await probeSession.getOutput() ?? '';
    final fps = _extractFps(probeOutput) ?? 30;

    final extractSession = await FFmpegKit.execute(
      '-i "$inputPath" -vsync 0 "${framesDir.path}/frame_%06d.png"',
    );
    final extractCode = await extractSession.getReturnCode();
    if (!ReturnCode.isSuccess(extractCode)) {
      throw Exception('Frame extraction failed');
    }

    final frameFiles = framesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (int i = 0; i < frameFiles.length; i++) {
      final file = frameFiles[i];
      final bytes = await file.readAsBytes();
      final decoded = img.decodePng(bytes)!;
      final mlInput = InputImage.fromFilePath(file.path);

      final matted = await _segmentationService.removeBackground(decoded, mlInput);
      final outPath = p.join(mattedDir.path, p.basename(file.path));
      await File(outPath).writeAsBytes(img.encodePng(matted));

      onProgress?.call(i + 1, frameFiles.length);
    }

    final outputPath = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'bg_removed_${DateTime.now().millisecondsSinceEpoch}.webm',
    );

    final encodeSession = await FFmpegKit.execute(
      '-framerate $fps -i "${mattedDir.path}/frame_%06d.png" '
      '-c:v libvpx-vp9 -pix_fmt yuva420p -lossless 1 "$outputPath"',
    );
    final encodeCode = await encodeSession.getReturnCode();
    if (!ReturnCode.isSuccess(encodeCode)) {
      throw Exception('Re-encode failed');
    }

    await workDir.delete(recursive: true);
    return outputPath;
  }

  double? _extractFps(String ffmpegLog) {
    final match = RegExp(r'(\d+(?:\.\d+)?) fps').firstMatch(ffmpegLog);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  void dispose() => _segmentationService.dispose();
}
