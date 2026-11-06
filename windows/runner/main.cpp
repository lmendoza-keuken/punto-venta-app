#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  NativeBootLog("wWinMain start");

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }
  NativeBootLog("console attach done");

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  HRESULT com_hr = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  NativeBootLog(SUCCEEDED(com_hr) ? "CoInitializeEx ok"
                                  : "CoInitializeEx failed");

  flutter::DartProject project(L"data");
  // No usar RunOnSeparateThread: con desktop_multi_window tumba el proceso
  // al abrir la 2ª ventana (crash nativo, a veces sin rastro en Dart).
  // Tampoco llamar window_manager.setFullScreen — congela con el modelo
  // de hilos fusionado (flutter/flutter#176088). Usar maximize / bounds.
  NativeBootLog("DartProject ready UIThreadPolicy=default (no separate UI thread)");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  NativeBootLog(("args count=" +
                 std::to_string(command_line_arguments.size()))
                    .c_str());

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  NativeBootLog("window.Create start");
  if (!window.Create(L"Punto venta Keuken", origin, size)) {
    NativeBootLog("window.Create FAILED -> EXIT_FAILURE");
    return EXIT_FAILURE;
  }
  NativeBootLog("window.Create ok");
  window.SetQuitOnClose(true);

  NativeBootLog("message loop start");
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  NativeBootLog("message loop end / CoUninitialize");
  ::CoUninitialize();
  NativeBootLog("wWinMain exit EXIT_SUCCESS");
  return EXIT_SUCCESS;
}
