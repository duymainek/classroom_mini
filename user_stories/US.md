# **Epic: Quản lý Hệ thống và Người dùng**

---

## **US01: Đăng nhập hệ thống theo vai trò**

**As a** (với tư cách là) người dùng (Giảng viên hoặc Sinh viên)
**I want to** (tôi muốn) đăng nhập vào hệ thống bằng tài khoản được cấp
**So that** (để) tôi có thể truy cập vào các tính năng dành riêng cho vai trò của mình.

### **Acceptance Criteria (A/C):**
- [ ] **Giao diện:** Hiển thị form đăng nhập với hai trường "Tài khoản" và "Mật khẩu".
- [ ] [cite_start]**Xác thực Giảng viên:** Hệ thống phải cho phép đăng nhập với tài khoản cố định `admin/admin`[cite: 13].
- [ ] **Xác thực Sinh viên:** Hệ thống phải cho phép sinh viên đăng nhập bằng tài khoản do Giảng viên tạo.
- [ ] **Điều hướng sau đăng nhập:**
    - [ ] [cite_start]Nếu là Giảng viên, chuyển hướng đến trang Dashboard của Giảng viên[cite: 29].
    - [ ] [cite_start]Nếu là Sinh viên, chuyển hướng đến trang chủ hiển thị danh sách khóa học[cite: 28].
- [ ] **Thông báo lỗi:** Hiển thị thông báo lỗi rõ ràng khi nhập sai thông tin đăng nhập.
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Giao diện đăng nhập phải tương thích và hoạt động đầy đủ chức năng.
    - [ ] **Desktop (Windows/macOS):** Giao diện đăng nhập phải tương thích và hoạt động đầy đủ chức năng.
    - [ ] **Web:** Giao diện đăng nhập phải responsive và hoạt động đầy đủ chức năng trên các trình duyệt phổ biến.

---

## **US02: Giảng viên quản lý các thực thể cốt lõi (Học kỳ, Khóa học, Nhóm)**

**As a** Giảng viên
**I want to** thực hiện các thao tác CRUD (Tạo, Xem, Sửa, Xóa) đối với Học kỳ, Khóa học và Nhóm học
**So that** tôi có thể thiết lập cấu trúc học thuật cho toàn bộ hệ thống.

### **Acceptance Criteria (A/C):**
- [ ] **Quản lý Học kỳ:**
    - [ ] [cite_start]Giao diện cho phép tạo Học kỳ mới chỉ với `mã` và `tên`[cite: 46].
    - [ ] Giao diện hiển thị danh sách các học kỳ đã tạo và cho phép Sửa/Xóa.
- [ ] **Quản lý Khóa học:**
    - [ ] [cite_start]Giao diện cho phép tạo Khóa học mới với `mã`, `tên`, `số buổi học` (10 hoặc 15) và gán vào một Học kỳ cụ thể[cite: 47].
    - [ ] Giao diện hiển thị danh sách các khóa học theo từng học kỳ và cho phép Sửa/Xóa.
- [ ] **Quản lý Nhóm:**
    - [ ] [cite_start]Giao diện cho phép tạo Nhóm mới và gán vào một Khóa học cụ thể trong một Học kỳ[cite: 48].
    - [ ] Giao diện hiển thị danh sách các nhóm thuộc một khóa học và cho phép Sửa/Xóa.
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Giảng viên có thể xem danh sách các thực thể. Các thao tác Tạo/Sửa/Xóa có thể được đơn giản hóa.
    - [ ] **Desktop (Windows/macOS):** Hỗ trợ đầy đủ các tính năng CRUD với giao diện tối ưu cho màn hình lớn.
    - [ ] **Web:** Hỗ trợ đầy đủ các tính năng CRUD, giao diện responsive.

---

## **US03: Giảng viên quản lý và nhập hàng loạt Sinh viên bằng CSV**

**As a** Giảng viên
**I want to** quản lý tài khoản Sinh viên và sử dụng chức năng nhập hàng loạt từ file CSV có kèm xác thực
[cite_start]**So that** tôi có thể thêm sinh viên vào hệ thống và phân vào các nhóm một cách nhanh chóng, hiệu quả, tránh trùng lặp[cite: 52, 53].

