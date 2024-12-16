Tiếp nối chuỗi bài viết về yocto thì chúng ta sẽ cùng nhau tìm hiểu về packages dependencies và packages splitting trong yocto.

Trong yocto, khi xây dựng các hệ thống nhúng hay các bản phân phối cho linux thì việc quản lý các package phụ thuộc và phân 
chia các package là vô cùng quan trọng. Nó giúp ich tối ưu hóa và linh hoạt trong việc tạo ra các thành phần của image.

# 1. Package dependencies
**Package dependencies** là các yêu cầu cần thiết cho một gói có thể hoạt động bình thường. Nếu một gói cần thư viện, một số gói khác
thí yocto sẽ đảm bảo các yêu cầu đó được thiết lập trước hoặc sau khi build package. 

Có hai loại phụ thuộc trong yocto là 
- build time dependencies
-  run time dependencies
- Phụ thuộc run time: một số package lúc chạy sẽ cần một số thư viện để có thể hoạt động bình thường. Lúc này yocto cần thiết lập các thư viện cần thiết đó.
## 1.1. Build time dependencis
Tại thời điểm build package, một số thư viện hoặc package khác sẽ cần để đàm bảo build process diễn ra bình thường. Yocto sẽ đảm bảo các yêu cầu đó có sẵn tại thời điểm build. Trong yocto, biến *DEPENDS* được sử dụng để chỉ định các gói, thư viện cần thiết cho quá trình build. 

