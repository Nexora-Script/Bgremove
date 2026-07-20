# BG Remover — On-device background removal (image + video)

Removes the background from photos and videos entirely on-device (no internet
needed after install), and exports at the **exact same resolution** as the
source — no downscaling, no lossy re-encoding of the parts that matter.

## How quality is preserved

- The segmentation model (Google ML Kit Selfie Segmentation) only outputs a
  **mask** — the original image/video pixels are never resized or
  recompressed. We composite the mask as an alpha channel onto the untouched
  original bytes.
- Images export as **PNG** (lossless, alpha-capable) instead of JPEG.
- Video frames are extracted **losslessly**, matted individually, then
  re-encoded at the **original framerate** using VP9 + alpha in a WebM
  container (swap to ProRes 4444 / `.mov` in `video_processor.dart` if you
  need an editing-friendly format instead).

## Project setup (one-time, local machine)

```bash
flutter create --project-name bg_remover --org com.yourcompany .
# ^ generates the missing android/ and ios/ platform folders;
#   this repo only ships lib/, pubspec.yaml, and the workflow.
flutter pub get
```

Then just push to `main` — GitHub Actions builds the APK for you.

## Getting the APK

1. Push this repo to GitHub.
2. Go to the **Actions** tab → "Build APK" workflow will run automatically,
   or trigger it manually via "Run workflow".
3. Once it finishes, open the run → download the `app-release-apks` artifact.
4. Unzip it — you'll get 3 APKs split by CPU architecture (arm64-v8a covers
   almost all modern phones). Install the matching one, or `flutter build apk`
   without `--split-per-abi` for one universal file.

## Notes / next steps

- First run of the app will download ML Kit's segmentation model
  (~a few MB) from Google Play services — this happens once, then it's cached
  on-device.
- For sharper edges on complex subjects (hair, fur), consider swapping the
  ML Kit segmenter for a converted RVM (Robust Video Matting) TFLite model —
  same integration point in `segmentation_service.dart`.
- Add an app icon / signing config in `android/app/build.gradle` before a
  real release (the workflow as-is produces a debug-signed release APK,
  fine for testing/sideloading, not for Play Store).
  
