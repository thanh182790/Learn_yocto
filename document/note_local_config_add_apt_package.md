#### Thêm đoạn này vào file local.conf

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
PACKAGE_CLASSES = "package_deb"
IMAGE_INSTALL:append = " apt dpkg dpkg-dev"
IMAGE_INSTALL_append = " packagegroup-core-buildessential"

# Trong local.conf thêm
IMAGE_INSTALL:append = " wpa-supplicant-conf" ## Cái này là mình tự thêm custom image, có thể bỏ.
IMAGE_INSTALL:append = " wifi-config" ## giống trên
ENABLE_UART = "1"
