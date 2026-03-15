
Player (Zig + SDL3 + FFmpeg)

A tiny cross‑platform media player written in **Zig** that can:

* Open and play video files (MP4, MKV, …) using **FFmpeg** (`avformat`, `avcodec`, `avutil`).
* Display the video in a window created with **SDL3** (`SDL3`).
* Render frames with a simple software pipeline (no GPU shaders – just raw pixel blitting).

The project is deliberately minimal so you can see exactly how the pieces fit together:

```
project_root/
├─ src/
│   ├─ main.zig                # entry point
│   ├─ platform/
│   │   └─ window.zig          # SDL window / render loop
│   ├─ ffmpeg/
│   │   └─ … (FFmpeg bindings)
│   └─ ...                     # other modules (ffmpeg, utils, …)
├─ vendor/
│   └─ ffmpeg/                 # pre‑built FFmpeg binaries (optional)
├─ build.zig                   # Zig build script
└─ README.md
```

---

## 📦 Prerequisites

| Platform | What you need |
|----------|---------------|
| **macOS (aarch64)** | - Homebrew <br> `brew install ffmpeg pkg-config zig` |
| **Linux** | - Your distro’s packages (`ffmpeg`, `libsdl3-dev`, `pkg-config`, `zig`) |
| **Windows** | - Download the **SDL3** development libraries (DLL + headers) and the **FFmpeg** binaries, then add them to your `PATH`/`PKG_CONFIG_PATH`. <br> (Or use the bundled `vendor/` folder – see below.) |

> **Tip:** If you are on macOS, the simplest way is `brew install ffmpeg pkg-config zig`.  
> On Ubuntu/Debian: `sudo apt install ffmpeg libsdl3-dev pkg-config zig`.

---

## 📂 Project Layout

```
project_root/
├─ src/
│   ├─ main.zig                # entry point – starts the app
│   ├─ platform/
│   │   └─ window.zig          # SDL window + render loop
│   ├─ ffmpeg/
│   │   └─ … (FFmpeg bindings) # auto‑generated bindings to libav*
│   └─ …                       # other helper modules
├─ vendor/
│   └─ ffmpeg/                 # (optional) pre‑built FFmpeg libs + headers
├─ build.zig                   # Zig build script – fetches & builds everything
└─ README.md
```

*If you **don’t** want to vendor FFmpeg, you can rely on the system‑wide installation (`/opt/homebrew/lib`, `/opt/homebrew/include` on macOS, or the standard library paths on Linux). The build script will automatically pick them up.*

---

## 🚀 Building & Running

### 1. Clone / fetch the repository

```bash
git clone https://github.com/by965738071/media_player.git
cd media_player
```

> The repository ships a **pre‑generated** `ffmpeg` binding (`ffmpeg-7.1`) and a **pre‑compiled** FFmpeg binary in `vendor/ffmpeg/`.  
> If you prefer to use a system‑wide FFmpeg, just delete the `vendor/` folder – the build script will fall back to the system installation.

### 2. Build the executable

```bash
zig build
```

*What happens?*  

* The build script downloads/compiles the FFmpeg source (if you kept the `vendor/` folder).  
* It compiles the FFmpeg bindings into a static library (`libffmpeg_lib`).  
* It compiles your Zig sources (`src/**/*.zig`).  
* It links everything together, producing `./zig-out/bin/media_player` (or just `media_player` on macOS/Linux).

### 3. Run the player

```bash
zig build run
```

You should see a window appear. Drop a video file onto the window or run:

```bash
./zig-out/bin/media_player path/to/your_video.mp4
```

The player will open the file, decode it with FFmpeg, and display it in the SDL window.

---

## 📂 Using the vendored FFmpeg (optional but recommended for portability)

If you want the project to be **self‑contained** (no system‑wide FFmpeg required):

1. **Download a pre‑built FFmpeg build** for your platform.  
   * macOS (aarch64) example:  
     ```bash
     curl -L -o ffmpeg.zip https://evermeet.cx/ffmpeg/ffmpeg-6.1-full_build-aarch64-osx.zip
     unzip ffmpeg.zip -d vendor/ffmpeg
     ```
   * Linux: grab the `tar.xz` from your distro’s repository or from https://ffmpeg.org/download.html.

2. **Make sure the folder layout matches**  

