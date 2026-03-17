# Issue: NASM package fails to build on Windows

## 问题描述

使用 zig 0.16.0-dev.2905 在 Windows 上构建 ffmpeg 依赖时，nasm 包编译失败。

### 错误信息

```
error: 'endian.h' file not found
# include <endian.h>
          ^~~~~~~~~~~

error: 'sys/mman.h' file not found
# include <sys/mman.h>
          ^~~~~~~~~~~~~

error: redefinition of 'vsnprintf'
int vsnprintf(char *str, size_t size, const char *format, va_list ap)
    ^
...previous definition is here
```

## 根本原因

nasm 包的 `build.zig` 在 Windows 上错误地设置了以下配置标志为 `1`（表示存在），但 Windows 并不提供这些 POSIX 头文件：

- `HAVE_ENDIAN_H = 1` - Windows 没有 `endian.h`
- `HAVE_MACHINE_ENDIAN_H = 1` - Windows 没有 `machine/endian.h`
- `HAVE_SYS_ENDIAN_H = 1` - Windows 没有 `sys/endian.h`
- `HAVE_MMAN = 1` - Windows 没有 `sys/mman.h`

## 修复方案

修改 `nasm-2.16.1-5-J30Ed9pnXADeEiehXaWUd4iLEMPwLrIv42q9X7NUFs8O/build.zig`，根据操作系统动态设置这些标志：

```zig
// 将这些行：
.HAVE_ENDIAN_H = 1,
.HAVE_MACHINE_ENDIAN_H = 1,
.HAVE_SYS_ENDIAN_H = 1,

// 修改为：
.HAVE_ENDIAN_H = have(t.os.tag != .windows),
.HAVE_MACHINE_ENDIAN_H = have(t.os.tag != .windows),
.HAVE_SYS_ENDIAN_H = have(t.os.tag != .windows),
```

其中 `have()` 是已有的辅助函数：
```zig
fn have(c: bool) ?c_int {
    return if (c) 1 else null;
}
```

---

# Issue: FFmpeg package fails to build on Windows

## 问题描述

在 Windows 上使用 zig 构建 ffmpeg 包时，出现大量编译错误。

### 错误信息

```
error: 'arpa/inet.h' file not found
#include <arpa/inet.h>

error: 'sys/mman.h' file not found
#include <sys/mman.h>

error: call to undeclared function 'fcntl'
error: use of undeclared identifier 'F_SETFD'
error: use of undeclared identifier 'FD_CLOEXEC'

error: conflicting types for 'close'
#define closesocket close
```

## 根本原因

ffmpeg 包的 `build.zig` 在 Windows 上错误地将以下 POSIX 相关的配置标志设为 `true`，但 Windows 并不提供这些头文件和函数：

- `HAVE_ARPA_INET_H = true` - Windows 没有 `arpa/inet.h`
- `HAVE_POLL_H = true` - Windows 没有 `poll.h`
- `HAVE_SYS_PARAM_H = true` - Windows 没有
- `HAVE_SYS_RESOURCE_H = true` - Windows 没有
- `HAVE_SYS_SELECT_H = true` - Windows 没有
- `HAVE_SYS_TIME_H = true` - Windows 没有
- `HAVE_SYS_UN_H = true` - Windows 没有
- `HAVE_TERMIOS_H = true` - Windows 没有
- `HAVE_UNISTD_H = true` - Windows 只有部分
- `HAVE_MMAP = true` - Windows 没有
- `HAVE_FCNTL = true` - Windows 没有
- `HAVE_X86ASM = true` - 需要 nasm，但 nasm 包在 Windows 上无法编译

## 修复方案

修改 `ffmpeg-7.0.1-9-zT7QA1qACAQoyIfPuk8EYU3Y2MefLFq84XB_pnplNh7Z/build.zig`，根据操作系统动态设置这些标志：

