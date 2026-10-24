# Trucks & Skulls (Modern iOS 64-bit Edition)

A ground-up modern reconstruction of the classic physics destruction game **Trucks & Skulls** (originally by Appy Entertainment).
Rebuilt in Unity with modern 64-bit ARM64 support for iOS 16+ (tested on iPhone 12 Pro Max), using all **306 original levels** converted directly from `.POND` files.

---

## 📁 Project Contents

```
TrucksAndSkulls_Unity/
├── Assets/
│   ├── Scripts/
│   │   ├── LevelData.cs          # Data models matching original game
│   │   ├── LevelParser.cs        # Loads levels & episodes from StreamingAssets
│   │   ├── GamePhysics.cs        # Box2D physics simulation & part spawning
│   │   ├── StructurePart.cs      # Health, damage, explosive materials & skulls
│   │   ├── TruckProjectile.cs    # 6 truck types with special mid-air abilities
│   │   ├── TruckLauncher.cs      # Touch drag-to-aim slingshot & trajectory
│   │   ├── GameManager.cs        # Win/loss conditions, scoring & level flow
│   │   ├── CameraController.cs   # Pinch-zoom, follow truck, level bounds
│   │   ├── EpisodeSelectUI.cs    # Episode browser UI (7 original episodes)
│   │   └── LevelSelectUI.cs      # Level grid selector
│   └── StreamingAssets/
│       ├── episodes.json         # 7 original episodes
│       ├── levels_index.json     # All 306 level metadata
│       └── Levels/               # 306 converted level JSON files
├── Tools/
│   └── convert_levels.py        # Python parser for .POND files
├── codemagic.yaml               # Cloud CI build config (compiles IPA on cloud Mac)
└── README.md
```

---

## 🎮 How to Open & Play on Windows

1. Open **Unity Hub** on your Windows PC.
2. Click **Open** -> **Add project from disk**.
3. Select `C:\Users\hunter\Downloads\TrucksAndSkulls_Unity`.
4. Recommended Unity Version: **Unity 2021.3 LTS** or **Unity 2022.3 LTS**.
5. Once opened, press the **Play** button in the Unity Editor to test immediately!
   - **Click & Drag** left of the launcher to aim.
   - **Release** to launch the monster truck.
   - **Tap/Click** in flight to trigger the truck's special power (e.g. MIRV splits, Crotch Rocket nitro boosts, Bomber drops bomb).
   - Destroy all smiling skulls to win!

---

## ☁️ How to Build the iOS IPA Without a Mac (via Codemagic)

Since you don't own a Mac, **Codemagic** provides free cloud macOS build machines that will compile and sign the IPA using your Apple Developer account.

### Step 1: Create a GitHub Repository
1. Open PowerShell in `C:\Users\hunter\Downloads\TrucksAndSkulls_Unity`:
   ```powershell
   git init
   git add .
   git commit -m "Trucks and Skulls modern build"
   ```
2. Create a new repository on [GitHub.com](https://github.com) (Private is recommended).
3. Push your project to GitHub:
   ```powershell
   git remote add origin https://github.com/<your-username>/trucks-and-skulls.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Connect to Codemagic
1. Go to [codemagic.io](https://codemagic.io) and log in with your GitHub account.
2. Click **Add application**, select your `trucks-and-skulls` repository, and choose **Unity** project.
3. In **Codemagic Settings** -> **Integrations**:
   - Connect your **Apple Developer Portal** account using an **App Store Connect API key** (generate this in [appstoreconnect.apple.com](https://appstoreconnect.apple.com) under Users & Access -> Integrations -> Keys).

### Step 3: Run the Build
1. Click **Start new build** on the `unity-ios` workflow.
2. Codemagic will:
   - Spin up a cloud Mac Mini
   - Compile the Unity project
   - Sign the binary with your Apple Developer Certificate
   - Export the signed `.ipa` file.

---

## 📱 Installing the IPA on iPhone 12 Pro Max (iOS 16)

When the build finishes, you can install the `.ipa` onto your iPhone:
1. **Directly from Codemagic**: Codemagic gives you a direct install link/QR code in your email or on their web dashboard. Open it in Safari on your iPhone to install directly.
2. **Via Sideloadly / AltStore**: Download the `.ipa` from Codemagic artifacts to your Windows PC, plug in your iPhone, and install with Sideloadly.
3. **Via TrollStore**: If your iOS 16 device has TrollStore installed, simply send the `.ipa` via AirDrop or iCloud and tap **Install with TrollStore** for permanent, non-expiring installation.
