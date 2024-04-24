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
    echo -e "${green}Đang cài đặt ProGens! ${plain}\n"
    if [[ x"${release}" == x"centos" ]]; then
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum update
        yum install epel-release -y
        yum install wget curl ufw tmux unzip tar crontabs git socat yum-utils device-mapper-persistent-data lvm2 docker-ce docker-ce-cli containerd.io psmisc -y
        systemctl enable docker
        systemctl start docker
    else
        apt-get update -y
        apt-get install wget ufw tmux curl unzip tar cron git socat ca-certificates gnupg lsb-release psmisc aria2 -y
        curl -fsSL https://download.docker.com/linux/${release}/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${release} $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
        apt-get update -y
        apt-get install docker-ce docker-ce-cli containerd.io -y
        systemctl enable docker.service
    fi
}

install_progens() {
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
        rm -rf /usr/bin/progens
        # wget -q -N --no-check-certificate -O /usr/bin/proton https://github.com/dopaemon/ProtonBox/raw/Download/ProtonBox-${arch}
        # aria2c -s16 -x16 -o proton -d /usr/bin/ https://github.com/dopaemon/ProtonBox/raw/Download/ProtonBox-${arch}

        if [[ x"${release}" == x"centos" ]]; then
            wget -q -N --no-check-certificate -O /usr/bin/progens https://github.com/dopaemon/ProtonBox/raw/ProGens/ProGens-${arch}
        else
            aria2c -s16 -x16 -o progens -d /usr/bin https://github.com/dopaemon/ProtonBox/raw/ProGens/ProGens-${arch}
        fi

        chmod +x /usr/bin/progens
}

echo -e "${green}Bắt đầu cài đặt.${plain}"

install_base

install_progens

echo "export TERM=xterm-256color" >> ~/.bashrc
echo "export TERM=xterm-256color" >> ~/.profile

export TERM=xterm-256color^M

if [ -s /usr/bin/progens ]
then
    echo -e "${green}Nhập 'progens' để sử dụng.${plain}"
else
    echo -e "${red}Liên lạc https://t.me/KernelPanix để báo lỗi.${plain}"
fi
