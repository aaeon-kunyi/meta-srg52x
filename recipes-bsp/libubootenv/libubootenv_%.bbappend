
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://debian/"

do_prepare_build() {
    rm ${S}/debian/control
    cp -r ${WORKDIR}/debian ${S}/
}