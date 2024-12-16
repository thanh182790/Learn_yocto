Hôm này mình và các bạn sẽ cùng tìm hiểu về các thuật ngữ cơ bản nhưng lại quan trọng trong yocto. Bài viết này của mình phù hợp với các bạn mới bắt đầu tiếp cận với yocto muốn nắm được những thuật ngữ hay dùng trong yocto.

# 1. Image
Image cũng chính là một recipe. Nó định nghĩa những thứ sẽ tồn tại ở trong root file system (RFS). Có một vài image được cung cấp trong Poky. Ví dụ như *core-image-minimal* là một image đơn giản nhất để hệ thống có thể khởi động được.
```bash
~/yocto/poky/meta/recipes-core/images$ cat core-image-minimal.bb
SUMMARY = "A small image just capable of allowing a device to boot."

IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE_append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"
```
File này chứa các thông tin để mô tả về recipen này, license, các gói phần mềm cần thiết được cài đặt vào RFS, ....

- *IMAGE_INSTALL* biến này xác định định gói phần mềm được cài đặt vào trong RFS
	+ packagegroup-core-boot: là các package cơ bản cần thiết cho một system
	+ CORE_IMAGE_EXTRA_INSTALL: Ngoài ra chúng ta cũng có thể define thêm các package khác thông qua biến này
- *IMAGE_LINGUAS* để xác định các ngôn ngữ hỗ trợ cho image
- *inherit core-image* chỉ ra image này kế thừa từ class *core-image*. Nó cung cấp các tính năng như cách xử lý IMAGE_INSTALL, định nghĩa filesystem, và nhiều tính năng khác
- *IMAGE_ROOTFS_SIZE* Xác định kích thước của RFS.
- *IMAGE_ROOTFS_EXTRA_SPACE_append* thêm dung lượng trống vào RFS dựa trên các tính năng của distro

# 2. Machine file
Machine là các file mô tả một phần cứng cụ thể mà chúng ta đang build image cho nó.
Ví dụ đây là một file cầu hình để định nghĩa các thông số phần cứng và phần mềm cho máy ảo QEMU với kiến trúc x86.
```bash
~/yocto/poky$ cat meta/conf/machine/qemux86.conf
#@TYPE: Machine
#@NAME: QEMU x86 machine
#@DESCRIPTION: Machine configuration for running an x86 system on QEMU

PREFERRED_PROVIDER_virtual/xserver ?= "xserver-xorg"
PREFERRED_PROVIDER_virtual/libgl ?= "mesa"
PREFERRED_PROVIDER_virtual/libgles1 ?= "mesa"
PREFERRED_PROVIDER_virtual/libgles2 ?= "mesa"

require conf/machine/include/qemu.inc
DEFAULTTUNE ?= "core2-32"
require conf/machine/include/tune-corei7.inc
require conf/machine/include/qemuboot-x86.inc

UBOOT_MACHINE ?= "qemu-x86_defconfig"

KERNEL_IMAGETYPE = "bzImage"

SERIAL_CONSOLES ?= "115200;ttyS0 115200;ttyS1"

XSERVER = "xserver-xorg \
           ${@bb.utils.contains('DISTRO_FEATURES', 'opengl', 'mesa-driver-swrast xserver-xorg-extension-glx', '', d)} \
           xf86-video-cirrus \
           xf86-video-fbdev \
           xf86-video-vmware \
           xf86-video-modesetting \
           xf86-video-vesa \
           xserver-xorg-module-libint10 \
           "

MACHINE_FEATURES += "x86 pci"

MACHINE_ESSENTIAL_EXTRA_RDEPENDS += "v86d"

MACHINE_EXTRA_RRECOMMENDS = "kernel-module-snd-ens1370 kernel-module-snd-rawmidi"

WKS_FILE ?= "qemux86-directdisk.wks"
do_image_wic[depends] += "syslinux:do_populate_sysroot syslinux-native:do_populate_sysroot mtools-native:do_populate_sysroot dosfstools-native:do_populate_sysroot"

#For runqemu
QB_SYSTEM_NAME = "qemu-system-i386"
```
Trong file này sẽ có cấu hình các thông tin chung của máy cũng như là các tính năng, kernel, bootloader, một số cấu hình càn thiết cho qemu.
- *PREFERRED_PROVIDER..* cho biết thông tin provider cho các thư viện hay các dịch vụ.
- *UBOOT_MACHINE* chỉ ra tên cấu hình uboot cho quemux86
- *KERNEL_IMAGETYPE* loại file mà kernel sử dụng (bzImage, zImage, ...)
- *SERIAL_CONSOLES* cấu hình cài đặt cho đường serial 
- *MACHINE_FEATURES* chỉ định các tính năng phần cứng, phần mềm cho machine. Như trong ví dụ trên, chỉ ra máy qemux86 hỗ trợ cho CPU kiến trúc X86 và hỗ tợ các interface PCI
- *MACHINE_ESSENTIAL_EXTRA_RDEPENDS* và *MACHINE_EXTRA_RRECOMMENDS* để chỉ định các kernel module, gói cần thiết.
- Ngoài ra, file này bao gồm các file cấu hình chung cho quemu, khởi động qemu, tinh chỉnh được recommed sử dung cho intel core i7. (Chi tiết các file này mình nghĩ mọi người nên đọc để hiểu rõ hơn).
# 3. Distro
Distro là một bản phân phối linux hoàn chỉnh. Mỗi bản distro đã tùy chỉnh các cầu hình, phần mềm, kernel và các cài đặt khác để cho phù hợp với thiết bị phần cứng. 