```zig
// 修改前：
.HAVE_ARPA_INET_H = true,
.HAVE_POLL_H = true,
.HAVE_SYS_PARAM_H = true,
.HAVE_SYS_RESOURCE_H = true,
.HAVE_SYS_SELECT_H = true,
.HAVE_SYS_TIME_H = true,
.HAVE_SYS_UN_H = true,
.HAVE_TERMIOS_H = true,
.HAVE_UNISTD_H = true,
.HAVE_MMAP = true,
.HAVE_FCNTL = true,
.HAVE_X86ASM = t.cpu.arch.isX86(),

// 修改后：
.HAVE_ARPA_INET_H = t.os.tag != .windows,
.HAVE_POLL_H = t.os.tag != .windows,
.HAVE_SYS_PARAM_H = t.os.tag != .windows,
.HAVE_SYS_RESOURCE_H = t.os.tag != .windows,
.HAVE_SYS_SELECT_H = t.os.tag != .windows,
.HAVE_SYS_TIME_H = t.os.tag != .windows,
.HAVE_SYS_UN_H = t.os.tag != .windows,
.HAVE_TERMIOS_H = t.os.tag != .windows,
.HAVE_UNISTD_H = t.os.tag != .windows,
.HAVE_MMAP = t.os.tag != .windows,
.HAVE_FCNTL = t.os.tag != .windows,
.HAVE_X86ASM = t.cpu.arch.isX86() and t.os.tag != .windows,
```

## 测试环境

- Zig version: 0.16.0-dev.2905+5d71e3051
- OS: Windows (win32)
- Target: x86_64-windows-msvc

---

# Issue: FFmpeg network.h winsock2.h 冲突

## 问题描述

在 Windows 上编译 FFmpeg 时，出现以下错误：

```
error: Please include winsock2.h before windows.h
error: conflicting types for 'close'
#define closesocket close
```

## 根本原因

`libavformat/network.h` 包含 `os_support.h`，而 `os_support.h` 在 Windows 上会包含 `windows.h`。但 Windows 的 socket 函数需要先包含 `winsock2.h`，否则会与 `windows.h` 产生冲突。

## 修复方案

修改 `ffmpeg-7.0.1-9-zT7QA1qACAQoyIfPuk8EYU3Y2MefLFq84XB_pnplNh7Z/libavformat/network.h`，在 `config.h` 之后、`os_support.h` 之前添加 winsock2.h 的条件包含：

```c
#include "config.h"

#if HAVE_WINSOCK2_H
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

#include "libavutil/error.h"
#include "os_support.h"
```

同时需要在 ffmpeg 的 `config.h` 中确保 `HAVE_WINSOCK2_H` 已定义为 1。

---

# Issue: FFmpeg os_support.h 缺少 Windows 头文件

## 问题描述

在 Windows 上编译 FFmpeg 时，出现以下错误：

```
error: call to undeclared function '_wmkdir'
DEF_FS_FUNCTION(mkdir,  _wmkdir,  _mkdir)

error: call to undeclared function '_mkdir'
DEF_FS_FUNCTION(mkdir,  _wmkdir,  _mkdir)

error: call to undeclared function '_wrmdir'
DEF_FS_FUNCTION(rmdir,  _wrmdir , _rmdir)

error: call to undeclared function '_rmdir'
DEF_FS_FUNCTION(rmdir,  _wrmdir , _rmdir)

error: conflicting types for 'close'
#define closesocket close
```

## 根本原因

ffmpeg 包的 `build.zig` 在 Windows 上将以下标志错误地设为 `false`，导致 Windows 头文件未被包含：

- `HAVE_DIRECT_H = false` - 需要 `<direct.h>` 提供 `_wmkdir`, `_mkdir`, `_wrmdir`, `_rmdir`
- `HAVE_IO_H = false` - 需要 `<io.h>`
- `HAVE_CLOSESOCKET = false` - 导致 `closesocket` 宏被定义为 `close`，与 Windows 的 `closesocket` 冲突

## 修复方案

