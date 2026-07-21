import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'services/segmentation_service.dart';

void main() => runApp(const BgRemoverApp());

class BgRemoverApp extends StatelessWidget {
  const BgRemoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BG Remover',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _segmentationService = SegmentationService();
  final _picker = ImagePicker();

  bool _busy = false;
  String? _resultPath;
  String _status = '';

  Future<void> _pickAndProcessImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _busy = true;
      _status = 'Removing background…';
      _resultPath = null;
    });

    try {
      final bytes = await File(picked.path).readAsBytes();
      final original = img.decodeImage(bytes)!;
      final mlInput = InputImage.fromFilePath(picked.path);

      final matted = await _segmentationService.removeBackground(original, mlInput);

      final outDir = await getApplicationDocumentsDirectory();
      final outPath = p.join(outDir.path, 'bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(outPath).writeAsBytes(img.encodePng(matted));

      setState(() {
        _resultPath = outPath;
        _status = 'Done — exported at ${matted.width}x${matted.height}';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndProcessVideo() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Video background removal is temporarily disabled — the underlying '
          'library it depended on was discontinued. Photo removal below still '
          'works fully.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _segmentationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Background Remover')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_resultPath != null && _resultPath!.endsWith('.png'))
                Image.file(File(_resultPath!), height: 240),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_busy) const CircularProgressIndicator(),
              if (!_busy) ...[
                ElevatedButton.icon(
                  onPressed: _pickAndProcessImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Remove background from photo'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickAndProcessVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Remove background from video'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
