#!/usr/bin/env bash

# Fetch & build mkbootimg
git clone https://github.com/osm0sis/mkbootimg.git
cd mkbootimg
git checkout 17cea80bd5af64e45cdf9e263cad7555030e0e86
CFLAGS=-Wstringop-overflow=0 make mkbootimg
cd ..

# Fetch U-Boot for Qualcomm SM7150 source code
#git clone https://github.com/sm7150-mainline/u-boot.git
git clone --branch 2025-12-02 --depth 1 https://github.com/sm7150-mainline/u-boot.git
cd u-boot

# Patch U-Boot. EUD enablment. Leave USB PHY active after leaving Fastboot
git apply ../uboot-patch-enable-eud-fastboot.patch

# Configure U-Boot
#make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig qcom-phone.config tauchgang.config
cp ../tauchgang-eud-only.config configs/
make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig qcom-phone.config tauchgang-eud-only.config

# Build U-Boot qcom/sm7150-xiaomi-surya-tianma
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j$(nproc) CONFIG_DEFAULT_DEVICE_TREE=qcom/sm7150-xiaomi-surya-tianma

# Assemble Android boot.img
gzip .output/u-boot-nodtb.bin -c > .output/u-boot-nodtb.bin.gz
cat .output/u-boot-nodtb.bin.gz .output/dts/upstream/src/arm64/qcom/sm7150-xiaomi-surya-tianma.dtb > .output/uboot-dtb
          ../mkbootimg/mkbootimg --base '0x0' --kernel_offset '0x00008000' --pagesize '4096' --kernel .output/uboot-dtb -o .output/u-boot-sm7150-xiaomi-surya-tianma-eud-enabler.img