```
vendor/
└─ ffmpeg/
    ├─ include/          ← contains FFmpeg headers (e.g. libavformat, libavcodec …)
    └─ lib/
        ├─ macos/         ← libavformat.dylib, libavcodec.dylib, libavutil.dylib …
        └─ linux/         ← libavformat.so, libavcodec.so, libavutil.so
        └─ windows/       ← *.dll / .lib files (if on Windows)
```

3. **Re‑run the build**  

```bash
zig build
```

Now the build script will **link directly against the vendored libraries** – no system‑wide FFmpeg installation required.

---

## 🛠️ Build Script Overview (`build.zig`)

| Step | What it does |
|------|--------------|
| **Add include dirs** | Adds `/opt/homebrew/include` (macOS) or the `vendor/ffmpeg/include` path so the compiler can find `SDL3/SDL.h` and FFmpeg headers. |
| **Add library path** | Adds the corresponding `vendor/<platform>/` folder to the linker’s search path. |
| **Link libraries** | Calls `linkSystemLibrary("SDL3")` and `linkSystemLibrary("avformat")`, `linkSystemLibrary("avcodec")`, `linkSystemLibrary("avutil")` (plus `pthread`/`m` on *nix). |
| **Link the generated FFmpeg library** | `exe.linkLibrary(ffmpeg_lib);` – this is the static library built from the FFmpeg source (or the pre‑compiled `.a/.dylib` you vendored). |
| **Run‑step** | `b.addRunArtifact(exe);` lets you use `zig build run` to execute the program directly. |

If you prefer to **skip the vendored FFmpeg** and use the system‑wide installation, just delete the `vendor/` folder and the script will automatically pick up the system libraries (provided they are in the standard search paths).

---

## 📂 Running the Sample

```bash
# 1️⃣ Build
zig build

# 2️⃣ Run – pass a video file as an argument
./zig-out/bin/media_player path/to/sample.mp4
```

If you omit the argument, the player will try to open a sample file located at `media/sample.mp4` (you can create this folder yourself).

---

## 🛠️ Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-------|
| `error: Library 'SDL3' not found` | SDL3 not installed or not in the default search path. | Install via Homebrew (`brew install sdl3`) **or** place the `.dylib`/`.so`/`.dll` in `vendor/<platform>/` and the build script will find it. |
| `cannot find -lavformat` / `undefined reference to avformat` | FFmpeg libraries not found. | Ensure FFmpeg is installed (`brew install ffmpeg`) **or** copy the vendor libraries into `vendor/<platform>/` and rebuild. |
| `undefined reference to SDL_CreateWindow` | SDL headers not found. | Verify `addIncludeDir("/opt/homebrew/include")` (macOS) or the appropriate include path for your platform. |
| `runtime: undefined symbol: _printf` (or other libc symbols) | Linking against the wrong C library (e.g., mixing macOS and Linux libs). | Make sure you are building **only for your target platform** (macOS → use the macOS Zig binary). |
| `process exited with error code 1` (no further details) | Usually a missing symbol or a missing library. Check the console output for the exact missing symbol and install the corresponding package. | |

---

## 📂 Directory Layout (visual)

```
media_player/
├─ src/
│   ├─ main.zig                 # entry point
│   ├─ platform/
│   │   └─ window.zig           # window creation + render loop
│   ├─ ffmpeg/
│   │   └─ ... (auto‑generated bindings)
│   └─ ...                      # other modules
├─ vendor/
│   └─ ffmpeg/
│       ├─ include/            # FFmpeg headers
│   └─ lib/
│       ├─ macos/
│       │   └─ libavformat.dylib
│       └─ ...                 ← platform‑specific libs
├─ build.zig                    # build script (fetches, compiles, links)
└─ README.md
```

---

## 📚 Further Reading & Resources

| Topic | Link |
|-------|------|
| Zig language reference | https://ziglang.org/documentation/master/ |
| SDL3 official docs | https://wiki.libsdl.org/ |
| FFmpeg documentation | https://ffmpeg.org/documentation.html |
| Zig “cImport” & `@cImport` guide | https://ziglang.org/documentation/master/#C-Interop |
| Building C libraries with Zig | https://ziglang.org/documentation/master/#Building-C-Libraries |

---

## 📜 License

This project is released under the **MIT License** – see the `LICENSE` file for details.

---

## 🙏 Acknowledgements

* The **FFmpeg** project – for the powerful multimedia libraries.  
* The **SDL3** development team – for the cross‑platform windowing/input library.  
* The **Zig** community – for an amazing, safe, and fast systems language.

---

Enjoy building and playing! 🎥🚀
