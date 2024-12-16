Ở các bài viết trước chúng ta đã tìm hiểu về cách tạo một layer đơn giản trên yocto và chạy giả lập trên QEMU.
Để tiếp nối seris về yocto, hôm nay chúng ta cùng tìm hiểu về devtool - một công cụ hỗ trợ mạnh mẽ trong yocto.

# 1. Tổng quan về devtool
Devtool là một công cụ trong yocto. Nó được sinh ra nhằm giúp cho developers dễ dàng tạo ra , chỉnh sửa và update các recipe 
nhanh chóng thay vì làm manual. Bên cạnh đó nó cũng giúp chúng ta build, test các package software sau khi chỉnh sửa source
code để có thể tích hợp vao image sau cùng.

Sau khi clone source code của yocto về để có thể sử dụng devtool thì đầu tiên chúng ta phải thiết lập môi trường trong yocto bằng
lệnh sau:
``` bash
~/yocto/poky$ source oe-init-build-env
```

Dùng lệnh sau để xem hướng dẫn chi tiết các subcommand trong devtool
```bash
~/yocto/poky/build$ devtool -h
NOTE: Starting bitbake server...
usage: devtool [--basepath BASEPATH] [--bbpath BBPATH] [-d] [-q] [--color COLOR] [-h] <subcommand> ...

OpenEmbedded development tool

options:
  --basepath BASEPATH   Base directory of SDK / build directory
  --bbpath BBPATH       Explicitly specify the BBPATH, rather than getting it from the metadata
  -d, --debug           Enable debug output
  -q, --quiet           Print only errors
  --color COLOR         Colorize output (where COLOR is auto, always, never)
  -h, --help            show this help message and exit

subcommands:
  Beginning work on a recipe:
    add                   Add a new recipe
    modify                Modify the source for an existing recipe
    upgrade               Upgrade an existing recipe
[...]
```
Trong bài viết này, chúng ta sẽ tập trung vào một số command phổ biến được trình bày trong mục 2.
# 2. Các command phổ biến của devtool
## 2.1. devtool add
Lệnh này sẽ giúp tạo ra một recipe mới từ một mã nguồn có sẵn từ local hoặc trên sever. Sau khi chạy lệnh này 
một thư mục **workspace** sẽ được tạo ra. Devtool sẽ lưu các thông tin của source code và các recipe trong 
thư mục này.
Trong ví dụ này mình sẽ tạo ra một recipe mới có tên là *hello-devtool* từ source code trên github. Trong trường hợp không
chỉ định rõ branch thì mặc định devtool sẽ clone từ master.
```bash
~/yocto/poky/build$ devtool add hello-devtool https://github.com/thanh182790/Learn_yocto.git --srcbranch main
```
Như đã nói ở trên sau khi chạy xong lệnh này một recipe mới sẽ được tao trong thư mục **poky/build/workspace/recipes/...**

```bash
~/yocto/poky/build$ tree -L 1 workspace/
workspace/
├── appends     # Lưu các thay đôi khi modify hoặc upgrade
├── conf            # Lưu các config 
├── README
├── recipes       # Lưu lại các recipe mơi khi tạo
└── sources      # source code được lưu tại đây. Nếu bạn dùng src local thì folder này sẽ không có trong workspace

~/yocto/poky/build/workspace$ cat sources/hello-devtool/00-devtool/hello_devtool.c
#include <stdio.h>

int main()
{
        printf("Hello Devtool\n.");
        return 0;
}
```
Sau khi tạo recipe bằng devtool, nội dung trong file hello-devtool_git.bb sẽ được tự động gen 
```bash
~/yocto/poky/build/workspace/recipes/hello-devtool$ cat hello-devtool_git.bb
# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# Unable to find any files that looked like license statements. Check the accompanying
# documentation and source headers and set LICENSE and LIC_FILES_CHKSUM accordingly.
#
# NOTE: LICENSE is being set to "CLOSED" to allow you to at least start building - if
# this is not accurate with respect to the licensing of the software being built (it
# will not be in most cases) you must specify the correct value before using this
# recipe for anything other than initial testing/development!
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "git://github.com/thanh182790/Learn_yocto.git;protocol=https;branch=main"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "f029d58f4fb74193e5961defe59a484255fefede"

S = "${WORKDIR}/git"

# NOTE: no Makefile found, unable to determine what needs to be done

do_configure () {
        # Specify any needed configure commands here
        :
}

do_compile () {
        # Specify compilation commands here
        :
}

do_install () {
        # Specify install commands here
        :
}
```
## 2.2. devtool build
Lệnh này sẽ được dùng để build recipe để ra các package software rồi kiểm thử xem nó chạy có đúng không. Để kiểm thử ta có 
thể dùng lệnh deploy ( sẽ tìm hiểu sau).
Bên cạnh đó chúng ta cũng có thể build image bằng lệnh devtool build-imagge image_name
Để build được recipe chúng ta cần chỉnh sửa một chút file .bb theo như câu trúc source code hiện tại dưới local
```bash
~/yocto/poky/build/workspace/recipes/hello-devtool$ cat hello-devtool_git.bb
# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# Unable to find any files that looked like license statements. Check the accompanying
# documentation and source headers and set LICENSE and LIC_FILES_CHKSUM accordingly.
#
# NOTE: LICENSE is being set to "CLOSED" to allow you to at least start building - if
# this is not accurate with respect to the licensing of the software being built (it
# will not be in most cases) you must specify the correct value before using this
# recipe for anything other than initial testing/development!
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "git://github.com/thanh182790/Learn_yocto.git;protocol=https;branch=main"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "f029d58f4fb74193e5961defe59a484255fefede"

S = "${WORKDIR}/git"

# NOTE: no Makefile found, unable to determine what needs to be done


do_compile () {
        # Specify compilation commands here
    ${CC} ${S}/00-devtool/hello_devtool.c ${LDFLAGS} -o ${S}/00-devtool/hello_devtool
}

do_install () {
        # Specify install commands here
    install -d ${D}${bindir}
    install -m 0755 ${S}/00-devtool/hello_devtool ${D}${bindir}
}
```