### **Acceptance Criteria (A/C):**
- [ ] [cite_start]**Tạo Sinh viên độc lập:** Giao diện cho phép tạo từng tài khoản sinh viên riêng lẻ trước khi gán vào nhóm[cite: 51].
- [ ] **Chức năng Import CSV:**
    - [ ] [cite_start]Có nút "Import CSV" trên giao diện quản lý sinh viên[cite: 54].
    - [ ] [cite_start]Khi tải file lên, hệ thống hiển thị một màn hình xem trước (preview)[cite: 55, 56].
    - [ ] [cite_start]Màn hình preview phải chỉ rõ trạng thái của từng dòng: "sẽ được thêm" (cho sinh viên mới) hoặc "đã tồn tại" (cho sinh viên trùng)[cite: 56].
    - [ ] [cite_start]Hệ thống cho phép Giảng viên xác nhận chỉ nhập những sinh viên mới và bỏ qua những sinh viên đã tồn tại[cite: 56].
- [ ] [cite_start]**Phản hồi sau Import:** Sau khi hoàn tất, hệ thống hiển thị một màn hình tổng kết kết quả (bao nhiêu thêm thành công, bao nhiêu bị bỏ qua)[cite: 57].
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Hỗ trợ xem danh sách sinh viên. Chức năng import CSV có thể không cần hỗ trợ trên nền tảng này.
    - [ ] **Desktop (Windows/macOS):** Hỗ trợ đầy đủ chức năng quản lý và import CSV.
    - [ ] **Web:** Hỗ trợ đầy đủ chức năng quản lý và import CSV, giao diện responsive.

---

# **Epic: Phân phối Nội dung và Tương tác Học tập**

---

## **US04: Giảng viên tạo và phân phối Bài tập (Assignment)**

**As a** Giảng viên
**I want to** tạo một bài tập mới với các tùy chọn chi tiết và phạm vi phân phối cụ thể
**So that** tôi có thể giao nhiệm vụ và theo dõi tiến độ làm bài của sinh viên.

### **Acceptance Criteria (A/C):**
- [ ] **Form tạo Bài tập:**
    - [ ] [cite_start]Cho phép nhập `tiêu đề`, `mô tả` và đính kèm nhiều tệp/ảnh[cite: 66].
    - [ ] [cite_start]Cho phép thiết lập `ngày bắt đầu`, `hạn chót`, và tùy chọn `cho phép nộp trễ` (với hạn chót nộp trễ riêng)[cite: 66].
    - [ ] [cite_start]Cho phép giới hạn `số lần nộp tối đa`, `định dạng tệp` và `kích thước tệp`[cite: 66].
- [ ] [cite_start]**Phân phối:** Cho phép chọn phạm vi phân phối đến một, nhiều, hoặc tất cả các nhóm trong một khóa học[cite: 67].
- [ ] **Giao diện theo dõi:**
    - [ ] [cite_start]Hiển thị real-time danh sách sinh viên với các trạng thái: đã nộp, chưa nộp, nộp trễ, số lần nộp, và điểm số hiện tại[cite: 67].
    - [ ] [cite_start]Bảng theo dõi này phải hỗ trợ tìm kiếm, lọc (theo nhóm, trạng thái) và sắp xếp[cite: 68].
    - [ ] [cite_start]Có chức năng xuất toàn bộ dữ liệu theo dõi ra file CSV[cite: 68].
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Giảng viên có thể xem trạng thái nộp bài. Sinh viên có thể xem và nộp bài.
    - [ ] **Desktop (Windows/macOS):** Hỗ trợ đầy đủ chức năng tạo, quản lý và theo dõi bài tập.
    - [ ] **Web:** Hỗ trợ đầy đủ chức năng, giao diện responsive.

---

## **US05: Sinh viên xem và nộp Bài tập**

**As a** Sinh viên
**I want to** xem chi tiết các bài tập được giao và nộp bài làm của mình trước hạn chót
**So that** tôi có thể hoàn thành các yêu cầu của khóa học.

### **Acceptance Criteria (A/C):**
- [ ] **Xem Bài tập:**
    - [ ] Trong tab "Classwork", sinh viên thấy danh sách các bài tập được giao cho nhóm của mình.
    - [ ] [cite_start]Khi nhấp vào, sinh viên thấy đầy đủ thông tin: tiêu đề, mô tả, tệp đính kèm từ giảng viên, hạn chót, và các quy định khác[cite: 66].
