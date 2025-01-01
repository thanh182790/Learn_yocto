FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://devtool-fragment.cfg \
            file://0001-Add-SPI-protocol-driver-for-Nokia5110.patch \
            file://0001-Add-i2c-module.patch \
            "

