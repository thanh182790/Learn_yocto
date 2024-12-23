
Bài viết này thì mình sẽ chia sẻ cách build image cho Raspberry Pi Zero W bằng Yocto Project. Hãy cùng theo dõi nhé!

![](https://assets.devlinux.vn/uploads/editor-images/2024/11/20/image_4054780d24.png)

# 1. Giới thiệu chung về Yocto

Yocto là một dự án mã nguồn mở giúp dễ dàng build và tùy chỉnh một hệ điều hành nhúng. Yocto cung cấp các công cụ và tài nguyên để xây dựng OS phù hợp với phần cứng và ứng dụng cụ thể. Yocto cho phép định nghĩa và cấu hình các thành phần hệ thống, từ kernel Linux, thư viện, ứng dụng đến các tiện ích hệ thống.

# 2. Build Image

Để build thì chúng ta cần chuẩn bị một số phần cứng và phần mềm cần thiết trong quá trình build. Mình sẽ nói về các yêu cầu đó dưới đây và làm thế làm để tải phần mềm thì các bạn tự tìm hiểu để tải nhé.

## 2.1 Required

- Host Ubuntu chạy trên máy ảo VMware. Với ít nhất 50GB trống ổ cứng nhé.
- Raspberry Pi Zero W
- microSD card 16Gb trở lên.

## 2.2 Install host package

Để build được thì bạn cần tải install các package này nhé:

```bash
$ sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 python3-subunit zstd liblz4-tool file locales libacl1 
```

## 2.3 Clone Poky

**Đầu tiên tạo thư mục để build:**

```bash
$ mkdir yocto
$ cd yocto
```

**Tiếp theo chúng ta sẽ clone Poky repo để build từ trang chủ yoctoproject:**

```bash
$ git clone git://git.yoctoproject.org/poky
$ cd poky
$ git checkout -b dunfell origin/dunfell
```

## 2.4 Downloading necessary layers

**Download raspberrypi layer:**

```bash
$ git clone git://git.yoctoproject.org/meta-raspberrypi -b dunfell
```

## 2.5 Set up the build environment

**Thiết lập môi trường build:**

```bash
$ source oe-init-build-env build-rpi
```

## 2.5 Add layer and config machine

Sau đó ta cấu hình build bằng cách chỉnh sửa file **local.conf**. **Thay "qemux86" bằng "raspberrypi0-wifi":**

```bash
$ vim ../build/conf/local.conf
[...]
# MACHINE ??= "qemux86"
MACHINE ??= "raspberrypi0-wifi"
[...]
```

**Add layer vào bblayers.conf:**

```bash
$ vim ../build/conf/bblayers.conf
BBLAYERS ?= " \
  /home/user/yocto/poky/meta \
  /home/user/yocto/poky/meta-poky \
  /home/user/yocto/poky/meta-yocto-bsp \
	/home/user/yocto/poky/meta-raspberrypi \
  "
```

**Build:**

```bash
$ bitbake core-image-minimal
```

![](https://assets.devlinux.vn/uploads/editor-images/2024/11/23/image_5f069bc0ae.png)

## 2.6 Copy images into SDCard and boot

**Sau khi build xong ta vào đường dẫn sau:**

```bash
$ cd ~/yocto/poky/build-rpi/tmp/deploy/images/raspberrypi0-wifi/
```

**Ta sẽ thấy images:**

![](https://assets.devlinux.vn/uploads/editor-images/2024/11/23/Screenshot_2024_11_23_100501_aea3cd0bef.png)

Tiếp theo sẽ flash cho thẻ nhớ bằng "**core-image-minimal-raspberrypi0-wifi-20241123012031.rootfs.wic.bz2**". Các bạn cắm thẻ nhớ vào và check xem device file của thẻ nhớ là gì bằng lệnh lsblk. Thường thì là /dev/sdb:

```bash
$ lsblk
```

**Tạo ra image tạm:**

```bash
$ cp core-image-minimal-raspberrypi0-wifi-20241123012031.rootfs.wic.bz2 temp.wic.bz2
```

**Giải nén bzip2:**

```bash
$ bzip2 -d temp.wic.bz2
```

**Flash vào SDcard:**

```bash
$ sudo dd if=/dev/zero of=/dev/sdb bs=512 count=1
$ sudo dd if=temp.wic of=/dev/sdb bs=4M status=progress
$ sync
```

Sau khi flash vào SDCard rồi thì cắm thẻ nhớ vào Raspberry để khởi động nhé. Có màn hình rời thì gắn vào test luôn :)))

