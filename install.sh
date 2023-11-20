#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Thông báo: ${plain} Cần chạy tập lệnh dưới quyền Root.\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "armbian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Phiên bản hệ thống không được phát hiện.${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
else
    echo -e "${red}Hệ thống không được nhận dạng: ${arch}${plain}"
    exit 2
fi

echo "CPU: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "Chỉ dùng được cho máy 64Bit."
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ thống Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    echo -e "${green}Đang cài đặt ProtonBox! ${plain}\n"
    if [[ x"${release}" == x"centos" ]]; then
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
        yum update > /dev/null 2>&1
        yum install epel-release -y > /dev/null 2>&1
        yum install wget curl ufw tmux unzip tar crontabs git socat yum-utils device-mapper-persistent-data lvm2 docker-ce docker-ce-cli containerd.io psmisc -y > /dev/null 2>&1
        systemctl enable docker > /dev/null 2>&1
        systemctl start docker > /dev/null 2>&1
    else
        apt update -y > /dev/null 2>&1
        apt install wget ufw tmux curl unzip tar cron git socat ca-certificates gnupg lsb-release psmisc -y > /dev/null 2>&1
        curl -fsSL https://download.docker.com/linux/${release}/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${release} $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
        apt-get update > /dev/null 2>&1
        apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1
        systemctl enable docker.service > /dev/null 2>&1
    fi
}

install_proton() {
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
        rm -rf /usr/bin/proton
        wget -q -N --no-check-certificate -O /usr/bin/proton https://github.com/dopaemon/ProtonBox/raw/Download/ProtonBox-${arch} > /dev/null 2>&1
        chmod +x /usr/bin/proton
}

echo -e "${green}Bắt đầu cài đặt.${plain}"

install_base

install_proton

if [ -s /opt/ProtonBox/languages ]
then
    rm -rf /opt/ProtonBox/languages
    git clone -b languages --single-branch --depth=1 https://github.com/dopaemon/ProtonBox.git /opt/ProtonBox/languages
else
    git clone -b languages --single-branch --depth=1 https://github.com/dopaemon/ProtonBox.git /opt/ProtonBox/languages
fi

if [ -s /usr/bin/proton ]
then
    echo -e "${green}Nhập 'proton' để sử dụng.${plain}"
else
    echo -e "${green}Liên lạc https://t.me/KernelPanix để báo lỗi.${plain}"
fi
