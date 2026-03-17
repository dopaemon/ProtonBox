#!/bin/bash

# Màu sắc cho rực rỡ
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# 1. Kiểm tra quyền Root
[[ $EUID -ne 0 ]] && echo -e "${red}Thông báo: ${plain} Cần chạy tập lệnh dưới quyền Root.\n" && exit 1

# 2. Nhận diện hệ điều hành (Fix vụ Debian Sid/Testing)
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif grep -Eqi "armbian" /etc/issue || grep -Eqi "armbian" /proc/version; then
    release="debian"
elif grep -Eqi "ubuntu" /etc/issue || grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
elif grep -Eqi "debian" /etc/issue || grep -Eqi "debian" /proc/version; then
    release="debian"
elif grep -Eqi "centos|red hat|redhat" /etc/issue || grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
else
    echo -e "${red}Phiên bản hệ thống không được phát hiện.${plain}\n" && exit 1
fi

# 3. Nhận diện kiến trúc CPU
arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
else
    echo -e "${red}Hệ thống không được nhận dạng: ${arch}${plain}"
    exit 2
fi

echo -e "${green}Hệ điều hành: ${release} | CPU: ${arch}${plain}"

# 4. Kiểm tra phiên bản OS (Fix lỗi so sánh biến rỗng)
os_version=""
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi

# Nếu là Debian Sid/Forky thì os_version sẽ rỗng, ta gán tạm số lớn để pass check
[[ -z "$os_version" ]] && os_version=99

if [[ x"${release}" == x"centos" && ${os_version} -le 6 ]]; then
    echo -e "${red}Vui lòng sử dụng CentOS 7 trở lên！${plain}\n" && exit 1
elif [[ x"${release}" == x"ubuntu" && ${os_version} -lt 16 ]]; then
    echo -e "${red}Vui lòng sử dụng Ubuntu 16 trở lên！${plain}\n" && exit 1
elif [[ x"${release}" == x"debian" && ${os_version} -lt 8 ]]; then
    echo -e "${red}Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
fi

# 5. Hàm cài đặt base
install_base() {
    echo -e "${green}Đang cài đặt môi trường ProGens...${plain}"
    if [[ x"${release}" == x"centos" ]]; then
        yum update -y
        yum install -y wget curl ufw tmux unzip tar crontabs git socat yum-utils device-mapper-persistent-data lvm2 psmisc epel-release
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
        systemctl enable --now docker
    else
        apt-get update -y
        apt-get install -y wget ufw tmux curl unzip tar cron git socat ca-certificates gnupg lsb-release psmisc aria2
        
        # Cài Docker chính chủ
        mkdir -p /usr/share/keyrings
        curl -fsSL https://download.docker.com/linux/${release}/gpg | gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Fix cho Armbian/Sid: Lấy codename từ lsb_release, nếu lỗi dùng 'stable'
        codename=$(lsb_release -cs 2>/dev/null || echo "stable")
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${release} ${codename} stable" > /etc/apt/sources.list.d/docker.list
        
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io
        systemctl enable --now docker
    fi
}

# 6. Hàm cài đặt ProGens (Binary)
install_progens() {
    echo -e "${green}Đang tối ưu hệ thống và tải ProGens...${plain}"
    
    # Tắt IPv6 an toàn (không chèn trùng lặp)
    grep -qF "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf || echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    grep -qF "net.ipv6.conf.default.disable_ipv6" /etc/sysctl.conf || echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1

    rm -f /usr/bin/progens
    
    # Tải binary tương ứng kiến trúc, thêm --allow-overwrite cho aria2
    if [[ x"${release}" == x"centos" ]]; then
        wget -q -N --no-check-certificate -O /usr/bin/progens "https://github.com/dopaemon/ProtonBox/raw/ProGens/ProGens-${arch}"
    else
        aria2c -s16 -x16 --allow-overwrite=true -o progens -d /usr/bin "https://github.com/dopaemon/ProtonBox/raw/ProGens/ProGens-${arch}"
    fi

    chmod +x /usr/bin/progens
}

# --- Thực thi ---
echo -e "${green}Bắt đầu quy trình cài đặt tổng thể.${plain}"

install_base
install_progens

# Thiết lập Terminal color
for file in ~/.bashrc ~/.profile; do
    grep -qF "xterm-256color" "$file" || echo "export TERM=xterm-256color" >> "$file"
done
export TERM=xterm-256color

if [ -s /usr/bin/progens ]; then
    echo -e "----------------------------------------------------"
    echo -e "${green}Cài đặt hoàn tất! Nhập '${yellow}progens${green}' để bắt đầu.${plain}"
    echo -e "----------------------------------------------------"
else
    echo -e "${red}Lỗi: Không tải được ProGens. Liên hệ https://t.me/KernelPanix để báo lỗi.${plain}"
fi
