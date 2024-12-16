Trong các bài viết trước chúng ta có tìm hiểu về một công cụ quan trọng trong yocto mà giúp các developer có thể nhanh chóng tạo, chỉnh sửa, update recipe. Đó là devtool. Hôm nay mình sẽ cùng các bạn tìm hiểu cách để thêm một kernel module sử dụng devtool. Để đơn giản nhất thì mình sẽ lấy ví dụ helloworld kernel module.

# 1. Tạo layer mới để chứa các recipe kernel module
## 1.1. Thiết lập môi trường
Đầu tiên, chúng ta cần thiết lập môi trường Yocto bằng cách chạy lệnh sau trong thư mục dự án Yocto :
```bash
~/yocto/poky$ source oe-init-build-env
```
## 1.2. Tạo một layer mới
Sử dụng công cụ bitbake-layers để tạo layer mới:
```bash
~/yocto/poky/build$ bitbake-layers create-layer ../meta-kernelmodule
```
## 1.3. Thêm layer vào dự án
Mở file conf/bblayers.conf trong thư mục build/conf và thêm đường dẫn đến layer mới tạo:
```bash
BBLAYERS ?= " \
  /home/thanh/yocto/poky/meta \
  /home/thanh/yocto/poky/meta-poky \
  /home/thanh/yocto/poky/meta-yocto-bsp \
  /home/thanh/yocto/poky/meta-kernelmodule \
  /home/thanh/yocto/poky/build/workspace \
  "
```
# 2. Dùng devtool để tạo recipe
## 2.1. Chỉnh sửa kernel với devtool modify  
```bash
~/yocto/poky/build$ devtool modify virtual/kernel
```
Trong yocto *virtual/kernel* chỉ định kernel mà chúng ta đang sử dụng. Chúng ta có thể chỉ định được thông qua biến *PREFERRED_PROVIDER_virtual/kernel* . 
Trong trường hợp này của mình sử dụng *linux-yocto* 
```bash
~/yocto/poky/build$ bitbake -e core-image-minimal | grep ^PREFERRED_PROVIDER_virtual/kernel=
PREFERRED_PROVIDER_virtual/kernel="linux-yocto"
```
Sau khi chạy lệnh này thì kernel source sẽ được lưu trong thư mục source của workspace 
```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ ls -l
total 796
drwxr-xr-x  27 thanh thanh   4096 Nov 23 13:58 arch
drwxr-xr-x   3 thanh thanh   4096 Nov 23 13:58 block
drwxr-xr-x   2 thanh thanh   4096 Nov 23 13:58 certs
-rw-r--r--   3 thanh thanh    423 Nov 23 13:58 COPYING
-rw-r--r--   1 thanh thanh  99537 Nov 23 13:58 CREDITS
drwxr-xr-x   4 thanh thanh   4096 Nov 23 13:58 crypto
drwxr-xr-x  82 thanh thanh   4096 Nov 23 13:58 Documentation
drwxr-xr-x 138 thanh thanh   4096 Nov 23 13:58 drivers
drwxr-xr-x  78 thanh thanh   4096 Nov 23 13:58 fs
drwxr-xr-x  27 thanh thanh   4096 Nov 23 13:58 include
drwxr-xr-x   2 thanh thanh   4096 Nov 23 13:58 init
drwxr-xr-x   2 thanh thanh   4096 Nov 23 13:58 ipc
-rw-r--r--   1 thanh thanh   1321 Nov 23 13:58 Kbuild
-rw-r--r--   1 thanh thanh    595 Nov 23 13:58 Kconfig
drwxr-xr-x  18 thanh thanh   4096 Nov 23 13:58 kernel
drwxr-xr-x  18 thanh thanh  12288 Nov 23 13:58 lib
drwxr-xr-x   6 thanh thanh   4096 Nov 23 13:58 LICENSES
-rw-r--r--   1 thanh thanh 529809 Nov 23 13:58 MAINTAINERS
-rw-r--r--   1 thanh thanh  62429 Nov 23 13:58 Makefile
drwxr-xr-x   3 thanh thanh   4096 Nov 23 13:58 mm
drwxr-xr-x  70 thanh thanh   4096 Nov 23 13:58 net
-rw-r--r--   1 thanh thanh    727 Nov 23 13:58 README
drwxr-xr-x  29 thanh thanh   4096 Nov 23 13:58 samples
drwxr-xr-x  15 thanh thanh   4096 Nov 23 13:58 scripts
drwxr-xr-x  12 thanh thanh   4096 Nov 23 13:58 security
-rw-r--r--   1 thanh thanh      0 Nov 23 21:31 singletask.lock
drwxr-xr-x  26 thanh thanh   4096 Nov 23 13:58 sound
drwxr-xr-x  35 thanh thanh   4096 Nov 23 13:58 tools
drwxr-xr-x   3 thanh thanh   4096 Nov 23 13:58 usr
drwxr-xr-x   4 thanh thanh   4096 Nov 23 13:58 virt
```
## 2.2. Tạo một kernel module mới 
Tạo một thư mục helloworld trong thư mục *sources/linux-yocto/drivers/*
```bash
~/yocto/poky/build/workspace/sources/linux-yocto/drivers$ mkdir helloworld
```
Đây là nơi chứa source code của helloworld kernel module
## 2.3. Thêm source code cho module
### 2.3.1.  Tạo file helloworld.c
```bash
~/yocto/poky/build/workspace/sources/linux-yocto/drivers/helloworld$ touch helloworld.c
```
Viết một chương trình kernel module đơn giản 

```
#include <linux/module.h>  /* Thu vien nay dinh nghia cac macro nhu module_init va module_exit */
#include <linux/fs.h>      /* Thu vien nay dinh nghia cac ham allocate major & minor number */