![](https://assets.devlinux.vn/uploads/editor-images/2024/11/23/279b9aa9b63d0d63542c_c3e1d02d8d.jpg)

## 2.7. Note
Ở trên các bạn thấy rằng mình sẽ cần phải clone các layer cần thiết cho việc build image một cách thủ công. Để thuận tiện hơn chúng ta có thể sử dụng tool repo để clone các layer cần thiết thông qua một file manifests. File này sẽ có nhiệm vụ liệt kê các layer cần thiết và setup nhánh mà chúng ta muốn ở các layer. Cách làm như sau:

Các bạn tạo một thư mục workspace chứa các layer output của quá trình build
```bash
~$ mkdir yocto
```
Trong thư mục yocto/ tạo một thư mục manifests để chứa thông tin các layer cần thiết
```bash
~/yocto$ mkdir manifests
```
Trong thư mục manifests/ tạo một file manifests.xml với nội dung như sau:
```bash
~/yocto/manifests$ cat manifests.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- Yocto -->
  <remote name="yocto"
          fetch="git://git.yoctoproject.org"/>
  <project name="poky"
           remote="yocto"
           revision="refs/tags/yocto-3.1.33"
           upstream="dunfell"
           path="sources/poky"/>


  <!-- Raspberry Pi -->
  <project name="meta-raspberrypi"
           remote="yocto"
           revision="2081e1bb9a44025db7297bfd5d024977d42191ed"
           upstream="dunfell"
           path="sources/meta-raspberrypi"/>

</manifest>

```
Trong file này chúng ta sẽ cài đặt các layer mà chúng ta cần clone về và revision commit là gì cũng như nơi clone. Sau đó chúng ta sẽ cần init git tại thư mục manifests này
```bash
~/yocto/manifests$ git init
~/yocto/manifests$ git add manifests.xml
~/yocto/manifests$ git commit -m "Add file manifests"
```
Sau đó, quay lại thư mục yocto để init repo 
```bash
~/yocto$ repo init -u file:///home/tnguyenv/yocto/manifests/ -m manifests.xml
```
Sau khi init xong thì có thể thấy 1 thư mục ẩn .repo/ sẽ xuất hiện 
```bash
~/yocto$ ls -la
total 20
drwxr-xr-x 5 tnguyenv tnguyenv 4096 Dec  1 09:42 .
drwxr-xr-x 9 tnguyenv tnguyenv 4096 Dec  1 09:36 ..
drwxr-xr-x 7 tnguyenv tnguyenv 4096 Dec  1 09:42 .repo
drwxr-xr-x 3 tnguyenv tnguyenv 4096 Dec  1 09:36 manifests
```
Tiếp tục dùng lệnh repo sync để clone source về local. Quá trình này có thể diễn ra nhanh chậm tùy thuộc vào số lượng layer mà bạn setup trong file manifests.
```bash
~/yocto$ repo sync
```
Sau khi xong bước này bạn có thể thấy source đã được clone về máy. Casc bước sau đó sẽ giống như bước 2.5 ( Lưu ý đường dẫn sẽ cần update)
```bash
~/yocto$ tree -L 3
.
├── manifests
│   └── manifests.xml
└── sources
    ├── meta-raspberrypi
    │   ├── COPYING.MIT
    │   ├── README.md
    │   ├── classes
    │   ├── conf
    │   ├── docs
    │   ├── dynamic-layers
    │   ├── files
    │   ├── kas-poky-rpi.yml
    │   ├── lib
    │   ├── recipes-bsp
    │   ├── recipes-connectivity
    │   ├── recipes-core
    │   ├── recipes-devtools
    │   ├── recipes-graphics
    │   ├── recipes-kernel
    │   ├── recipes-multimedia
    │   └── wic
    └── poky
        ├── LICENSE
        ├── LICENSE.GPL-2.0-only
        ├── LICENSE.MIT
        ├── MEMORIAM
        ├── README.OE-Core
        ├── README.hardware -> meta-yocto-bsp/README.hardware
        ├── README.poky -> meta-poky/README.poky
        ├── README.qemu
        ├── SECURITY.md
        ├── bitbake
        ├── contrib
        ├── documentation
        ├── meta
        ├── meta-poky
        ├── meta-selftest
        ├── meta-skeleton
        ├── meta-yocto-bsp
        ├── oe-init-build-env
        └── scripts
```
# 3. Kết luận

Và sau đây và những chia sẻ của mình về build images cho Raspberry Pi Zero W bằng Yocto. Hẹn gặp các bạn ở các bài viết khác nhé!
