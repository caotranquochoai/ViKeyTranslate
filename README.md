# ViKeyTranslate (trước đây là Keyboard Translator)

Một tiện ích dịch thuật nhanh chóng, trực quan, hỗ trợ đa nền tảng (Desktop & Android). Cho phép bạn gọi cửa sổ dịch thuật mọi lúc mọi nơi để phá bỏ rào cản ngôn ngữ.

## Tính năng nổi bật

- **Tích hợp Google Analytics (GA4)**: Theo dõi hoạt động thông minh, đa nền tảng.
- **Phím tắt toàn cục (Desktop)**:
  - `Ctrl + Alt + T`: Nhanh chóng bật/tắt Cửa sổ dịch.
  - `Ctrl + Alt + Q`: Thoát hoàn toàn ứng dụng (Khắc phục lỗi chạy ngầm).
- **Cửa sổ nổi thông minh (Android Overlay)**: 
  - Mở cửa sổ ngay trên bề mặt các ứng dụng khác. 
  - Tích hợp tính năng cuộn nội dung tự động để tránh lỗi che khuất bàn phím (Bottom Overflow).
- **Trải nghiệm Đa Dịch vụ (Multi-provider Engine)**:
  - Google Translate (Miễn phí, không cần API Key).
  - Gemini API (AI thông minh, cho phép tùy chỉnh System Prompt linh hoạt).
  - Tương thích chuẩn OpenAI (Llama, GPT, DeepSeek, v.v., tùy chỉnh Base URL và API Key).
- **Tùy chỉnh cá nhân hóa chuyên sâu**:
  - Giao diện Setting cho phép cấu hình API Key, URL, tên Model, và thiết lập mẫu thao tác (Prompt).
  - Tùy chỉnh minh bạch: Độ trong suốt (Opacity) và Kích thước (Width, Height) của Cửa sổ nổi trên Android.
- **Tự động Snapshot**: Các thay đổi tùy chỉnh của bạn sẽ được lưu giữ nguyên vẹn (`shared_preferences`) cho mỗi ca làm việc tiếp theo.

## Hướng dẫn kết nối Thiết bị
   **Cập nhật thư viện**: 
   ```sh
   flutter pub get
   ```
### Desktop (Windows, macOS, Linux)

1. **Khởi chạy ứng dụng**:
   ```sh
   flutter run -d windows
   ```
2. **Kích hoạt Dịch thuật**:
   - Ấn nhấn `Ctrl + Alt + T`. Cửa sổ nổi sẽ hiện ra bất chấp bạn đang mở phần mềm nào.
   - Nhập từ ngữ, văn bản. Sau khi ấn `Enter`, hệ thống sẽ tự dịch và **auto-copy** kết quả vào Clipboard cho bạn Dán (Paste) ở nơi khác lập tức.
3. **Mở Menu Cài đặt**:
   - Click vào biểu tượng bánh răng bên trong góc Overlay.

### Android (Phiên bản không ổn định)

1. **Biên dịch File cài đặt (APK)**:
   ```sh
   flutter build apk --release
   ```
   Tệp APK sẽ xuất hiện tại `build/app/outputs/flutter-apk/app-release.apk`.
   
2. **Cấp quyền Hiển thị (Draw over other apps)**:
   - Trong lần đầu khởi chạy lúc cài đặt xong, bạn bắt buộc phải cấp quyền **Hiển thị trên các ứng dụng khác**. Nếu thiết bị chặn pop-up, bạn hãy mở `Cài đặt > Ứng dụng > ViKeyTranslate > Quyền > Hiển thị trên ứng dụng khác`.

3. **Thao tác Dịch**:
   - Bạn khởi động app, bấm **"Bật cửa sổ dịch"**.
   - Cửa sổ bong bóng được hiển thị bên trên. Bạn chạm vào nó để xuất hiện Form nhập chữ. Quá trình dịch đã xử lý thông minh để bàn phím không bị lấn lướt lên trên khung nội dung.
   - **Lưu ý Thao tác Sao chép (Copy) trên Android Overlay**: Do chính sách bảo mật ứng dụng chạy nền cứng rắn của phiên bản Android 10+, **Nút Copy tích hợp trên Cửa sổ nổi hiện không hoạt động**. Thay vào đó, bạn hãy tác động thủ công bằng cách **ấn giữ (long press) trực tiếp vào dòng chữ kết quả**, sau đó bôi đen tùy ý độ dài và sử dụng chức năng "Sao chép" (Copy) từ Thanh Công Cụ hiển thị mặc định của Điện Thoại.

## Hướng dẫn Build Release cho Windows (.msix / .exe)

### 1. Build File thực thi trực tiếp (.exe)
Cách đơn giản nhất để tạo ra tệp chạy độc lập (Portable EXE) không cần cấp quyền cài đặt:
```sh
flutter build windows
```
Đường dẫn File trích xuất: `build/windows/x64/runner/Release/keyboard_translator.exe`

### 2. Đóng gói mã nguồn thành MSIX Installer
Dự án có đi kèm gói Cấu hình đóng gói nhanh Microsoft Installer để phân phối chuyên nghiệp:

```sh
flutter pub get
flutter pub run msix:create
```

Đường dẫn File trích xuất: `build/windows/x64/runner/Release/keyboard_translator.msix`

## Cấu trúc Core (Dành riêng cho Dev)

- Thay vì thiết kế tách rẽ luồng Mobile & Desktop trong 2 nhánh dự án, chúng tôi sử dụng kỹ thuật **Conditional Import (`lib/services/analytics_service.dart`)**:
  - Các cấu hình Firebase C++ Native được đóng gói kĩ vào thiết bị di động (Nơi Flutter Engine tương thích mạnh với Plugin Gradle).
  - Code PC được điều tiết định tuyến (Proxy) tự động vượt qua SDK mà thay vào bằng HTTP Measurement Request, cho phép Máy tính hoàn thiện Compile MSVC mà không chạm mặt lỗi Missing Library lừng danh của Firebase C++ (`LNK2019`).
- `lib/settings_page.dart`: Giao diện tinh chỉnh.
- `lib/services/`: Khối Xử lý Dịch Thuật Đa luồng (API Wrapper, HTTP Client).

## Tác giả & Đóng góp

Ứng dụng **ViKeyTranslate** được phát triển và bảo trì bởi **VivuCloud**. 
- **Phiên bản hiện tại**: 1.0
- **Liên hệ hỗ trợ / Góp ý**: [VivuCloud Facebook Fanpage](https://www.facebook.com/VivuCloud)

Mọi đóng góp về mặt tính năng hay báo cáo lỗi đều rất được hoan nghênh để giúp ứng dụng ngày càng hoàn thiện hơn!
