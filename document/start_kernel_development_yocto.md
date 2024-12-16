Bài viết hôm này mình sẽ cùng với các bạn tìm hiểu về kernel development trong yocto. Thông qua bài viết hi vọng có thể đem đến cho mọi người cái nhìn tổng quan, các khái niệm cơ bản khi làm việc với yocto kernel. Các bài viết sau sẽ trình bày kiến thức chi tiết hơn.

# 1. Tổng quan yocto kernel development
Như chúng ta đã biết thì linux kernel là thành phần cốt lõi trong các hệ thống nhúng linux. Nó là system software nhằm thực hiện cac khởi tạo phần cứng 
và quản lý các tài nguyên của hệ thống. Yocto cung cấp các công cụ và cơ chế để quản lý kernel, hỗ trợ việc tùy chỉnh và cấu hình kernel theo nhu cầu cụ thể của phần cứng và ứng dụng. Trong Yocto, kerner được quản lí thông qua các recipe trong layer.

Khi làm việc với kernel chúng ta cần quan tâm đên:
- kernel source
- kernel config
- các bản patch nếu có
## 1.1. Kernel recipe
Mỗi bản release của yocto sẽ có một vài kernel recipe mà nó support. Ví dụ như trong release 3.1 thì yocto có support một bản linux-yocto-kernel 5.4
```bash
:~/yocto/poky/meta$ ls -l recipes-kernel/linux
total 308
-rw-r--r-- 1 thanh thanh 265178 Nov  5 12:28 cve-exclusion_5.4.inc
-rw-r--r-- 1 thanh thanh    651 Nov  5 12:28 cve-exclusion.inc
-rwxr-xr-x 1 thanh thanh   3546 Nov  5 12:28 generate-cve-exclusions.py
-rw-r--r-- 1 thanh thanh  11314 Nov  5 12:28 kernel-devsrc.bb
drwxr-xr-x 2 thanh thanh   4096 Nov  5 12:24 linux-dummy
-rw-r--r-- 1 thanh thanh   1297 Nov  5 12:28 linux-dummy.bb
-rw-r--r-- 1 thanh thanh   2554 Nov  5 12:28 linux-yocto_5.4.bb
-rw-r--r-- 1 thanh thanh   2562 Nov  5 12:28 linux-yocto-dev.bb
-rw-r--r-- 1 thanh thanh   2060 Nov  5 12:28 linux-yocto.inc
-rw-r--r-- 1 thanh thanh   1902 Nov  5 12:28 linux-yocto-rt_5.4.bb
-rw-r--r-- 1 thanh thanh   1064 Nov  5 12:28 linux-yocto-tiny_5.4.bb
```

