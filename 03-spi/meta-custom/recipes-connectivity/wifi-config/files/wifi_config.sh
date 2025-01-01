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