Để hiểu rõ hơn về package dependencies, chúng ta hay cùng lấy 1 ví dụ. Trong bài trước chúng ta đã [Tạo một layer helloword đơn giản trong yocto](https://devlinux.vn/post/tao-layer-don-gian-va-them-chuong-trinh-helloworld), hôm nay mình sẽ thêm 1 recipe mới *hello-pack-depend-split* vào layer này để làm ví dụ. 
### 1.1.1. Khởi tạo môi trường
```bash 
~/yocto/poky$ source oe-init-build-env
```

### 1.1.2. Tạo mã nguồn và file recipe
Tiếp theo tạo một thư mục chứa recipe *hello-pack-depend-split* trong *meta-helloworld* và thêm source code, file .bb
```bash
~/yocto/poky/meta-helloworld/recipes-example$ mkdir hello-pack-depend-split
~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ tree
.
├── files
│   ├── hello_depen.c
│   ├── hello_pack_split.c
│   ├── hello_run_time_depen.c
│   └── Makefile
└── hello-pack-depend-split.bb
```

Sourc code và makefile của demo như sau 
```bash
/*hello_depen.c*/
#include <stdio.h>
#include <curl/curl.h>

int main(void)
{
  CURL *curl;
  CURLcode res;

  curl = curl_easy_init();
  if(curl) {
        printf("Init curl OK\n");
        printf("In file %s\n",__FILE__);
    curl_easy_cleanup(curl);
  }
  return 0;
}
```

```bash
/* hello_pack_split.c */
#include <stdio.h>
#include <curl/curl.h>

int main(void)
{
  CURL *curl;
  CURLcode res;

  curl = curl_easy_init();
  if(curl) {
    printf("Init curl OK\n");
        printf("In file %s\n", __FILE__);
    curl_easy_cleanup(curl);
  }
  return 0;
}
```

```bash
/* hello_run_time_depen.c */
#include <stdio.h>
#include <curl/curl.h>

int main(void)
{
  CURL *curl;
  CURLcode res;

  curl = curl_easy_init();
  if(curl) {
    printf("Init curl OK\n");
    printf("In file %s\n", __FILE__);
    curl_easy_cleanup(curl);
  }
  int status = system("bash -c 'echo This is executed by bash at runtime!'");

  if (status == -1) {
    perror("Failed to run bash command");
        return 1;
  }

  return 0;
}
```

```bash
~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ cat files/Makefile
CC = gcc
CFLAGS = -Wall

all: hello_depen hello_pack_split hello_run_time_depen

hello_depen: hello_depen.c
        $(CC) hello_depen.c $(CFLAGS) -lcurl -o hello_depen

hello_pack_split: hello_pack_split.c
        $(CC) hello_pack_split.c  $(CFLAGS) -lcurl -o hello_pack_split

hello_run_time_depen: hello_run_time_depen.c
        $(CC) hello_run_time_depen.c $(CFLAGS) -lcurl -o hello_run_time_depen

clean:
        rm -f hello_depen hello_pack_split hello_run_time_depen
```

Trong ví dụ trên, mã nguồn demo đang dùng thư viện *libcurl*. Do đó để build được source thì chúng ta phải thêm flag *-lcurl*.

File .bb 
```bash
~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ cat hello-pack-depend-split.bb
DESCRIPTION = "Simple program to simulation package dependencies and spliting"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

S = "${WORKDIR}"
SRC_URI = "file://hello_depen.c \
           file://hello_pack_split.c \
           file://hello_run_time_depen.c \
           file://Makefile"

#DEPENDS = "curl"

EXTRA_OEMAKE = "CC='${CC}' CFLAGS='${CFLAGS} -Wl,--hash-style=gnu'"
# Các bước để build
do_compile() {
    oe_runmake
}

do_install() {
    # Cài đặt các file nhị phân vào thư mục tương ứng
    install -d ${D}${bindir}
    install -m 0755 hello_depen ${D}${bindir}/hello_depen
    install -m 0755 hello_pack_split ${D}${bindir}/hello_pack_split
    install -m 0755 hello_run_time_depen ${D}${bindir}/hello_run_time_depen
}
```

### 1.1.3. Build recipe
```bash 
~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ bitbake hello-pack-depend-split
...
ERROR: hello-pack-depend-split-1.0-r0 do_compile: oe_runmake failed
ERROR: hello-pack-depend-split-1.0-r0 do_compile: Execution of '/home/thanh/yocto/poky/build/tmp/work/core2-64-poky-linux/hello-pack-depend-split/1.0-r0/temp/run.do_compile.439825' failed with exit code 1
ERROR: Logfile of failure stored in: /home/thanh/yocto/poky/build/tmp/work/core2-64-poky-linux/hello-pack-depend-split/1.0-r0/temp/log.do_compile.439825
...
         -fdebug-prefix-map=/home/thanh/yocto/poky/build/tmp/work/core2-64-poky-linux/hello-pack-depend-split/1.0-r0/recipe-sysroot-native=  -Wl,--hash-style=gnu -lcurl -o hello_run_time_depen
| hello_pack_split.c:2:10: fatal error: curl/curl.h: No such file or directory
|     2 | #include <curl/curl.h>
|       |          ^~~~~~~~~~~~~
| hello_run_time_depen.c:2:10: fatal error: curl/curl.h: No such file or directory
|     2 | #include <curl/curl.h>
|       |          ^~~~~~~~~~~~~
| hello_depen.c:2:10: fatal error: curl/curl.h: No such file or directory
|     2 | #include <curl/curl.h>
|       |          ^~~~~~~~~~~~~
| compilation terminated.
| compilation terminated.
| compilation terminated.
| make: *** [Makefile:10: hello_pack_split] Error 1
| make: *** Waiting for unfinished jobs....
| make: *** [Makefile:7: hello_depen] Error 1
| make: *** [Makefile:13: hello_run_time_depen] Error 1
| ERROR: oe_runmake failed
| WARNING: exit code 1 from a shell command.
| ERROR: Execution of '/home/thanh/yocto/poky/build/tmp/work/core2-64-poky-linux/hello-pack-depend-split/1.0-r0/temp/run.do_compile.439825' failed with exit code 1
ERROR: Task (/home/thanh/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split/hello-pack-depend-split.bb:do_compile) failed with exit code '1'
```

Khi build recipe chúng ta sẽ nhận được một thông báo lỗi không tìm thấy file curl.h. Bởi vì trong mã nguồn chúng ta có dùng thư viện đó, makefile có chỉ định nhưng yocto chưa thiết lập thư viện đó trước khi thực hiện task do_compile() nên dẫn đên lỗi. Để sửa lỗi này, uncomment dòng **DEPENDS = "curl"** trong file .bb  rồ i build lại.

### 1.1.4. Build Image, chạy ứng dụng

```bash 
~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ bitbake core-image-minimal
....
~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ runqemu qemux86 core-image-minimal
.....
qemux86 login: root
root@qemux86:~# ls -l /usr/bin/ | grep hello_
-rwxr-xr-x    1 root     root         14296 Mar  9  2018 hello_app
-rwxr-xr-x    1 root     root         14424 Mar  9  2018 hello_depen
-rwxr-xr-x    1 root     root         14432 Mar  9  2018 hello_pack_split
-rwxr-xr-x    1 root     root         14456 Mar  9  2018 hello_run_time_depen
root@qemux86:~# /usr/bin/hello_depen
Init curl OK
In file hello_depen.c
root@qemux86:~# /usr/bin/hello_pack_split
Init curl OK
In file hello_pack_split.c
root@qemux86:~#
```
Như kết quả cho thấy ứng dụng đã chạy ok.
## 1.2. Run time dependencis
Tức là các gói, thư viện cần thiết cho một gói khác khi đang chạy. Trong yocto, biến *RDEPENDS* được sử dụng để chỉ định các thư viện, package cần thiết lúc run time.

Ở ví dụ trên, trong file *hello_run_time_depen.c* mình có sử dụng thư viện *bash* để chạy 1 lệnh bash thông qua function system(). Tuy nhiên trong file .bb lại không báo cho yocto biết để thiết lập lúc runtime. Điều này dẫn đến chương trình chạy sẽ bị lỗi như dưới.

```bash
root@qemux86:~# /usr/bin/hello_run_time_depen
Init curl OK
In file hello_run_time_depen.c
sh: bash: not found
root@qemux86:~#
```

Thêm biến **RDEPENDS_${PN} = "bash"** để yocto biết cần thiết lâp thư viện bash lúc runtime.
Build lại image và kiểm tra kết quả
```bash
root@qemux86:~# /usr/bin/hello_run_time_depen
Init curl OK
In file hello_run_time_depen.c
This is executed by bash at runtime!
root@qemux86:~#
```

# 2. Package splitting
Trong ví dụ trên, khi build recipe và tích hợp package của *hello-pack-depend-split* vào image va khi chạy ứng dụng lên chúng ta thấy rằng cả 3 file bin trong package đều tồn tại trên system. Trong một số trường hợp chúng ta không cần thiết phải cài đặt tất cả các ứng dụng của package lên image . Điều này giúp tối ưu hóa việc phân phối, cài đặt và bảo trì hệ thống. Quá trình này rất quan trọng khi  tối ưu hóa dung lượng hệ thống hoặc tách biệt các phần của ứng dụng để dễ dàng cập nhật và quản lý. Do đó, Package splitting có nhiệm vụ để chia tách một package gốc thành các package con.

 Chúng ta có thể sử dụng biến PACKAGES và FILES để chia nhỏ 1 package ra thành các package con. 
 ```bash
 ~/yocto/poky/meta-helloworld/recipes-example/hello-pack-depend-split$ cat hello-pack-depend-split.bb
DESCRIPTION = "Simple program to simulation package dependencies and spliting"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

S = "${WORKDIR}"
SRC_URI = "file://hello_depen.c \
           file://hello_pack_split.c \
           file://hello_run_time_depen.c \
           file://Makefile"

DEPENDS = "curl"
RDEPENDS_${PN} = "bash"
RDEPENDS_hello_run_time_depen = "bash"

EXTRA_OEMAKE = "CC='${CC}' CFLAGS='${CFLAGS} -Wl,--hash-style=gnu'"

PACKAGES =+ "hello_depen hello_pack_split hello_run_time_depen"

FILES_hello_depen = "${bindir}/hello_depen"
FILES_hello_pack_split = "${bindir}/hello_pack_split"
FILES_hello_run_time_depen = "${bindir}/hello_run_time_depen"

# Các bước để build
do_compile() {
    oe_runmake
}

do_install() {
    # Cài đặt các file nhị phân vào thư mục tương ứng
    install -d ${D}${bindir}
    install -m 0755 hello_depen ${D}${bindir}/hello_depen
    install -m 0755 hello_pack_split ${D}${bindir}/hello_pack_split
    install -m 0755 hello_run_time_depen ${D}${bindir}/hello_run_time_depen
}
 ```
 
 Sửa file local.conf để chỉ install package *hello_run_time_depen*
 ```
 #IMAGE_INSTALL_append = " hello-pack-depend-split"
IMAGE_INSTALL_append = " hello_run_time_depen"
 ```
 Kết quả chạy thử, thấy rằng trên target chỉ có file hello_run_time_depen như mong muốn.
 ```bash
 qemux86-64 login:root
root@qemux86-64:~# ls -l /usr/bin/hell*
-rwxr-xr-x    1 root     root         14296 Mar  9  2018 /usr/bin/hello_app
-rwxr-xr-x    1 root     root         14456 Mar  9  2018 /usr/bin/hello_run_time_depen
-rwxr-xr-x    1 root     root         14296 Mar  9  2018 /usr/bin/helloworld
root@qemux86-64:~# /usr/bin/hello_run_time_depen
Init curl OK
In file hello_run_time_depen.c
This is executed by bash at runtime!
root@qemux86-64:~#
 ```

# 3. Kết luận
Qua bài viết chúng ta có thể hiểu được hai khái niệm package dependencies và package splitting và demo để hiểu được cách hoạt động của chúng.
Kiến thức để viết bài viết này của mình còn hạn chế. Nếu mọi người có đóng góp gì xin hãy để lại comment bên dưới.

