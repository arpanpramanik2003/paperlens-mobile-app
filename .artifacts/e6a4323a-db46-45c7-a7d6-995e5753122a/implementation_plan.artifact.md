# Fix Black Screen on Emulator Startup (Hardware Acceleration)

Since the black screen appears during "Cold Boot" (after the Google animation) even before the app starts, this is a conflict between the Emulator's rendering engine and your PC's graphics drivers.

## User Review Required

> [!IMPORTANT]
> Since you want to keep **Hardware Acceleration** for speed, we need to change how the Emulator communicates with your GPU. The default "Automatic" setting sometimes picks an unstable path on Windows.

## Proposed Solutions (In order of effectiveness)

### 1. Force OpenGL Backend to "ANGLE" (Most Effective for Windows)
ANGLE translates OpenGL calls to DirectX, which is much more stable on Windows GPUs.

**Steps to find the setting:**
1.  **Start your Emulator** (even if it's currently showing a black screen).
2.  On the emulator's side panel (the toolbar), click the **three dots (...)** at the bottom (Extended Controls).
3.  In the new window that opens, select **Settings** on the left-hand sidebar.
4.  Click the **Advanced** tab at the top.
5.  Look for the **OpenGL ES renderer** dropdown.
6.  Change it from "Autodetect" to **ANGLE (D3D11)**.
7.  **Restart the Emulator**: You must close and start it again for the change to work.

> [!TIP]
> If you cannot see the "Advanced" tab, ensure your Emulator is updated in **SDK Manager > SDK Tools**.

### 2. Disable "Launch in Tool Window"
Sometimes the embedded emulator window in Android Studio has rendering bugs.
- **Action**:
  1. Go to **Settings > Tools > Emulator**.
  2. Uncheck **Launch in a tool window**.
  3. Restart the Emulator (it will open in a separate window).

### 3. Update Graphics Drivers
- **Action**: Ensure your Intel/NVIDIA/AMD graphics drivers are updated to the latest version. This is the #1 cause of hardware acceleration failure.

### 4. Adjust AVD Memory
The current config uses 2GB RAM. Increasing this can sometimes help the UI system initialize.
- **Action**: In Device Manager, edit the AVD, click **Show Advanced Settings**, and increase **RAM** to `4096 MB`.

## Verification Plan
1. Apply the **ANGLE** setting.
2. Perform a **Cold Boot**.
3. Verify the Android home screen appears after the Google animation.
