#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

# ========= Config =========
UBOOT_REPO="https://github.com/sm7150-mainline/u-boot.git"
UBOOT_BRANCH="2025-12-02"
MKBOOTIMG_REPO="https://github.com/osm0sis/mkbootimg.git"
MKBOOTIMG_COMMIT="17cea80bd5af64e45cdf9e263cad7555030e0e86"

CROSS_COMPILE="aarch64-linux-gnu-"
CONFIG_FILE="tauchgang-eud-only.config"
PATCH_FILE="uboot-patch-enable-eud-fastboot.patch"

PAGESIZE=4096
BASE_ADDR=0x0
KERNEL_OFFSET=0x00008000
# ==========================

echo "==> Checking toolchain"
command -v ${CROSS_COMPILE}gcc >/dev/null \
  || { echo "Missing ${CROSS_COMPILE}gcc in PATH"; exit 1; }

echo "==> Fetching mkbootimg"
if [ ! -d mkbootimg ]; then
    git clone "${MKBOOTIMG_REPO}"
fi

pushd mkbootimg >/dev/null
git fetch --all
git checkout "${MKBOOTIMG_COMMIT}"
CFLAGS=-Wstringop-overflow=0 make mkbootimg
popd >/dev/null

echo "==> Fetching U-Boot"
if [ ! -d u-boot ]; then
    git clone --branch "${UBOOT_BRANCH}" --depth 1 "${UBOOT_REPO}"
fi

pushd u-boot >/dev/null

echo "==> Applying EUD fastboot patch (if needed)"
if git apply --reverse --check "../${PATCH_FILE}" 2>/dev/null; then
    echo "    Patch already applied, skipping"
else
    git apply "../${PATCH_FILE}"
fi

echo "==> Installing custom config"
cp "../${CONFIG_FILE}" configs/

build_variant() {
    local panel="$1"
    local dt="qcom/sm7150-xiaomi-surya-${panel}"

    echo "==> Building variant: ${panel}"
    rm -rf .output

    make CROSS_COMPILE="${CROSS_COMPILE}" O=.output \
        qcom_defconfig qcom-phone.config "${CONFIG_FILE}"

    make CROSS_COMPILE="${CROSS_COMPILE}" O=.output -j"$(nproc)" \
        CONFIG_DEFAULT_DEVICE_TREE="${dt}"

    echo "==> Assembling Android boot image for ${panel}"
    gzip -c .output/u-boot-nodtb.bin > .output/u-boot-nodtb.bin.gz

    cat \
        .output/u-boot-nodtb.bin.gz \
        .output/dts/upstream/src/arm64/qcom/sm7150-xiaomi-surya-${panel}.dtb \
        > .output/uboot-dtb

    ../mkbootimg/mkbootimg \
        --base "${BASE_ADDR}" \
        --kernel_offset "${KERNEL_OFFSET}" \
        --pagesize "${PAGESIZE}" \
        --kernel .output/uboot-dtb \
        -o ".output/u-boot-sm7150-xiaomi-surya-${panel}-eud-enabler.img"

    cp ".output/u-boot-sm7150-xiaomi-surya-${panel}-eud-enabler.img" ../
}

# Build both panel variants
build_variant tianma
build_variant huaxing

popd >/dev/null

echo "=================================="
echo "✅ All done. These are your files:"
ls -lh u-boot-sm7150-xiaomi-surya-*-eud-enabler.img