修改 `ffmpeg-7.0.1-9-zT7QA1qACAQoyIfPuk8EYU3Y2MefLFq84XB_pnplNh7Z/build.zig`：

```zig
// 修改前：
.HAVE_DIRECT_H = false,
.HAVE_IO_H = false,
// ...
.HAVE_CLOSESOCKET = false,

// 修改后：
.HAVE_DIRECT_H = t.os.tag == .windows,
.HAVE_IO_H = t.os.tag == .windows,
// ...
.HAVE_CLOSESOCKET = t.os.tag == .windows,
```

这样 Windows 就能正确包含 `<direct.h>`、`<io.h>` 并正确处理 `closesocket` 函数。

---

# Issue: FFmpeg 更多 Windows 兼容性问题

## 问题描述

在 Windows 上编译 FFmpeg 时，出现更多错误：

```
error: unknown type name 'DXVA_PictureParameters'
error: 'compat/w32dlfcn.h' file not found
error: use of undeclared identifier 'put_pixels16_y2_mmxext'
error: call to undeclared function 'strerror_r'
error: 'dlfcn.h' file not found
error: call to undeclared function 'posix_memalign'
error: call to undeclared function 'lstat'
error: 'glob.h' file not found
```

## 根本原因

ffmpeg 包的 `build.zig` 中多个 POSIX 相关标志未考虑 Windows：

- `HAVE_LSTAT = true` - Windows 使用 `_stat`
- `HAVE_POSIX_MEMALIGN = true` - Windows 使用 `_aligned_malloc`
- `HAVE_STRERROR_R = true` - Windows 使用 `strerror_s`
- `CONFIG_AVDEVICE = true` - 需要大量 Windows 特定头文件

## 修复方案

修改 `ffmpeg-7.0.1-9-zT7QA1qACAQoyIfPuk8EYU3Y2MefLFq84XB_pnplNh7Z/build.zig`：

```zig
// 修改前：
.HAVE_LSTAT = true,
.HAVE_POSIX_MEMALIGN = true,
.HAVE_STRERROR_R = true,
// ...
.CONFIG_AVDEVICE = true,

// 修改后：
.HAVE_LSTAT = t.os.tag != .windows,
.HAVE_POSIX_MEMALIGN = t.os.tag != .windows,
.HAVE_STRERROR_R = t.os.tag != .windows,
// ...
.CONFIG_AVDEVICE = t.os.tag != .windows,
```

以及更多相关标志：
```zig
.HAVE_MEMALIGN = t.os.tag != .windows,
.HAVE_MKSTEMP = t.os.tag != .windows,
.HAVE_MMAP = t.os.tag != .windows,
.HAVE_MPROTECT = t.os.tag != .windows,
.HAVE_NANOSLEEP = t.os.tag != .windows,
.HAVE_PEEKNAMEDPIPE = t.os.tag == .windows,
.HAVE_SLEEP = t.os.tag == .windows,
.HAVE_MAPVIEWOFFILE = t.os.tag == .windows,
```

---

# Issue: FFmpeg 更多 Windows 编译错误 (GLOB, USLEEP, UNIX, D3D, MFENC)

## 问题描述

在 Windows 上编译 FFmpeg 时，出现更多错误：

```
error: 'glob.h' file not found
error: call to undeclared function 'usleep'
error: unknown type name 'DXVA_PictureParameters'
error: 'compat/w32dlfcn.h' file not found
error: 'sys/un.h' file not found
```

## 根本原因

ffmpeg 包的 `build.zig` 中更多 POSIX/Windows 特定标志未正确设置：

- `HAVE_GLOB = true` - Windows 没有 `glob.h`
- `HAVE_USLEEP = true` - Windows 使用 `Sleep()` 或其他 API
- `CONFIG_UNIX_PROTOCOL = true` - Unix domain sockets 不存在于 Windows
- D3D12VA/MFENC 源文件在 Windows 上编译但需要缺失的 Windows SDK 头文件

## 修复方案