```bash
~/yocto/poky/build/workspace$ devtool build hello-devtool
...
NOTE: hello-devtool: compiling from external source tree /home/thanh/yocto/poky/build/workspace/sources/hello-devtool
NOTE: Tasks Summary: Attempted 531 tasks of which 526 didn't need to be rerun and all succeeded.
```
Thư mục workspae/ sau khi build trông như sau:
```bash
~/yocto/poky/build/workspace$ tree
.
├── appends
│   └── hello-devtool_git.bbappend
├── conf
│   └── layer.conf
├── README
├── recipes
│   └── hello-devtool
│       └── hello-devtool_git.bb
└── sources
    └── hello-devtool
        ├── 00-devtool
        │   ├── hello_devtool
        │   └── hello_devtool.c
        ├── oe-logs -> /home/thanh/yocto/poky/build/tmp/work/core2-32-poky-linux/hello-devtool/1.0+git999-r0/temp
        └── oe-workdir -> /home/thanh/yocto/poky/build/tmp/work/core2-32-poky-linux/hello-devtool/1.0+git999-r0

9 directories, 6 files
```

Để có thể test được xem app này có chạy được trên máy target hay không chúng ta có thể thử bằng cách build image có chứa 
recipe này.
Mở file conf/local.conf trong thư mục build/conf và thêm ứng dụng vào danh sách các ứng dụng sẽ được xây dựng
```bash
IMAGE_INSTALL_append = " hello-devtool"
```
Sau đó buidl lại image và test trên qemu
```bash
bitbake core-image-minimal

bitbake -e core-image-minimal | grep IMAGE_INSTALL  # kiểm tra xem có hello-devtool trong image không

runqemu qemux86 core-image-minimal nographic
qemux86 login: root
root@qemux86:~# /usr/bin/hello_devtool
Hello Devtool
```

## 2.3. devtool deploy
Ở lệnh trên chúng ta đang build lại cả một image rồi test nó trên qemu. Trong trường hợp nếu bạn chỉ cần kiểm tra software của recipe
bạn thêm vào sau khi build recipe đó thì ta dùng lệnh devtool deploy.
Để có thể deploy lên máy target thì yêu cầu cần thiết là từ máy local của chúng ta phải ssh được sang target.

Trong ví dụ này, mình sẽ dùng qemu để thử. Trước tiên cần thêm openssh vào image của chúng ta.
```bash
IMAGE_INSTALL_append = " openssh"
```
Sau đó, build lại core-image-minimal. Chạy qemu với image đó. Hiện tại khi chưa deploy thì không tim thấy file hello_devtool.
```bash
root@qemux86:~# ls -l /usr/bin/ | grep hello
-rwxr-xr-x    1 root     root         14296 Mar  9  2018 helloworld
root@qemux86:~#
```
Để deploy được recipe lên máy target thì chúng ta dùng lệnh sau

