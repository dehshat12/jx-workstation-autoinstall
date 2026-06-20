#!/usr/bin/env bash
set -euo pipefail

PACKAGE="jx-workstation"
VERSION="${JX_VERSION:-0.1.0}"
ARCH="${JX_ARCH:-arm64}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${REPO_ROOT}/build/${PACKAGE}"
PKGROOT="${BUILD_DIR}/pkgroot"
DEBIAN_DIR="${PKGROOT}/DEBIAN"
DIST_DIR="${REPO_ROOT}/dist"
DEB_PATH="${DIST_DIR}/${PACKAGE}_${VERSION}_${ARCH}.deb"

host_arch="$(dpkg --print-architecture)"
if [[ "${host_arch}" != "${ARCH}" ]]; then
    printf 'warning: building Architecture=%s on host architecture %s\n' "${ARCH}" "${host_arch}" >&2
fi

rm -rf -- "${BUILD_DIR}"
install -d -m 0755 "${DEBIAN_DIR}" "${DIST_DIR}"

cd "${REPO_ROOT}"
make -B all
make install install-service DESTDIR="${PKGROOT}"

install -d -m 0755 "${PKGROOT}/opt/jx/bin" "${PKGROOT}/opt/jx/share/icons" "${PKGROOT}/usr/share/doc/${PACKAGE}"
install -m 0755 jx-apply-branding "${PKGROOT}/opt/jx/bin/jx-apply-branding"
install -m 0755 jx-restore-ubuntu-branding "${PKGROOT}/opt/jx/bin/jx-restore-ubuntu-branding"
install -m 0644 assets/jx-os.png "${PKGROOT}/opt/jx/share/icons/jx-logo.png"
install -m 0644 "${SCRIPT_DIR}/README.md" "${PKGROOT}/usr/share/doc/${PACKAGE}/README.md"

sed \
    -e "s/^Version: .*/Version: ${VERSION}/" \
    -e "s/^Architecture: .*/Architecture: ${ARCH}/" \
    "${SCRIPT_DIR}/control" > "${DEBIAN_DIR}/control"
awk 'NF { print }' "${SCRIPT_DIR}/conffiles" > "${DEBIAN_DIR}/conffiles"
install -m 0755 "${SCRIPT_DIR}/postinst" "${DEBIAN_DIR}/postinst"
install -m 0755 "${SCRIPT_DIR}/prerm" "${DEBIAN_DIR}/prerm"
install -m 0755 "${SCRIPT_DIR}/postrm" "${DEBIAN_DIR}/postrm"

installed_size="$(du -sk "${PKGROOT}" | awk '{print $1}')"
awk -v size="${installed_size}" '
    /^Installed-Size:/ { next }
    /^Description:/ && !done {
        print "Installed-Size: " size
        done = 1
    }
    { print }
' "${DEBIAN_DIR}/control" > "${DEBIAN_DIR}/control.tmp"
mv "${DEBIAN_DIR}/control.tmp" "${DEBIAN_DIR}/control"

fakeroot dpkg-deb --build --root-owner-group "${PKGROOT}" "${DEB_PATH}"
printf 'Built %s\n' "${DEB_PATH}"
