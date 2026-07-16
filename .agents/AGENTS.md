# Quy tắc phát triển dự án (Project Development Rules)

## 1. Quy tắc đặt tên nhánh Git (Git Branching Rules)
Tất cả các thành viên và Coding Agent phải tuân thủ nghiêm ngặt quy tắc đặt tên nhánh sau đây:
- **Tính năng mới (Feature)**: `feature/<tên_tính_năng_hoặc_scope>`
  *Ví dụ:* `feature/customer-commerce`, `feature/ui-support-docs`, `feature/auth-setup`
- **Sửa lỗi (Bug Fix)**: `fix/<tên_lỗi_hoặc_scope>`
  *Ví dụ:* `fix/cart-duplicate-item`, `fix/avatar-upload-crash`
- **Cải tiến/Cấu hình (Chore)**: `chore/<scope_hoặc_task_name>`
  *Ví dụ:* `chore/firebase-init`, `chore/add-dependencies`
- **Tài liệu (Documentation)**: `docs/<tên_tài_liệu>`
  *Ví dụ:* `docs/update-readme`

## 2. Quy tắc Commit (Git Commits)
- Sử dụng chuẩn **Conventional Commits** để viết thông điệp commit.
- Cú pháp: `<type>(<scope>): <mô tả ngắn bằng tiếng Việt hoặc tiếng Anh>`
- Các loại `type` chính:
  - `feat`: Tính năng mới.
  - `fix`: Sửa lỗi.
  - `chore`: Cấu hình hệ thống, gradle, dependencies, assets, build tools.
  - `docs`: Cập nhật tài liệu (README, AGENTS.md, docs/).
  - `refactor`: Tái cấu trúc mã nguồn (không đổi logic hay tính năng).
  - `style`: Định dạng code (spacing, formatting - không đổi logic).
  - `test`: Thêm hoặc chỉnh sửa các test cases.

## 3. Quy trình làm việc & Quy tắc chung cho AI Agent
- AI Agent phải đọc `AGENTS.md` và `README.md` để hiểu cấu trúc và quy định dự án trước khi sửa đổi code.
- Tuyệt đối **không được push code trực tiếp lên nhánh `main`**. Mọi thay đổi phải thực hiện trên nhánh tính năng và tạo Pull Request (PR).
- Trước khi commit hoặc tạo PR, bắt buộc phải chạy các lệnh kiểm tra lỗi tĩnh:
  ```bash
  dart format .
  flutter analyze
  ```
