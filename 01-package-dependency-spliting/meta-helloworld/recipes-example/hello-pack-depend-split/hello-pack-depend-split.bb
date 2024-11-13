DESCRIPTION = "Simple program to simulation package dependencies and spliting"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

S = "${WORKDIR}"
SRC_URI = "file://hello_depen.c \
           file://hello_pack_split.c \
           file://hello_run_time_depen.c \
           file://Makefile"

EXTRA_OEMAKE = "CC='${CC}' CFLAGS='${CFLAGS} -Wl,--hash-style=gnu'"

PACKAGES =+ "hello_depen hello_pack_split hello_run_time_depen"

FILES_hello_depen = "${bindir}/hello_depen"
FILES_hello_pack_split = "${bindir}/hello_pack_split"
FILES_hello_run_time_depen = "${bindir}/hello_run_time_depen"

DEPENDS = "curl"
RDEPENDS_${PN} = "bash"
RDEPENDS_hello_run_time_depen = "bash"

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