Trong các bài học trước khi chúng ta làm việc với yocto, build image thì nếu để ý sẽ thấy trong file local.conf sử dụng biến *DISTRO* để chỉ ra distro mà chúng ra sử dụng. Mặc đinh là Poky distro, nó là distro cơ sở mà các distro khác khi xây dựng sẽ kế thừa.
```bash
~/yocto/poky$ grep "DISTRO" ./build/conf/local.conf
DISTRO ?= "poky"
```
Ta có thể xem những cấu hình của distro trong file config
```bash
~/yocto/poky$ cat meta-poky/conf/distro/poky.conf
DISTRO = "poky"
DISTRO_NAME = "Poky (Yocto Project Reference Distro)"
DISTRO_VERSION = "3.1.33"
DISTRO_CODENAME = "dunfell"
SDK_VENDOR = "-pokysdk"
SDK_VERSION = "${@d.getVar('DISTRO_VERSION').replace('snapshot-${DATE}', 'snapshot')}"

MAINTAINER = "Poky <poky@lists.yoctoproject.org>"

TARGET_VENDOR = "-poky"

LOCALCONF_VERSION = "1"

DISTRO_VERSION[vardepsexclude] = "DATE"
SDK_VERSION[vardepsexclude] = "DATE"

# Override these in poky based distros
POKY_DEFAULT_DISTRO_FEATURES = "largefile opengl ptest multiarch wayland vulkan"
POKY_DEFAULT_EXTRA_RDEPENDS = "packagegroup-core-boot"
POKY_DEFAULT_EXTRA_RRECOMMENDS = "kernel-module-af-packet"

DISTRO_FEATURES ?= "${DISTRO_FEATURES_DEFAULT} ${POKY_DEFAULT_DISTRO_FEATURES}"

PREFERRED_VERSION_linux-yocto ?= "5.4%"

SDK_NAME = "${DISTRO}-${TCLIBC}-${SDKMACHINE}-${IMAGE_BASENAME}-${TUNE_PKGARCH}-${MACHINE}"
SDKPATHINSTALL = "/opt/${DISTRO}/${SDK_VERSION}"

DISTRO_EXTRA_RDEPENDS += " ${POKY_DEFAULT_EXTRA_RDEPENDS}"
DISTRO_EXTRA_RRECOMMENDS += " ${POKY_DEFAULT_EXTRA_RRECOMMENDS}"

POKYQEMUDEPS = "${@bb.utils.contains("INCOMPATIBLE_LICENSE", "GPL-3.0", "", "packagegroup-core-device-devel",d)}"
DISTRO_EXTRA_RDEPENDS_append_qemuarm = " ${POKYQEMUDEPS}"
DISTRO_EXTRA_RDEPENDS_append_qemuarm64 = " ${POKYQEMUDEPS}"
DISTRO_EXTRA_RDEPENDS_append_qemumips = " ${POKYQEMUDEPS}"
DISTRO_EXTRA_RDEPENDS_append_qemuppc = " ${POKYQEMUDEPS}"
DISTRO_EXTRA_RDEPENDS_append_qemux86 = " ${POKYQEMUDEPS}"
DISTRO_EXTRA_RDEPENDS_append_qemux86-64 = " ${POKYQEMUDEPS}"

TCLIBCAPPEND = ""

SANITY_TESTED_DISTROS ?= " \
            poky-2.7 \n \
            poky-3.0 \n \
            poky-3.1 \n \
            ubuntu-18.04 \n \
            ubuntu-20.04 \n \
            ubuntu-22.04 \n \
            fedora-37 \n \
            debian-11 \n \
            opensuseleap-15.3 \n \
            almalinux-8.8 \n \
            "
# add poky sanity bbclass
INHERIT += "poky-sanity"

# QA check settings - a little stricter than the OE-Core defaults
WARN_TO_ERROR_QA = "already-stripped compile-host-path install-host-path \
                    installed-vs-shipped ldflags pn-overrides rpaths staticdev \
                    unknown-configure-option useless-rpaths"
WARN_QA_remove = "${WARN_TO_ERROR_QA}"
ERROR_QA_append = " ${WARN_TO_ERROR_QA}"

require conf/distro/include/poky-world-exclude.inc
require conf/distro/include/no-static-libs.inc
require conf/distro/include/yocto-uninative.inc
require conf/distro/include/security_flags.inc
INHERIT += "uninative"

INHERIT += "reproducible_build"

BB_SIGNATURE_HANDLER ?= "OEEquivHash"
BB_HASHSERVE ??= "auto"
```
Trong file này sẽ define một số biến để cấu hình distro như là 
- *DISTRO* chỉ tên ngắn gọn của distro
- *POKY_DEFAULT_DISTRO_FEATURES* chỉ ra các tính năng mặc định có trong distro
- *DISTRO_FEATURE* danh sách các tính năng đầy đủ. [Xem thêm](https://docs.yoctoproject.org/ref-manual/features.html#distro-features)
- Ngoài ra, file cấu hình cũng sẽ chỉ định các package phụ thuộc thông qua các biến *POKY_DEFAULT_EXTRA_RDEPENDS*, *POKY_DEFAULT_EXTRA_RRECOMMENDS *, ...

# 4. Local.conf
Local.conf trong Yocto là một trong những tệp cấu hình quan trọng được đặt trong thư mục build/conf/. Nó thiết lập các cài đặt và tùy chỉnh cụ thể cho phiên bản build mà bạn đang thực hiện. Ví dụ như là 
- *MACHINE* máy target mà chúng ta muốn build image
- *IMAGE_FSTYPES* chỉ định dạng của rfs
- *BB_NUMBER_THREADS* chỉ định số luồng xử lý được phép cho BitBake.
- *PARALLEL_MAKE* make sẽ sử dụng số thread được chỉ định.
- *TMPDIR* là nơi để lưu output quá trình build
- Ngoài ra còn nhiều cấu hình khác chúng ta có thể đặt vào trong local.conf

 Các cài đặt trong file này sẽ chỉ ảnh hưởng đến môi trường build hiện tại (local) mà không làm thay đổi bất kỳ cài đặt nào trong các cấu hình toàn cục của Yocto.
 
 # 5. Kết luận
 Bài viết hôm nay mình đã trình bày những thuật ngữ cơ bản trong yocto khi mới bắt đầu tìm hiểu nó mà bất cứ ai cũng cần phải biết. Hi vọng nó có thể giúp các bạn hiểu hơn về yocto.



