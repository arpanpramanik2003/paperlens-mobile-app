# Fixed Black Screen with Hardware Acceleration

To allow using **Hardware** or **Automatic** graphics without the black screen, I have made code-level changes and provided troubleshooting steps for the emulator's state.

## Changes Made

### 1. Defaulting to SurfaceView
Modified [AndroidManifest.xml](file:///D:/Edutation(P)/Learning-code/paperlens_app/paperlens_flutter/android/app/src/main/AndroidManifest.xml) to remove the following meta-data:
```xml
<meta-data
  android:name="io.flutter.embedding.android.RenderMode"
  android:value="texture"
/>
```
**Why this helps**: Forced `texture` mode (TextureView) often struggles with hardware acceleration in emulators, leading to a black screen. Removing this allows Flutter to use `SurfaceView`, which is the default and much more compatible with Hardware acceleration.

## Recommended Next Steps (Emulator Maintenance)

Since you want to keep **Hardware** acceleration enabled for performance, please follow these steps to clear any "stuck" graphics states:

1.  **Cold Boot the Emulator**:
    - Open **Device Manager**.
    - Click the three dots (More Actions) for your device.
    - Select **Cold Boot Now**. This forces the OS and GPU drivers to restart completely, which usually clears the black screen issue.
2.  **Verify Graphics Setting**:
    - Ensure your Graphics setting is back to **Automatic** or **Hardware - GLES 2.0**.
3.  **Wipe Data (If needed)**:
    - If it still shows black, use **Wipe Data** in the Device Manager. This is a common requirement when switching rendering modes.