- [ ] **Nộp bài:**
    - [ ] Có khu vực để sinh viên đính kèm tệp bài làm của mình.
    - [ ] Nút "Nộp bài" (Submit) để xác nhận việc nộp.
    - [ ] [cite_start]Hệ thống kiểm tra các ràng buộc (kích thước, định dạng tệp) trước khi cho phép nộp[cite: 66].
    - [ ] Sau khi nộp, trạng thái bài tập được cập nhật.
- [ ] [cite_start]**Thông báo:** Sinh viên nhận được email xác nhận đã nộp bài thành công[cite: 82].
- [ ] [cite_start]**Hạn chế:** Sinh viên không thể nộp bài cho các khóa học ở học kỳ cũ (chế độ chỉ đọc)[cite: 33].
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Chức năng xem và nộp bài phải hoạt động trơn tru.
    - [ ] **Desktop (Windows/macOS):** Chức năng xem và nộp bài phải hoạt động trơn tru.
    - [ ] **Web:** Chức năng xem và nộp bài phải hoạt động trơn tru, giao diện responsive.

---

## **US06: Giảng viên tạo và quản lý Quiz từ Ngân hàng câu hỏi**

**As a** Giảng viên
**I want to** tạo các bài quiz bằng cách lựa chọn câu hỏi từ một ngân hàng câu hỏi có thể tái sử dụng
**So that** tôi có thể kiểm tra kiến thức của sinh viên một cách nhanh chóng và đa dạng.

### **Acceptance Criteria (A/C):**
- [ ] **Ngân hàng câu hỏi:**
    - [ ] [cite_start]Có một khu vực riêng để quản lý ngân hàng câu hỏi, có thể tái sử dụng qua các học kỳ[cite: 69].
    - [ ] [cite_start]Mỗi câu hỏi có dạng trắc nghiệm nhiều lựa chọn, một đáp án đúng, và nhãn độ khó (dễ, trung bình, khó)[cite: 70].
- [ ] **Tạo Quiz:**
    - [ ] [cite_start]Giảng viên có thể tạo quiz mới và cấu hình `thời gian mở/đóng`, `số lần làm bài`, `thời lượng`[cite: 71].
    - [ ] [cite_start]Giảng viên có thể chọn ngẫu nhiên một số lượng câu hỏi dựa trên cấu trúc (ví dụ: 5 dễ, 3 trung bình, 2 khó) từ ngân hàng câu hỏi[cite: 71].
- [ ] **Theo dõi và Xuất dữ liệu:**
    - [ ] [cite_start]Giao diện theo dõi hiển thị ai đã làm, chưa làm, điểm số, và thời gian nộp[cite: 72].
    - [ ] [cite_start]Hỗ trợ xuất kết quả của một hoặc tất cả các bài quiz ra file CSV[cite: 72].
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Sinh viên có thể làm quiz. Giảng viên có thể xem kết quả.
    - [ ] **Desktop (Windows/macOS):** Hỗ trợ đầy đủ chức năng tạo, quản lý quiz và ngân hàng câu hỏi.
    - [ ] **Web:** Hỗ trợ đầy đủ chức năng, giao diện responsive.


# **Epic: Giao diện Người dùng và Trải nghiệm Cốt lõi**

---

## **US08: Hiển thị Trang chủ theo Vai trò và Điều hướng Học kỳ**

**As a** (với tư cách là) người dùng (Giảng viên hoặc Sinh viên)
**I want to** (tôi muốn) xem một trang chủ được cá nhân hóa theo vai trò của mình và có thể dễ dàng chuyển đổi giữa các học kỳ
**So that** (để) tôi có thể nhanh chóng nắm bắt thông tin quan trọng nhất và truy cập dữ liệu từ các học kỳ trước.

