#include "flutter_window.h"

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/base.h>

#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

namespace {
using flutter::EncodableValue;
using flutter::MethodResult;

winrt::fire_and_forget RecognizeResumeImage(
    std::vector<uint8_t> image_bytes,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  try {
    auto stream = winrt::Windows::Storage::Streams::InMemoryRandomAccessStream();
    auto writer = winrt::Windows::Storage::Streams::DataWriter(stream);
    writer.WriteBytes(image_bytes);
    co_await writer.StoreAsync();
    writer.DetachStream();
    stream.Seek(0);

    auto decoder =
        co_await winrt::Windows::Graphics::Imaging::BitmapDecoder::CreateAsync(
            stream);
    auto bitmap = co_await decoder.GetSoftwareBitmapAsync();
    auto engine =
        winrt::Windows::Media::Ocr::OcrEngine::TryCreateFromUserProfileLanguages();
    if (!engine) {
      result->Error("ocr_language_unavailable",
                    "No supported Windows OCR language is installed.");
      co_return;
    }

    auto recognition = co_await engine.RecognizeAsync(bitmap);
    result->Success(EncodableValue(winrt::to_string(recognition.Text())));
  } catch (const winrt::hresult_error& error) {
    result->Error("ocr_failed", winrt::to_string(error.message()));
  }
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  resume_ocr_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "people/resume_ocr",
          &flutter::StandardMethodCodec::GetInstance());
  resume_ocr_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "recognizeText") {
          result->NotImplemented();
          return;
        }
        const auto* bytes =
            std::get_if<std::vector<uint8_t>>(call.arguments());
        if (!bytes || bytes->empty()) {
          result->Error("invalid_image", "Image data is empty or invalid.");
          return;
        }
        RecognizeResumeImage(*bytes, std::move(result));
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  resume_ocr_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
