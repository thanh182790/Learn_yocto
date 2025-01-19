Bài viết hôm nay mình sẽ chia sẻ cách setup wifi cho raspberry pi zero W bằng yocto.

# 1. Tạo  layer
Tạo 1 layer mới để chứa các recipes cấu hình wifi cho raspberry pi.
```bash
~$ bitbake-layers create-layer /home/tnguyenv/yocto/sources/meta-custom
```
# 2. Thêm layer vào project
Thêm layer vừa tạo vào dự án. 
```bash
~/yocto/sources/poky/build$ bitbake-layers show-layers
NOTE: Starting bitbake server...
layer                 path                                      priority
==========================================================================
meta                  /home/tnguyenv/yocto/sources/poky/meta    5
meta-poky             /home/tnguyenv/yocto/sources/poky/meta-poky  5
meta-yocto-bsp        /home/tnguyenv/yocto/sources/poky/meta-yocto-bsp  5
meta-raspberrypi      /home/tnguyenv/yocto/sources/meta-raspberrypi  9
meta-oe               /home/tnguyenv/yocto/sources/meta-openembedded/meta-oe  6
meta-python           /home/tnguyenv/yocto/sources/meta-openembedded/meta-python  7
meta-multimedia       /home/tnguyenv/yocto/sources/meta-openembedded/meta-multimedia  6
meta-networking       /home/tnguyenv/yocto/sources/meta-openembedded/meta-networking  5
meta-custom           /home/tnguyenv/yocto/sources/meta-custom  6
```
Lưu ý là ngoài layer vừa tạo thì chúng ta cũng cần thêm các layer của open-embedded.
# 3. Tạo các recipes
Trong layer vừa tạo, chúng ta tạo 1 thư mục *recipes-connectivity* để chứa các recipe cần cho việc setup wifi.
```bash
~/yocto/sources/meta-custom$ ls -l
total 20
-rw-r--r-- 1 tnguyenv tnguyenv 1035 Dec 26 22:26 COPYING.MIT
-rw-r--r-- 1 tnguyenv tnguyenv  795 Dec 26 22:26 README
drwxr-xr-x 2 tnguyenv tnguyenv 4096 Dec 26 22:26 conf
drwxr-xr-x 4 tnguyenv tnguyenv 4096 Dec 28 01:01 recipes-connectivity
drwxr-xr-x 3 tnguyenv tnguyenv 4096 Dec 26 22:26 recipes-example
```
## 3.1. Tạo recipe wpa-supplicant
Tạo 1 thư mục *wpa-supplicant* để chứa file cấu hình và file công thức như dưới
```bash
~/yocto/sources/meta-custom/recipes-connectivity/wpa-supplicant$ tree
.
├── files
│   └── wpa_supplicant.conf
└── wpa-supplicant-conf.bb

1 directory, 2 files
```
```bash
~/yocto/sources/meta-custom/recipes-connectivity/wpa-supplicant$ cat files/wpa_supplicant.conf
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
        ssid="YOUR_WIFI_NAME"
        psk="YOUR_WIFI_PASSWORD"
        key_mgmt=WPA-PSK
}
```
```bash
~/yocto/sources/meta-custom/recipes-connectivity/wpa-supplicant$ cat wpa-supplicant-conf.bb
SUMMARY = "Custom wpa_supplicant.conf file"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wpa_supplicant.conf"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 0600 ${WORKDIR}/wpa_supplicant.conf ${D}${sysconfdir}/wpa_supplicant/
}

FILES:${PN} = "${sysconfdir}/wpa_supplicant/wpa_supplicant.conf"
```
## 3.2. Tạo recipe config wifi
Trong bước trên chúng ta đã tạo ra một file để cấu hình wifi nhưng chúng ta cần phải điền tên wifi, mật khẩu sau khi flash image lên.
Trong bước này, chúng ta sẽ tạo ra 1 recipe để install một file script vào system cho phép chúng ta setup wifi thông qua script này .
```bash
~/yocto/sources/meta-custom/recipes-connectivity/wifi-config$ ls -l
total 8
drwxr-xr-x 2 tnguyenv tnguyenv 4096 Dec 28 01:09 files
-rw-r--r-- 1 tnguyenv tnguyenv  410 Dec 28 01:22 wifi-config.bb
```
```bash
~/yocto/sources/meta-custom/recipes-connectivity/wifi-config$ cat files/wifi_config.sh
#!/bin/bash

CONFIG_FILE="/etc/wpa_supplicant/wpa_supplicant.conf"
BACKUP_FILE="/etc/wpa_supplicant/wpa_supplicant.conf.bak"

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with root." >&2
    exit 1
fi

# Nhập thông tin từ người dùng
read -p "Enter SSID: " ssid
read -p "Enter password WiFi: " psk

# Kiểm tra đầu vào
if [[ -z "$ssid" || -z "$psk" ]]; then
    echo "SSID and password isn't allowed empty." >&2
    exit 1
fi

# Sao lưu file cấu hình cũ (nếu tồn tại)
if [ -f "$CONFIG_FILE" ]; then
    echo "Back up config ..."
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    if [ $? -ne 0 ]; then
        echo "Can not back up old config." >&2
        exit 1
    fi
    echo "Back up config save in: $BACKUP_FILE"
fi

# Ghi cấu hình mới vào file
echo "Writing new config to file $CONFIG_FILE..."
cat > "$CONFIG_FILE" <<EOF
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
update_config=1

network={
    ssid="$ssid"
    psk="$psk"
    key_mgmt=WPA-PSK
}
EOF

# Đặt quyền hạn cho file cấu hình
chmod 600 "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    echo "Can not set privilege for file config $(CONFIG_FILE)" >&2
    exit 1
fi

echo "Update config for wifi successfull."

# Khởi động lại wpa_supplicant
echo "Restarting wpa_supplicant..."
pkill wpa_supplicant
wpa_supplicant -B -i wlan0 -c "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    echo "Can not restart wpa_supplicant. please check again." >&2
    exit 1
fi

# Lấy địa chỉ IP
echo "Getting IP of board..."
udhcpc -i wlan0
if [ $? -ne 0 ]; then
    echo "Can not get ip. Please check again." >&2
    exit 1
fi

echo "WiFi has been configured and activated successfully!"
```
```bash
~/yocto/sources/meta-custom/recipes-connectivity/wifi-config$ cat wifi-config.bb
SUMMARY = "WiFi configuration script"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wifi_config.sh"

S = "${WORKDIR}"
# add depen for script
RDEPENDS_${PN} += "bash"
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/wifi_config.sh ${D}${bindir}/wifi_config.sh
}

FILES:${PN} = "${bindir}/wifi_config.sh"
```
# 4. Sửa file local.conf
Thêm vào cuối file 
```
INHERIT += "rm_work"
# Thêm vào cuối file conf/local.conf
MACHINE = "raspberrypi0-wifi"

# Thêm các package cần thiết
IMAGE_INSTALL:append = " \
    iw\
    wpa-supplicant \
    linux-firmware-bcm43430 \
    iw \
    dhcpcd \
"

# Thêm WiFi vào DISTRO_FEATURES
DISTRO_FEATURES:append = " wifi"

# Tùy chọn: Enable SSH để debug
EXTRA_IMAGE_FEATURES += "ssh-server-dropbear"
# Trong local.conf thêm
IMAGE_INSTALL:append = " wpa-supplicant-conf"
IMAGE_INSTALL:append = " wifi-config"
ENABLE_UART = "1"
```
# 5. Build lại image
```bash
~/yocto/sources/poky/build/conf$ bitbake rpi-basic-image
```
# 6. Flash image rồi chạy thử
Sau khi system init ok thì kiểm tra các interface.
```
root@raspberrypi0-wifi:~# ifconfig -a
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

wlan0     Link encap:Ethernet  HWaddr B8:27:EB:A3:78:E7
          BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```