### **Acceptance Criteria (A/C):**
- [ ] **Trang chủ Giảng viên:** Giao diện phải là một dashboard tóm tắt các chỉ số chính của học kỳ hiện tại: số lượng khóa học, nhóm, sinh viên, bài tập và quiz. Phải có các biểu đồ tiến độ để cung cấp thông tin chi tiết nhanh.
- [ ] **Trang chủ Sinh viên:** Giao diện phải hiển thị các khóa học đã đăng ký dưới dạng thẻ (cards). Mỗi thẻ phải có ảnh bìa, tên khóa học, và tên giảng viên.
- [ ] **Chuyển đổi Học kỳ:**
    - [ ] Cả hai vai trò đều phải có một công cụ chuyển đổi học kỳ ở vị trí thuận tiện.
    - [ ] Hệ thống phải mặc định tải học kỳ mới nhất khi truy cập.
- [ ] **Chế độ Chỉ đọc:** Khi sinh viên chuyển sang xem một học kỳ đã qua, mọi hành động như nộp bài tập hay làm quiz đều bị vô hiệu hóa.
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Giao diện trang chủ và chức năng chuyển đổi học kỳ phải được tối ưu hóa và hoạt động đầy đủ.
    - [ ] **Desktop (Windows/macOS):** Giao diện trang chủ và chức năng chuyển đổi học kỳ phải hoạt động đầy đủ.
    - [ ] **Web:** Giao diện trang chủ phải responsive và hoạt động đầy đủ trên các trình duyệt.

---

## **US09: Điều hướng Không gian Khóa học với cấu trúc 3 Tab**

**As a** (với tư cách là) thành viên của một khóa học
**I want to** (tôi muốn) truy cập vào không gian khóa học được tổ chức thành 3 tab rõ ràng: Stream, Classwork, và People
**So that** (để) tôi có thể dễ dàng tìm thấy thông báo, bài tập, tài liệu và danh sách các thành viên trong lớp.

### **Acceptance Criteria (A/C):**
- [ ] **Cấu trúc 3 Tab:** Mỗi khóa học khi được mở ra phải được tổ chức thành ba tab.
- [ ] **Tab Stream:** Phải hiển thị các thông báo gần đây và cho phép các chuỗi bình luận ngắn để tương tác nhanh.
- [ ] **Tab Classwork:** Phải là nơi tập trung các bài tập, quiz, và tài liệu. Tab này phải được tổ chức có hệ thống và có khả năng tìm kiếm, sắp xếp.
- [ ] **Tab People:** Phải liệt kê các nhóm và sinh viên đã đăng ký trong khóa học.
- [ ] **Quyền của Sinh viên:** Sinh viên có thể xem cả ba tab nhưng không thể nhắn tin trực tiếp cho các sinh viên khác từ đây.
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Cấu trúc 3 tab phải dễ dàng điều hướng, có thể sử dụng swipe gestures.
    - [ ] **Desktop (Windows/macOS):** Cấu trúc 3 tab phải hiển thị rõ ràng và đầy đủ chức năng.
    - [ ] **Web:** Cấu trúc 3 tab phải responsive và hoạt động tốt.

---

## **US10: Quản lý Hồ sơ Cá nhân (User Profile)**

**As a** (với tư cách là) người dùng (Giảng viên hoặc Sinh viên)
**I want to** (tôi muốn) xem và chỉnh sửa thông tin cá nhân cơ bản trên trang Profile của mình
**So that** (để) tôi có thể cá nhân hóa tài khoản và đảm bảo thông tin của mình là chính xác.

### **Acceptance Criteria (A/C):**
- [ ] **Trang Profile:** Cả Giảng viên và Sinh viên đều phải có một trang Profile.
- [ ] **Chỉnh sửa thông tin:** Người dùng có thể xem và chỉnh sửa các thông tin cơ bản như avatar và các trường bổ sung khác.
- [ ] **Hạn chế:** Tên hiển thị (display name) không thể bị thay đổi.
- [ ] **Quy tắc đặt tên:** Tên người dùng phải là tên thật, không được phép dùng các tên chung chung như "user1", "user2".
- [ ] **Triển khai đa nền tảng:**
    - [ ] **Mobile (Android):** Trang Profile phải hiển thị và cho phép chỉnh sửa các trường được phép.
    - [ ] **Desktop (Windows/macOS):** Trang Profile phải hoạt động đầy đủ chức năng.
    - [ ] **Web:** Trang Profile phải hoạt động đầy đủ chức năng và có giao diện responsive.