#define DRIVER_AUTHOR "helloworld xxxxxxxx@gmail.com"
#define DRIVER_DESC   "Hello world kernel module in yocto"
#define DRIVER_VERS   "1.0"

/* Constructor */
static int  __init hello_world_init(void)
{
    printk(KERN_INFO "Hello world kernel module in yocto new\n");
    return 0;
}

/* Destructor */
static void  __exit hello_world_exit(void)
{
    printk(KERN_INFO "Goodbye helloworld kernel module in yocto\n");
}

module_init(hello_world_init);
module_exit(hello_world_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR(DRIVER_AUTHOR);
MODULE_DESCRIPTION(DRIVER_DESC);
MODULE_VERSION(DRIVER_VERS);
```
### 2.3.2. Tạo Kconfig
Thêm một file Kconfig trong thư mục helloworld
```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ cat drivers/helloworld/Kconfig
config HELLOWORLD
    tristate "Hello World Kernel Module"
    default y
    help
      This is a built-in Hello World kernel module.
```
### 2.3.3. Tạo Makefile
Tạo  1 file Makefile trong thư mục helloworld
```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ cat drivers/helloworld/Makefile
obj-$(CONFIG_HELLO_WORLD) += helloworld.o
```
## 2.4. Sửa file Kconfig và Makefile ở drivers/
Trong thư mục drivers/ thêm dòng sau vào file Kconfig
```
source "drivers/helloworld/Kconfig"
```

Thêm dòng sau vào file Makefile ( built-in) 
```
obj-y += helloworld/
```
## 2.5. Build 
Build laij kernel và image
```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ devtool build linux-yocto
```

```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ bitbake core-image-minimal
```

## 2.6. Kiểm tra kết quả
Chạy thử image trên qemu và kiểm tra bằng lệnh dmesg xem có log lúc init không 

```bash
~/yocto/poky/build/workspace/sources/linux-yocto/drivers$ runqemu qemux86 core-image-minimal nographic
```
```bash
root@qemux86:~# dmesg | tail -100 | grep Hello
[    4.308025] Hello world kernel module in yocto new
root@qemux86:~#
```

## 2.7. finish
Sau khi kiểm tra thấy đã có module, chúng ta có thể kết thúc việc chỉnh sửa kernel theo các bước sau
### 2.7.1. Commit change
Commit các thay đổi trên source của kernel
```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ git status
On branch v5.4/standard/base
Your branch is behind 'origin/v5.4/standard/base' by 802 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   drivers/Kconfig
        modified:   drivers/Makefile

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        drivers/helloworld/

no changes added to commit (use "git add" and/or "git commit -a")
```

```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ git add .
```

```bash
~/yocto/poky/build/workspace/sources/linux-yocto$ git commit -m "Lear Yocto: Add kernel module helloworld"
[v5.4/standard/base 82d729b6020e] Lear Yocto: Add kernel module helloworld
 5 files changed, 37 insertions(+)
 create mode 100644 drivers/helloworld/Kconfig
 create mode 100644 drivers/helloworld/Makefile
 create mode 100644 drivers/helloworld/helloworld.c
 ```
 
 ### 2.7.2. devtool finish
 Dùng devtool finish để tạo ra bản vá lưu vào layer trong mục 1 đã tạo
 ```bash
 ~/yocto/poky/build/workspace/sources/linux-yocto$ devtool finish linux-yocto ~/yocto/poky/meta-kernelmodule
NOTE: Starting bitbake server...
NOTE: Reconnecting to bitbake server...
NOTE: Previous bitbake instance shutting down?, waiting to retry...
NOTE: Retrying server connection (#1)...
Loading cache: 100% |#############################################################################################################################################################################| Time: 0:00:00
Loaded 1333 entries from dependency cache.
Parsing recipes: 100% |###########################################################################################################################################################################| Time: 0:00:00
Parsing of 777 .bb files complete (776 cached, 1 parsed). 1333 targets, 41 skipped, 0 masked, 0 errors.
INFO: Would remove config fragment /tmp/devtoolodvggopi/tmpg51drl39/devtool-fragment.cfg
NOTE: Writing append file /home/thanh/yocto/poky/meta-kernelmodule/recipes-kernel/linux/linux-yocto_%.bbappend
NOTE: Copying 0001-Lear-Yocto-Add-kernel-module-helloworld.patch to /home/thanh/yocto/poky/meta-kernelmodule/recipes-kernel/linux/linux-yocto/0001-Lear-Yocto-Add-kernel-module-helloworld.patch
INFO: Cleaning sysroot for recipe linux-yocto...
INFO: Leaving source tree /home/thanh/yocto/poky/build/workspace/sources/linux-yocto as-is; if you no longer need it then please delete it manually
 ```
 Check trong thư mục *meta-kernelmodule/*
 ```bash
 ~/yocto/poky/meta-kernelmodule$ tree
.
├── conf
│   └── layer.conf
├── COPYING.MIT
├── README
├── recipes-example
│   └── example
│       └── example_0.1.bb
└── recipes-kernel
    └── linux
        ├── linux-yocto
        │   └── 0001-Lear-Yocto-Add-kernel-module-helloworld.patch
        └── linux-yocto_%.bbappend
```

# 3. Kết Luận
Bài viết hôm nay mình và các bạn đã cùng nhau tìm hiểu cách thêm một kernel module vào kernel bằng cách sử dụng devtool. Mong các bạn góp ý thêm.