Chạy file wifi_config.sh để setup wifi. Điền tên wifi và mật khẩu.
```bash
root@raspberrypi0-wifi:~# which wifi_config.sh
/usr/bin/wifi_config.sh
root@raspberrypi0-wifi:~#
```
```bash
root@raspberrypi0-wifi:~# wifi_config.sh
Enter SSID: Trolllllllllllllllllllllllllllll
Enter password WiFi: 0346534617
Back up config ...
Back up config save in: /etc/wpa_supplicant/wpa_supplicant.conf.bak
Writing new config to file /etc/wpa_supplicant/wpa_supplicant.conf...
Update config for wifi successfull.
Restarting wpa_supplicant...
/usr/bin/wifi_config.sh: line 58: pkill: command not found
Successfully initialized wpa_supplicant
[ 1160.398319] brcmfmac: brcmf_cfg80211_set_power_mgmt: power save enabled
Getting IP of board...
udhcpc: started, v1.31.1
udhcpc: sending discover
[ 1161.617059] IPv6: ADDRCONF(NETDEV_CHANGE): wlan0: link becomes ready
udhcpc: sending discover
udhcpc: sending select for 192.168.0.102
udhcpc: lease of 192.168.0.102 obtained, lease time 86400
/etc/udhcpc.d/50default: Adding DNS 192.168.0.1
WiFi has been configured and activated successfully!
root@raspberrypi0-wifi:~#
```
Kiểm tra lại bằng câu lệnh *ifconig -a*
```bash
root@raspberrypi0-wifi:~# ifconfig -a
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

wlan0     Link encap:Ethernet  HWaddr B8:27:EB:A3:78:E7
          inet addr:192.168.0.102  Bcast:192.168.0.255  Mask:255.255.255.0
          inet6 addr: fe80::ba27:ebff:fea3:78e7/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1532 (1.4 KiB)  TX bytes:1862 (1.8 KiB)
```
Thấy rằng đã có địa chỉ ip để kết nối.
Thử ssh từ host hiện tai sang board pi.
```bash
tnguyenv@VN-T14G2-19:~$ ssh root@192.168.0.102
The authenticity of host '192.168.0.102 (192.168.0.102)' can't be established.
RSA key fingerprint is SHA256:oWKb/WylpfBDImm+HQSqRQpYcsghsUYDjwVjePUriZg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Please type 'yes', 'no' or the fingerprint: yes
Warning: Permanently added '192.168.0.102' (RSA) to the list of known hosts.
root@raspberrypi0-wifi:~#
```
OK thế là chúng ta đã setup được wifi  trên con Pi zero W để ssh qua rồi.
