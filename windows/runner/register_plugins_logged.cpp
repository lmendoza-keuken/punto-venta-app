#include "register_plugins_logged.h"

#include <windows.h>

#include <cloud_firestore/cloud_firestore_plugin_c_api.h>
#include <desktop_multi_window/desktop_multi_window_plugin.h>
#include <firebase_auth/firebase_auth_plugin_c_api.h>
#include <firebase_core/firebase_core_plugin_c_api.h>
#include <firebase_storage/firebase_storage_plugin_c_api.h>
#include <screen_retriever_windows/screen_retriever_windows_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <window_manager/window_manager_plugin.h>

#include "utils.h"

namespace {

void LogPluginCrash(const char* name, DWORD code) {
  char buf[192];
  sprintf_s(buf, sizeof(buf), "plugin %s CRASHED seh=0x%08lX", name, code);
  NativeBootLog(buf);
}

// SEH no puede estar en funciones con objetos C++ que necesiten unwind.
void RegisterOne(
    const char* name,
    void (*register_fn)(flutter::PluginRegistry*),
    flutter::PluginRegistry* registry) {
  char start_buf[128];
  sprintf_s(start_buf, sizeof(start_buf), "plugin %s start", name);
  NativeBootLog(start_buf);

  __try {
    register_fn(registry);
  } __except (EXCEPTION_EXECUTE_HANDLER) {
    LogPluginCrash(name, GetExceptionCode());
    return;
  }

  char done_buf[128];
  sprintf_s(done_buf, sizeof(done_buf), "plugin %s done", name);
  NativeBootLog(done_buf);
}

void RegFirebaseCore(flutter::PluginRegistry* registry) {
  FirebaseCorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
}

void RegFirebaseAuth(flutter::PluginRegistry* registry) {
  FirebaseAuthPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
}

void RegCloudFirestore(flutter::PluginRegistry* registry) {
  CloudFirestorePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CloudFirestorePluginCApi"));
}

void RegFirebaseStorage(flutter::PluginRegistry* registry) {
  FirebaseStoragePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FirebaseStoragePluginCApi"));
}

void RegDesktopMultiWindow(flutter::PluginRegistry* registry) {
  DesktopMultiWindowPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopMultiWindowPlugin"));
}

void RegScreenRetriever(flutter::PluginRegistry* registry) {
  ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
}

void RegUrlLauncher(flutter::PluginRegistry* registry) {
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}

void RegWindowManager(flutter::PluginRegistry* registry) {
  WindowManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowManagerPlugin"));
}

}  // namespace

void RegisterPluginsLogged(flutter::PluginRegistry* registry) {
  NativeBootLog("RegisterPluginsLogged start");

  // firebase_core primero (el generated lo pone después de firestore).
  RegisterOne("firebase_core", RegFirebaseCore, registry);
  RegisterOne("firebase_auth", RegFirebaseAuth, registry);
  RegisterOne("cloud_firestore", RegCloudFirestore, registry);
  RegisterOne("firebase_storage", RegFirebaseStorage, registry);
  RegisterOne("desktop_multi_window", RegDesktopMultiWindow, registry);
  RegisterOne("screen_retriever", RegScreenRetriever, registry);
  RegisterOne("url_launcher", RegUrlLauncher, registry);
  RegisterOne("window_manager", RegWindowManager, registry);

  NativeBootLog("RegisterPluginsLogged done");
}
