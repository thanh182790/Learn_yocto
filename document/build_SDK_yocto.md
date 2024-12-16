Ơ các bài viết trước chúng ta đã tìm hiểu về (Sẽ paste link bài viết vào sau khi public).
- Cách tạo một layer đơn giản trong yocto.
- Cách sử dụng devtool để thao tác với recipes
- Package dependencies và splitting.

Tiếp nối chuỗi bài viết về yocto thì hôm nay mình sẽ cùng với các bạn tìm hiểu cách build SDK trong Yocto.

## 1. Tổng quan về SDK

Sofware Development Kit (SDK) là một bộ công cụ và thư viện dành cho các developers để xây dựng, kiểm thử và triển khai các ứng dụng.

Một SDK tiêu chuẩn gồm có các thành phần:
- *Cross-Development, toolchain*: chứa các công cụ để biên dịch, debug, ... . Giúp chúng ta có thể biên dịch mã nguồn trên máy host tạo ra file thực thi có thể chạy được trên máy target.
- *Thư viện,  Header*: Các thư viện và header file cần thiết để phát triển ứng dung.
-*Các script để cài đặt môi trường*.

## 2. Build SDK 
### 2.1.1. Tích hợp trực tiếp SDK vào image
Trong yocto có hỗ trợ chúng ta, cài đặt trực tiếp SDK vào image bằng cách sử dụng biến *EXTRA_IMAGE_FEATURES* trong file *build/conf/local.conf*

Để làm được vậy chúng ta thêm feature như sau
```bash
EXTRA_IMAGE_FEATURES ?= "tools_sdk"
```
Sau đó build lại image và kiểm tra *gcc, make*,... đã có trên image đó chưa
```bash
bitbake core-image-minimal
```
Kết quả:
![](https://assets.devlinux.vn/uploads/editor-images/2024/11/14/image_4aaccbdbcc.png)

### 2.1.2. Tạo ra file cài đặt SDK
Vì cách trên sẽ cài đặt trực tiếp SDK lên image do đó nếu chúng ta muôn phát triển các phần mềm trên máy host thì cần phải có SDK của máy target. 
Yocto cũng hỗ trợ chúng ta tạo ra file cài đặt SDK ngay trên máy host bằng cách build image với option.

```bash 
bitbake core-image-minimal -c populate_sdk
```

```bash 
bitbake core-image-minimal -c populate_sdk_ext
```

- Option*populate_sdk* sẽ tạo ra SDK tiêu chuẩn
- Oprion *populate_sdk_ext* tạo ra một extensible SDK. eSDK là một phiên bản mở rộng bao gồm các thành phần của SDK và gôm thêm các tập lệnh
trong *devtool* như bài học trước đã giới thiệu.

Sau khi build xong, thì file cài đặt SDK sẽ được lưu trong *build/tmp/deploy/sdk/*
```bash
:~/yocto/poky/build$ ls -l tmp/deploy/sdk/
total 389096
-rw-r--r-- 1 thanh thanh      8968 Nov 14 01:21 poky-glibc-x86_64-core-image-minimal-core2-32-qemux86-toolchain-3.1.33.host.manifest
-rwxr-xr-x 1 thanh thanh 398178632 Nov 14 01:28 poky-glibc-x86_64-core-image-minimal-core2-32-qemux86-toolchain-3.1.33.sh
-rw-r--r-- 1 thanh thanh     21847 Nov 14 01:21 poky-glibc-x86_64-core-image-minimal-core2-32-qemux86-toolchain-3.1.33.target.manifest
-rw-r--r-- 1 thanh thanh    212605 Nov 14 01:21 poky-glibc-x86_64-core-image-minimal-core2-32-qemux86-toolchain-3.1.33.testdata.json
```

Để cài đặt SDK trên máy host, cần chạy file .sh. Chúng ta có thể chỉ rõ đường dẫn muốn lưu SDK hoặc dùng đường dẫn mặc đinh.
```bash
~/yocto/poky/build/tmp/deploy/sdk$ ./poky-glibc-x86_64-core-image-minimal-core2-32-qemux86-toolchain-3.1.33.sh
Poky (Yocto Project Reference Distro) SDK installer version 3.1.33
==================================================================
Enter target directory for SDK (default: /opt/poky/3.1.33): ~/yocto/sdk_install/qemux86/
```

```bash
~/yocto/sdk_install/qemux86$ ls -l
total 32
-rw-r--r-- 1 thanh thanh  4097 Nov 14 12:30 environment-setup-core2-32-poky-linux
-rw-r--r-- 1 thanh thanh 15355 Nov 14 12:30 site-config-core2-32-poky-linux
drwxr-xr-x 4 thanh thanh  4096 Nov 14 12:29 sysroots
-rw-r--r-- 1 thanh thanh   122 Nov 14 12:30 version-core2-32-poky-linux
```

Muốn phát triển các ứng dụng cho máy target, ta cần cài đặt môi trường 
```bash
~/yocto/sdk_install/qemux86$ source environment-setup-core2-32-poky-linux
```
Kiểm tra các đường dẫn trong biến PATH
```bash
~/yocto/sdk_install/qemux86$ echo $PATH
/home/thanh/yocto/sdk_install/qemux86/sysroots/x86_64-pokysdk-linux/usr/bin:/home/thanh/yocto/sdk_install/qemux86/sysroots/x86_64-pokysdk-linux/usr/sbin 
...
```

### 2.1.3. Thử nghiệm
Viết một chương trình hello_SDK đơn giản, biên dịch trên máy host rồi copy sang target xem kết quả.
```
#include <stdio.h>

int main()
{
        printf("Hello SDK\n");
        return 0;
}
```
Biên dịch
```bash
~/yocto/sdk_install/qemux86$ $CC -o ~/hello_SDK_app ~/hello_SDK.c
```
copy file binary sang máy target
```bash
~/yocto/sdk_install/qemux86$ scp /home/thanh/hello_SDK_app root@192.168.7.2:~/
```
Kiểm tra kết quả trên qemu
```bash
root@qemux86:~# ls -l
-rwxr-xr-x    1 root     root         18752 Nov 14 05:53 hello_SDK_app
root@qemux86:~# ./hello_SDK_app
Hello SDK
root@qemux86:~#
```

Kết quả chạy ra đúng như mong muốn. 
Bài hôm nay chúng mình đã tim hiểu cách build SDK bằng yocto. Bài viết của mình còn nhiều thiếu xót. Mong các bạn góp ý...