```bash
~/yocto/poky/build/workspace$ devtool deploy-target hello-devtool root@192.168.7.2
# hello-devtool là tên recipe
# root@192.168.7.2 là username và địa chỉ ip máy target
```
Sau khi deploy chúng ta có thể kiểm tra trên máy target xem có fie hello_devtool chưa.
```bash
root@qemux86:~# ls -l /usr/bin/ | grep hello
-rwxr-xr-x 1 root root   13640 Mar  9  2018 /usr/bin/hello_devtool
-rwxr-xr-x 1 root root   13636 Mar  9  2018 helloworld
root@qemux86:~# /usr/bin/hello_devtool
Hello Devtool
.root@qemux86:~#
```
Để undeploy dùng lệnh sau
```bash
~/yocto/poky/build/workspace$ devtool undeploy-target hello-devtool root@192.168.7.2
NOTE: Starting bitbake server...
INFO: Successfully undeployed hello-thanh
```
## 2.4. devtool finish
Sau khi build và test image ok, chúng ta sẽ muốn thêm recipe này vào một meta-layer trong poky. Ví dụ, trong bài viết trước
chúng ta có tạo ra một layer *helloworld*  nay mình sẽ thêm recipe mới này vào layer đó.
Dùng lệnh sau để thêm
```bash
~/yocto/poky/build/workspace/sources/hello-devtool$ devtool finish -f hello-devtool ../meta-helloworld/recipes-example/
```
Sau khi thêm thành công sẽ có 1 recipe xuất hiện trong meta-helloworld 
```bash
### Trước khi thêm
~/yocto/poky$ tree meta-helloworld/
meta-helloworld/
├── conf
│   └── layer.conf
├── COPYING.MIT
├── README
└── recipes-example
    ├── example
    │   └── example_0.1.bb
    └── helloworld
        ├── files
        │   └── helloworld.c
        └── helloworld.bb

	### sau khi thêm 
~/yocto/poky$ tree meta-helloworld/
meta-helloworld/
├── conf
│   └── layer.conf
├── COPYING.MIT
├── README
└── recipes-example
    ├── example
    │   └── example_0.1.bb
    ├── hello-thanh
    │   └── hello-devtool_git.bb
    └── helloworld
        ├── files
        │   └── helloworld.c
        └── helloworld.bb

```
## 2.5. devtool modify
Lệnh này cho phép chúng ta có thể chỉnh sửa một recipe đã tồn tại trong 1 layer nào đó dưới local ( ý là sẽ thay đổi source code của recipe đó). Recipe này nằm ngoài folder workspace của devtool. Giả sử bây giờ mình muốn chỉnh sửa lại source code của recipe hello-devtool rồi build image thì làm như sau.

Đầu tiên, dùng devtool modify để clone source từ github về workspace
```bash
~/yocto/poky/build$ devtool modify hello-devtool

# Sau khi chạy lệnh này thì devtool sẽ tạo ra một worksapce ( không có recipe vì recipe đã tồn tại trong layer helloworld rồi)
~/yocto/poky/build/workspace$ tree
.
├── appends
│   └── hello-devtool_git.bbappend
├── conf
│   └── layer.conf
├── README
└── sources
    └── hello-devtool
        └── 00-devtool
            └── hello_devtool.c
```
Chỉnh sửa source code 
```
#include <stdio.h>

int main()
{
        printf("Hello Devtool.\n");
        printf("This line edit in devtool modify.\n");
        return 0;
}
```

Sau đó thưc hiện build lại và test như các bước trên.
```bash
root@qemux86:~# /usr/bin/hello_devtool
Hello Devtool.
This line edit in devtool modify.
root@qemux86:~#
```

Sau đó dùng lệnh devtool finish để kết thúc và ghi kết quả lại vào layer helloworld.
```bash 
~/yocto/poky/build$ devtool finish -f hello-devtool ../meta-helloworld/
```
## 2.6. devtool reset
Giả sử trong quá trình modify, nếu chúng ta cảm thấy không cần thiết thì có thể dùng lệnh này để xóa các thay đổi của bạn.
```bash
devtool reset hello-devtool
```

## 2.7. devtool update-recipe
Lệnh này giúp cho chúng ta có thể update được recipe đã tồn tại trong 1 layer bên ngoài workspace của devtool.
Trong ví dụ mình làm dưới đây minh vẫn tiếp tục dùng recipe *hello-thanh*
Đầu tiên thì chúng ta sẽ cần dùng modify source code của recipe đó.
```bash
~/yocto/poky/build/workspace$ devtool modify hello-devtool
```
```
#include <stdio.h>

int main()
{
        printf("Hello Devtool.\n");
        printf("This line edit in devtool modify.\n");
				printf("This line is changed in devtool update-recipe\n");   /* Thêm dòng code này vào */
        return 0;
}
```
Sau đó commit thay đổi đó lên rồi update lại recipe
```
~/yocto/poky/build/workspace/sources/hello-devtool$ git commit -m "Update-recipe"
```

Tiếp theo sẽ update recipe và xem sự thay đổi trong file hello-devtool_git.bb ở folder meta-helloworld/recipes-example/hello-thanh/
```bash
~/yocto/poky/build/workspace$ devtool update-recipe hello-devtool
.....
INFO: Adding new patch 0001-Update-recipe.patch
INFO: Updating recipe hello-devtool_git.bb
```

Kiêm tra lại trên qemu để xem chương trình có chạy đúng không.
```bash
root@qemux86:~# /usr/bin/hello_devtool
Hello Devtool.
This line edit in devtool modify.
This line is changed in devtool update-recipe
root@qemux86:~#
```

Trên đây là một số công cụ trong devtool giúp tạo, thay đổi , kiểm thử các bản package trước khi tích hợp vào image cuối cùng.

Bài viết của mình vẫn còn nhiều thiếu sót mong mọi người góp ý!!!!


