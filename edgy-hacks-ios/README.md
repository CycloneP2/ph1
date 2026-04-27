# EDGY HACKS - MLBB iOS Mod Menu

Premium iOS Mod Menu for Mobile Legends: Bang Bang. Supports both Jailbroken and Non-Jailbroken (Sideloaded) environments.

## Features
- **ESP Player**: Real-time position tracking with HP and Hero Name.
- **ESP Monster**: Focused on Lord, Turtle, and Buffs (Filtered by ID).
- **Snaplines**: Tactical lines from screen center to targets.
- **Anti-Report**: DNS Bypass for report logging.
- **Draggable UI**: Smooth floating action button and modern menu.
- **Stability**: ARM64 optimized memory validation and pointer safety.

## Repository Structure
- `.github/workflows/`: Automated CI/CD for building DEB/DYLIB.
- `tweak/`: Main source code and build files.
- `tweak/Titanox/`: Hooking framework for non-jailbroken devices.

## Build Instructions (GitHub Actions)
1. Fork this repository.
2. Go to **Actions** tab.
3. Select **Build EDGY Hacks Tweak**.
4. Click **Run workflow** and choose your target (`jailbreak`, `sideload`, or `both`).
5. Download the artifacts from the workflow run.

## Offsets (Current Version)
- **UnityFramework Base**: Dynamic
- **BattleManager Instance**: `0xADC8A0` (Static Pointer)
- **Entity Position**: `0x310` (Vector3)
- **Entity HP**: `0x1AC`

## Disclaimer
This project is for educational purposes only. Use at your own risk.
