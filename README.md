# Shoe Store Marketplace Mobile App (FinalPrm)

Ứng dụng di động thương mại điện tử giày dép đa vai trò (Guest, User, Seller, Admin) phát triển bằng Flutter và Firebase.

## 📁 Cấu trúc thư mục (Architecture)

Dự án áp dụng cấu trúc **Feature-First** kết hợp mô hình **MVVM / Repository** sạch sẽ (Clean Architecture):

```text
lib/
├── core/
│   ├── theme/                  # Design tokens & Themes
│   │   ├── app_colors.dart       # Định nghĩa bảng màu (Light/Dark mode)
│   │   ├── app_spacing.dart      # Quy chuẩn margin, padding, border radius
│   │   ├── app_text_styles.dart  # Định nghĩa typography (Outfits)
│   │   └── app_theme.dart        # Kết hợp các token thành ThemeData hoàn chỉnh
│   └── widgets/                # Các components dùng chung độc lập logic
│       ├── app_button.dart       # Nút bấm tùy chỉnh (Primary, Tonal, Outlined, Text, Loading)
│       ├── app_text_field.dart   # Trường nhập liệu tùy chỉnh (Password toggle, validate)
│       ├── product_card_skeleton.dart # Skeleton loading với hiệu ứng Shimmer
│       ├── loading_view.dart     # Vòng xoay tải dữ liệu (FullScreen / Overlay)
│       ├── empty_view.dart       # Màn hình thông báo dữ liệu rỗng
│       ├── error_view.dart       # Màn hình báo lỗi tiếng Việt thân thiện có nút thử lại
│       └── confirm_dialog.dart   # Hộp thoại xác nhận hành vi
├── features/
│   └── profile/                # Feature Quản lý hồ sơ cá nhân
│       ├── domain/
│       │   └── models/
│       │       └── user_profile.dart # Immutable model đại diện cho Profile
│       ├── data/
│       │   └── repositories/
│       │       └── profile_repository.dart # Interface & Mock dữ liệu lưu trữ
│       └── presentation/
│           ├── controllers/
│           │   └── profile_controller.dart # StateNotifier quản lý trạng thái tải/lưu
│           └── views/
│               ├── profile_view.dart # Giao diện sửa thông tin & chọn avatar
│               ├── about_view.dart   # Màn hình giới thiệu thành viên & ứng dụng
│               └── help_view.dart    # Màn hình FAQ & Kênh hỗ trợ khách hàng
└── main.dart                   # Cấu hình GoRouter, ProviderScope & Showroom
```

---

## 🛠️ Hướng dẫn cài đặt & chạy ứng dụng

### 1. Yêu cầu hệ thống
* Flutter SDK (phiên bản `>= 3.12.0`)
* Android Studio / Xcode (dành cho giả lập thiết bị di động)
* Thiết bị thật Android/iOS hoặc trình duyệt Web

### 2. Các bước cài đặt
Clone repository và tải các dependencies liên quan:
```bash
# Tải các gói thư viện
flutter pub get
```

### 3. Chạy ứng dụng
Chạy ứng dụng trực tiếp bằng thiết bị kết nối hoặc giả lập:
```bash
# Chạy ở chế độ debug
flutter run
```

---

## 📋 Checklist Demo Sprint 0 (Màn hình Showroom)

Trang chủ `/` (Showroom) được thiết kế đặc biệt để hội đồng kiểm duyệt và nhóm phát triển nghiệm thu nhanh chóng:
- [x] **Light/Dark Mode Theme**: Cho phép bấm icon góc phải thanh AppBar để chuyển đổi theme real-time, kiểm tra giao diện Sleek Dark Mode.
- [x] **Accessibility (Phóng to chữ & Vùng chạm)**: Toàn bộ layout đảm bảo không vỡ khi chữ phóng to `130%` (Text Scale). Tất cả các nút bấm, icon thao tác đều tuân thủ kích thước tối thiểu `48dp` (vùng chạm chuẩn).
- [x] **Trạng thái Components**:
  - `AppButton`: Đầy đủ Primary, Secondary, Outlined, Text, Disabled, Loading (quay tròn ngăn chặn double click).
  - `AppTextField`: Trường mật khẩu tích hợp ẩn/hiện, trường báo lỗi có màu viền đỏ, trường Email chỉ đọc.
  - `ProductCardSkeleton`: Chạy thử hiệu ứng Shimmer mượt mà trên lưới ô vuông.
  - `LoadingView`: Nhấn để kích hoạt Overlay làm mờ màn hình trong 3 giây (mô phỏng tiến trình lưu server).
  - `ConfirmDialog`: Nhấn để bật Popup xác nhận hủy bỏ/thực hiện thao tác.
  - `EmptyView & ErrorView`: Bấm xem màn hình giả lập trạng thái trống hoặc mất mạng (tiếng Việt).

---

## 🧪 Kịch bản kiểm thử nhanh (Smoke Tests)

### Kịch bản 1: Cập nhật thông tin cá nhân thành công
1. Nhấn nút **"Xem"** ở Card đầu tiên trên Showroom để chuyển sang `/profile`.
2. Kiểm tra thông tin hiển thị mặc định: Họ tên là *Nguyễn Văn Hiếu*, SĐT là *0987654321*.
3. Thay đổi Tên thành *Nguyễn Văn Hiếu Edit* và SĐT thành *0987654322*.
4. Nhấn **"Lưu thay đổi"**.
5. Màn hình overlay loading xuất hiện trong `1.2 giây`, sau đó hiện thông báo Snackbar màu xanh lá cây: *"Cập nhật thông tin thành công!"*.
6. Kiểm tra xem Avatar có được hiển thị ký tự viết tắt tương ứng không.

### Kịch bản 2: Báo lỗi Validation khi để trống hoặc nhập sai định dạng
1. Vào trang `/profile`.
2. Xóa sạch ô **Họ và tên**. Nhập SĐT ít hơn 10 chữ số (Ví dụ: *123*).
3. Nhấn **"Lưu thay đổi"**.
4. Các thông báo lỗi tiếng Việt màu đỏ sẽ xuất hiện trực tiếp dưới ô nhập liệu:
   - *"Họ và tên không được để trống"*
   - *"Số điện thoại tối thiểu phải có 10 chữ số"*
5. Tiến trình lưu không được thực hiện.

### Kịch bản 3: Hủy bỏ chỉnh sửa khi chưa lưu
1. Vào trang `/profile`.
2. Sửa thông tin **Họ và tên** bất kỳ.
3. Nhấn nút **"Hủy bỏ"**.
4. Dialog xác nhận xuất hiện: *"Bạn có chắc chắn muốn hủy các thay đổi chưa lưu?"*.
5. Nhấn **"Quay lại"** -> Dialog đóng, thông tin chỉnh sửa vẫn giữ nguyên.
6. Nhấn lại **"Hủy bỏ"** -> Nhấn **"Đồng ý"** -> Dữ liệu form tự động reset về giá trị gốc gần nhất.
