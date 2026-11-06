#ifndef RUNNER_REGISTER_PLUGINS_LOGGED_H_
#define RUNNER_REGISTER_PLUGINS_LOGGED_H_

#include <flutter/plugin_registry.h>

// Igual que RegisterPlugins, pero con NativeBootLog por plugin + SEH.
void RegisterPluginsLogged(flutter::PluginRegistry* registry);

// Solo plugins de ventana para el engine de desktop_multi_window.
// Firebase en el 2º engine puede tumbar todo el proceso.
void RegisterSecondaryWindowPluginsLogged(flutter::PluginRegistry* registry);

#endif  // RUNNER_REGISTER_PLUGINS_LOGGED_H_
