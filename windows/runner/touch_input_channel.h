#ifndef RUNNER_TOUCH_INPUT_CHANNEL_H_
#define RUNNER_TOUCH_INPUT_CHANNEL_H_

#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>

#include <memory>

// Detecta touch en el monitor primario y abre el Touch Keyboard (TabTip).
// Solo registrar en el engine de la ventana principal (POS).
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
RegisterTouchInputChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_TOUCH_INPUT_CHANNEL_H_
