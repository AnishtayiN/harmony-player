#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

bool IsWindows10OrGreater() {
  OSVERSIONINFOEX osvi = {};
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
  osvi.dwMajorVersion = 10;
  osvi.dwMinorVersion = 0;
  DWORDLONG condition = 0;
  VER_SET_CONDITION(condition, VER_MAJORVERSION, VER_GREATER_EQUAL);
  VER_SET_CONDITION(condition, VER_MINORVERSION, VER_GREATER_EQUAL);
  return VerifyVersionInfo(&osvi, VER_MAJORVERSION | VER_MINORVERSION, condition);
}

}  // namespace

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  const wchar_t* window_class =
      RegisterWindowClass(kIconName, kWindowClassName);

  DWORD window_style = WS_OVERLAPPEDWINDOW;
  DWORD extended_style = WS_EX_APPWINDOW;

  if (IsWindows10OrGreater()) {
    extended_style |= WS_EX_NOREDIRECTIONBITMAP;
  }

  HWND window = CreateWindowEx(
      extended_style, window_class, title.c_str(), window_style,
      origin.x, origin.y, size.width, size.height,
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window) {
    return false;
  }

  window_handle_ = window;
  UpdateTheme(window);
  return OnCreate();
}

bool Win32Window::Show() {
  if (window_handle_) {
    ShowWindow(window_handle_, SW_SHOWNORMAL);
    UpdateTheme(window_handle_);
    return true;
  }
  return false;
}
