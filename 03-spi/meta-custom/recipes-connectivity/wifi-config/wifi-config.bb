SUMMARY = "WiFi configuration script"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wifi_config.sh"

S = "${WORKDIR}"
# add depen for script
RDEPENDS_${PN} += "bash"
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/wifi_config.sh ${D}${bindir}/wifi_config.sh
}

FILES:${PN} = "${bindir}/wifi_config.sh"

