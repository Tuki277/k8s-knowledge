# lựa chọn version java

apt install openjdk-11-jdk -y

update-alternatives --config java

adduser jenkins

su jenkins

# install gitlab và blue ocean plugins

# jenkins > system > add gitlab

# new item > pipeline > tên dự án > enable (discard old build - giữ lại những bản build cũ - nên để 10 bản)
# Build when a change is pushed to GitLab (enable push event, accepted merge request event), trên gitlab (nên bỏ push event đi, vì chỉ khi nào merge mới nên build)

# tạo một service để jenkins agent có thể khởi động cùng hệ thống nếu bị tắt
# /etc/systemd/system/jenkins-agent.service lưu ý, script connect có %2D hoặc url encode, thì sửa hết về dạng thường