Như trên chúng ta có thể thấy thì có một vài recipes mà realse hỗ trợ. Vậy làm thế nào để biết được image của chúng ta đang dùng recipe nào?
Biến *PREFERRED_PROVIDER_virtual/kernel* sẽ cho chúng ta biết được điều đó.
```bash
~/yocto/poky/meta$ bitbake -e core-image-minimal | grep ^PREFERRED_PROVIDER_virtual/kernel
PREFERRED_PROVIDER_virtual/kernel="linux-yocto"
thanh@VN-T14G2-19:~/yocto/poky/meta$
```
Ngoài ra chúng ta có thể kiểm tra bằng command *uname -a* sau khi chạy qemu.
![](https://assets.devlinux.vn/uploads/editor-images/2024/11/16/image_a04c513d3c.png)

## 1.2. Switch kernel recipe
Thông qua biến *PREFERRED_PROVIDER_virtual/kernel* chúng ta có thể thay đổi provider của kerner recipe từ "linux-yocto" sang "linux-yocto-rt". 
Thêm biến đó vào file local.conf
```bash 
PREFERRED_PROVIDER_virtual/kernel = "linux-yocto-rt"
```
 Kiểm tra trong image core-image-minimal
 ```bash
 ~/yocto/poky/meta$ bitbake -e core-image-minimal | grep ^PREFERRED_PROVIDER_virtual/kernel
PREFERRED_PROVIDER_virtual/kernel="linux-yocto-rt"
thanh@VN-T14G2-19:~/yocto/poky/meta$
 ````
Sau khi boot, kiêm tra trên qemu
![](https://assets.devlinux.vn/uploads/editor-images/2024/11/16/image_4c755a56d4.png)

# 2. Build Yocto với custom kernel recipe
Có hai cách cơ bản để biên dịch kernel trong yocto
- Dùng recipe được đính kèm sẵn trong poky
- Sử dụng kernel recipe tự custom

Trong mục này chúng ta sẽ tìm hiểu cách custom 1 kernel recipe. Thông thường tạo 1 kernel recipe thì sẽ tuân theo những yêu cầu sau:
- Kế thừa kernel.bbclass ( nó cung cấp các công cụ, các cấu hình cần thiết để xây dựng kernel cho các target khác nhau)
- Thiết lập SRC_URI (path of kernel source code)
- Chỉ định đường dẫn source cho biến S
- Chỉ định các bản patch nếu có 
- Cung cấp file defconfig cho kernel

## 2.1. Tạo thư mục recipes-kernel
Đầu tiên, tạo thư mục *recipes-kernel* trong 1 layer đã có sẫn ( ví dụ: meta-helloworld đã tạo trong bài trước)
```bash
~/yocto/poky/meta-helloworld$ mkdir recipes-kernel
```
Trong *recipes-kernel*  tạo 1 thư mục *linux* để lưu các kernel recipes.
```bash
~/yocto/poky/meta-helloworld$ 
~/yocto/poky/meta-helloworld/recipes-kernel$ mkdir linux
```

## 2.2. Tạo file kernel recipe 
Tạo 1 file tên *custom-kernel_1.0.bb* để chứa các thông tin hướng dẫn build kernel.
```bash
~/yocto/poky/meta-helloworld/recipes-kernel/linux$ touch custom-kernel_1.0.bb
```
Thêm một số thông tin cơ bản vào file như decription, license
```
DESCRIPTION = "Simple example to buil yocto with a custom kernel recipe"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
inherit kernel
```
## 2.3. Thêm SRC_URI
Trong ví dụ này mình sẽ dủng kernel lastest release ở thời điểm hiện tại là 6.11.8 https://www.kernel.org/. Copy link của file tar lưu vào biến *SRC_URI*
![](https://assets.devlinux.vn/uploads/editor-images/2024/11/16/image_959d2243a3.png)

Sau đó, thêm cấu hình provider cho kernel vào file local.config
```bash
PREFERRED_PROVIDER_virtual/kernel = "custom-kernel"
```
Tiến hành, build thử kernel.
```bash
~/yocto/poky/build$ bitbake custom-kernel
```
Lúc này bạn sẽ nhận được lỗi do thiếu checksum cho file kernel.tar

<mark>ERROR: custom-kernel-1.0-r0 do_fetch: No checksum specified for '/home/thanh/yocto/poky/build/downloads/linux-6.11.8.tar.xz', please add at least one to the recipe:
SRC_URI[sha256sum] = "aee8a844fe152420bece70ffae8525b9b23089aa4da31fa32f30e1859bf93c3d"
ERROR: custom-kernel-1.0-r0 do_fetch: Bitbake Fetcher Error: NoChecksumError('Missing SRC_URI checksum', 'https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.8.tar.xz')
ERROR: Logfile of failure stored in: /home/thanh/yocto/poky/build/tmp/work/qemux86-poky-linux/custom-kernel/1.0-r0/temp/log.do_fetch.369316
ERROR: Task (/home/thanh/yocto/poky/meta-helloworld/recipes-kernel/linux/custom-kernel_1.0.bb:do_fetch) failed with exit code '1'
</mark>
Update lại file kernel recipe bằng cách thêm checksum như log hướng dẫn
```
DESCRIPTION = "Simple example to buil yocto with a custom kernel recipe"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
inherit kernel
SRC_URI = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.8.tar.xz"
SRC_URI[sha256sum] = "aee8a844fe152420bece70ffae8525b9b23089aa4da31fa32f30e1859bf93c3d"
```

## 2.4. Thêm file defconf
Sau khi đã thêm checksum vào file recipe, nếu chúng ta tiếp tục build lại kernel sẽ gặp lỗi khi chưa chỉ ra file defconfig cho kernel
![](https://assets.devlinux.vn/uploads/editor-images/2024/11/16/image_0a576c12e4.png)
Các bạn có thể lấy file [defconfig](https://github.com/torvalds/linux/tree/master/arch/x86/configs) trên repo của linux.
Lưu ý: dùng file i386_defconfig cho x86. Đổi tên file thành defconfig. Sau đó update lại file recipe

```
DESCRIPTION = "Simple example to buil yocto with a custom kernel recipe"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit kernel

SRC_URI = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.8.tar.xz;name=kernel \
           file://defconfig"
DEPENDS += "coreutils-native"
SRC_URI[kernel.sha256sum] = "aee8a844fe152420bece70ffae8525b9b23089aa4da31fa32f30e1859bf93c3d"
```

## 2.5. Chỉ định đường dẫn source
Sau khi update default config, bạn sẽ cần update thêm đường dẫn đên source
```bash
~/yocto/poky/meta-helloworld/recipes-kernel/linux/files$ bitbake -e custom-kernel | grep ^WORKDIR=
WORKDIR="/home/thanh/yocto/poky/build/tmp/work/qemux86-poky-linux/custom-kernel/1.0-r0"
thanh@VN-T14G2-19:~/yocto/poky/meta-helloworld/recipes-kernel/linux/files$ ls -l /home/thanh/yocto/poky/build/tmp/work/qemux86-poky-linux/custom-kernel/1.0-r0/linux-6.11.8
lrwxrwxrwx 1 thanh thanh 66 Nov 16 21:22 /home/thanh/yocto/poky/build/tmp/work/qemux86-poky-linux/custom-kernel/1.0-r0/linux-6.11.8 -> /home/thanh/yocto/poky/build/tmp/work-shared/qemux86/kernel-source
```

Update biến S vào file recipe
```
S = "${WORKDIR}/linux-6.11.8"
```

## 2.6. Build kernel và image
Build kernel 
```bash
~/yocto/poky/meta-helloworld/recipes-kernel/linux/files$ bitbake custom-kernel
...
meta-helloworld
workspace            = "dunfell:63d05fc061006bf1a88630d6d91cdc76ea33fbf2"

Initialising tasks: 100% |########################################################################################################################################################################| Time: 0:00:00
Sstate summary: Wanted 10 Found 1 Missed 9 Current 174 (10% match, 95% complete)
NOTE: Executing Tasks
NOTE: Tasks Summary: Attempted 659 tasks of which 635 didn't need to be rerun and all succeeded
```
```bash
~/yocto/poky/meta-helloworld/recipes-kernel/linux/files$ bitbake core-image-minimal
```
Chạy thử trên qemu, kiểm tra version kernel 

![](https://assets.devlinux.vn/uploads/editor-images/2024/11/16/image_d53e2e256a.png)

# 3. Kết luận
Trong bài viết này mình đã cùng với các bạn tìm hiểu tổng qua về kernel development trong yocto và thực hiện build iamge với custom kernel recipe.
Hi vọng bài viết của mình có thể giúp ích cho các bạn.


