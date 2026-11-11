#include "flutter_window.h"

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/base.h>

#include <algorithm>
#include <cwctype>
#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

namespace {
using flutter::EncodableValue;
using flutter::MethodResult;
using winrt::Windows::Globalization::Language;
using winrt::Windows::Graphics::Imaging::BitmapAlphaMode;
using winrt::Windows::Graphics::Imaging::BitmapDecoder;
using winrt::Windows::Graphics::Imaging::BitmapPixelFormat;
using winrt::Windows::Graphics::Imaging::SoftwareBitmap;
using winrt::Windows::Media::Ocr::OcrEngine;
using winrt::Windows::Storage::Streams::DataWriter;
using winrt::Windows::Storage::Streams::InMemoryRandomAccessStream;

std::wstring ExtractLines(
    const winrt::Windows::Media::Ocr::OcrResult& recognition) {
  std::wstring text;
  for (const auto& line : recognition.Lines()) {
    if (!text.empty()) text += L"\n";
    text += line.Text().c_str();
  }
  return text;
}

int ScoreRecognizedText(const std::wstring& text, bool is_italian_engine) {
  std::wstring lower;
  lower.reserve(text.size());
  int non_space = 0;
  int accented = 0;
  for (wchar_t ch : text) {
    if (!std::iswspace(ch)) ++non_space;
    if (ch > 127) ++accented;
    lower.push_back(static_cast<wchar_t>(std::towlower(ch)));
  }
  int italian_hits = 0;
  for (const wchar_t* word :
       {L"esperienza", L"competenze", L"istruzione", L"formazione",
        L"lingue", L"profilo", L"motivazione", L"anni", L"laurea", L"lavoro"}) {
    if (lower.find(word) != std::wstring::npos) ++italian_hits;
  }
  int english_hits = 0;
  for (const wchar_t* word :
       {L"experience", L"skills", L"education", L"summary", L"profile",
        L"employment", L"software", L"engineer", L"years", L"work"}) {
    if (lower.find(word) != std::wstring::npos) ++english_hits;
  }
  const int language_bonus = is_italian_engine
                                 ? (italian_hits * 40 + accented * 10)
                                 : (english_hits * 40);
  return non_space + language_bonus;
}

winrt::fire_and_forget RecognizeResumeImage(
    std::vector<uint8_t> image_bytes,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  try {
    auto stream = InMemoryRandomAccessStream();
    auto writer = DataWriter(stream);
    writer.WriteBytes(image_bytes);
    co_await writer.StoreAsync();
    writer.DetachStream();
    stream.Seek(0);

    auto decoder = co_await BitmapDecoder::CreateAsync(stream);
    auto bitmap = co_await decoder.GetSoftwareBitmapAsync(
        BitmapPixelFormat::Bgra8, BitmapAlphaMode::Ignore);

    std::vector<std::pair<OcrEngine, bool>> engines;
    if (auto en_engine = OcrEngine::TryCreateFromLanguage(Language(L"en-US"))) {
      engines.emplace_back(std::move(en_engine), false);
    }
    if (auto it_engine = OcrEngine::TryCreateFromLanguage(Language(L"it-IT"))) {
      engines.emplace_back(std::move(it_engine), true);
    }
    if (engines.empty()) {
      if (auto fallback = OcrEngine::TryCreateFromUserProfileLanguages()) {
        engines.emplace_back(std::move(fallback), false);
      }
    }
    if (engines.empty()) {
      result->Error("ocr_unavailable",
                    "No Windows OCR engine is installed on this system.");
      co_return;
    }

    std::wstring best_text;
    int best_score = -1;
    for (const auto& [engine, is_italian] : engines) {
      auto recognition = co_await engine.RecognizeAsync(bitmap);
      auto candidate = ExtractLines(recognition);
      const int score = ScoreRecognizedText(candidate, is_italian);
      if (score > best_score) {
        best_score = score;
        best_text = std::move(candidate);
      }
    }
    result->Success(EncodableValue(winrt::to_string(best_text)));
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