修改 `ffmpeg-7.0.1-9-zT7QA1qACAQoyIfPuk8EYU3Y2MefLFq84XB_pnplNh7Z/build.zig`：

```zig
// 修改前：
.HAVE_GLOB = true,
// ...
.HAVE_USLEEP = true,
// ...
.CONFIG_UNIX_PROTOCOL = true,

// 修改后：
.HAVE_GLOB = t.os.tag != .windows,
// ...
.HAVE_USLEEP = t.os.tag != .windows,
// ...
.CONFIG_UNIX_PROTOCOL = t.os.tag != .windows,
```

同时需要注释掉以下在 Windows 上有问题的源文件：

```zig
// D3D 硬件加速相关文件（需要 Windows SDK 特定头文件）
//"/W/libavcodec/d3d11va.c",
//"/W/libavcodec/d3d12va_av1.c",
//"/W/libavcodec/d3d12va_decode.c",
//"/W/libavcodec/d3d12va_h264.c",
//"/W/libavcodec/d3d12va_hevc.c",
//"/W/libavcodec/d3d12va_mpeg2.c",
//"/W/libavcodec/d3d12va_vc1.c",
//"/W/libavcodec/d3d12va_vp9.c",

// Microsoft Media Foundation 编码器（需要缺失的 w32dlfcn.h）
//"/W/libavcodec/mfenc.c",

// DirectShow 捕获（需要缺失的 w32dlfcn.h）
//"/W/libavfilter/vsrc_ddagrab.c",

// Unix domain sockets（Windows 不支持）
//"libavutil/macos_kperf.c",  // macOS 专用
//"libavformat/unix.c",
```

---

# Issue: FFmpeg MMX/SSE 函数和 macOS 特定文件

## 问题描述

在 Windows 上编译 FFmpeg 时，出现以下错误：

```
error: use of undeclared identifier 'put_pixels16_y2_mmxext'
error: use of undeclared identifier 'avg_pixels16_mmxext'
...
error: 'dlfcn.h' file not found (macos_kperf.c)
```

## 根本原因

1. **MMX/SSE 函数**: 在 Windows 上由于 NASM 不可用，`.asm` 文件无法编译，导致所有 MMX/SSE 内联函数未定义。

2. **macos_kperf.c**: 这是 macOS 专用文件，需要 `dlfcn.h`，在 Windows 上不应编译。

## 修复方案

### 1. 禁用所有 x86 SIMD 功能（在 Windows 上）

修改 `ffmpeg-7.0.1-9-zT7QA1qACAQoyIfPuk8EYU3Y2MefLFq84XB_pnplNh7Z/build.zig`：

```zig
// 将所有 x86 相关 HAVE 标志添加 `and t.os.tag != .windows` 条件

// 例如：
.HAVE_MMX = have_x86_feat(t, .mmx) and t.os.tag != .windows,
.HAVE_MMXEXT = have_x86_feat(t, .mmx) and t.os.tag != .windows,
.HAVE_SSE = have_x86_feat(t, .sse) and t.os.tag != .windows,
.HAVE_SSE2 = have_x86_feat(t, .sse2) and t.os.tag != .windows,
// ... 等等

// 同样适用于 _EXTERNAL 和 _INLINE 变体
.HAVE_MMX_EXTERNAL = have_x86_feat(t, .mmx) and t.os.tag != .windows,
.HAVE_MMX_INLINE = have_x86_feat(t, .mmx) and t.os.tag != .windows,
// ...

// 以及
.HAVE_MMX2 = have_x86_feat(t, .mmx) and t.os.tag != .windows,
.HAVE_I686 = (have_x86_feat(t, .cmov) and ...) and t.os.tag != .windows,
.HAVE_I686_EXTERNAL = ... and t.os.tag != .windows,
.HAVE_I686_INLINE = ... and t.os.tag != .windows,
```

### 2. 注释掉 macOS 专用文件

```zig
//"libavutil/macos_kperf.c",
```
