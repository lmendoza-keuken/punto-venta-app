#include "touch_input_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>

#include <vector>

namespace {

bool IsPrimaryMonitor(HMONITOR monitor) {
  if (monitor == nullptr) {
    return false;
  }
  MONITORINFO info = {};
  info.cbSize = sizeof(info);
  if (!GetMonitorInfoW(monitor, &info)) {
    return false;
  }
  return (info.dwFlags & MONITORINFOF_PRIMARY) != 0;
}

bool RectsOverlap(const RECT& a, const RECT& b) {
  return a.left < b.right && a.right > b.left && a.top < b.bottom &&
         a.bottom > b.top;
}

bool IsPrimaryDisplayTouch() {
  UINT32 count = 0;
  if (!GetPointerDevices(&count, nullptr) || count == 0) {
    // Fallback: machine-level digitizer presence (no per-monitor info).
    const int digitizer = GetSystemMetrics(SM_DIGITIZER);
    return (digitizer & NID_READY) != 0 &&
           ((digitizer & NID_INTEGRATED_TOUCH) != 0 ||
            (digitizer & NID_EXTERNAL_TOUCH) != 0);
  }

  std::vector<POINTER_DEVICE_INFO> devices(count);
  if (!GetPointerDevices(&count, devices.data())) {
    return false;
  }

  HMONITOR primary = MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO primary_info = {};
  primary_info.cbSize = sizeof(primary_info);
  const bool have_primary_rect =
      primary != nullptr && GetMonitorInfoW(primary, &primary_info);

  for (UINT32 i = 0; i < count; ++i) {
    const POINTER_DEVICE_INFO& device = devices[i];
    if (device.pointerDeviceType != POINTER_DEVICE_TYPE_TOUCH) {
      continue;
    }
    if (IsPrimaryMonitor(device.monitor)) {
      return true;
    }
    // Some drivers leave monitor unset; match by device/display rects.
    if (have_primary_rect && device.device != nullptr) {
      RECT pointer_rect = {};
      RECT display_rect = {};
      if (GetPointerDeviceRects(device.device, &pointer_rect, &display_rect) &&
          (RectsOverlap(pointer_rect, primary_info.rcMonitor) ||
           RectsOverlap(display_rect, primary_info.rcMonitor))) {
        return true;
      }
    }
  }
  return false;
}

}  // namespace

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
RegisterTouchInputChannel(flutter::FlutterEngine* engine) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "punto_venta/windows_touch_input",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "isPrimaryDisplayTouch") {
          result->Success(flutter::EncodableValue(IsPrimaryDisplayTouch()));
          return;
        }
        result->NotImplemented();
      });

  return channel;
}
