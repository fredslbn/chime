#!/bin/bash

SECONDS=0 # builtin bash timer
ZIPNAME="SUPER.KERNEL-CHIME-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
DTC_DIR="$PWD/tc/dtc"
DEFCONFIG="bengal_defconfig"

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
#DTB=$(pwd)/out/arch/arm64/boot/dts/qcom

export ARCH=arm64
export SUBARCH=arm64

############# Needed variables.
export KDIR=$(pwd)
export LINKER="ld"
export PATH="${KDIR}"/gcc32/bin:"${KDIR}"/gcc64/bin:/usr/bin/:${PATH}
export DTC_EXT="${DTC_DIR}/linux-x86/dtc/dtc"
export KBUILD_BUILD_USER="unknown"
export KBUILD_BUILD_HOST="Pancali"
#############

if [ ! -d "${KDIR}/gcc64" ]; then
        curl -sL https://github.com/cyberknight777/gcc-arm64/archive/refs/heads/master.tar.gz | tar -xzf -
        mv "${KDIR}"/gcc-arm64-master "${KDIR}"/gcc64
fi

if [ ! -d "${KDIR}/gcc32" ]; then
	curl -sL https://github.com/cyberknight777/gcc-arm/archive/refs/heads/master.tar.gz | tar -xzf -
        mv "${KDIR}"/gcc-arm-master "${KDIR}"/gcc32
fi

if ! [ -d "$DTC_DIR" ]; then
echo "DTC not found! Cloning to $DTC_DIR..."
if ! git clone -q -b android10-gsi --depth=1 https://android.googlesource.com/platform/prebuilts/misc $DTC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi



#if [[ $1 = "-r" || $1 = "--regen" ]]; then
#make O=out ARCH=arm64 $DEFCONFIG savedefconfig
#cp out/defconfig arch/arm64/configs/$DEFCONFIG
#exit
#fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
   rm -rf out
fi


mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j16 \
    ARCH=arm64 \
    O=out \
    CROSS_COMPILE=aarch64-elf- \
    CROSS_COMPILE_ARM32=arm-eabi- \
    LD="${KDIR}"/gcc64/bin/aarch64-elf-"${LINKER}" \
    AR=aarch64-elf-ar \
    AS=aarch64-elf-as \
    NM=aarch64-elf-nm \
    OBJDUMP=aarch64-elf-objdump \
    OBJCOPY=aarch64-elf-objcopy \
    CC=aarch64-elf-gcc Image dtbo.img 2>&1 | tee log.txt

#if [ -f "out/arch/arm64/boot/Image" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
if [ -f "out/arch/arm64/boot/Image" ]; then
   echo -e "\nKernel compiled succesfully! Zipping up...\n"
   
   git clone --depth=1 https://github.com/missgoin/AnyKernel3.git

   cp $IMAGE AnyKernel3
   cp $DTBO AnyKernel3
   #find $DTB -name "*.dtb" -exec cat {} + > AnyKernel3/dtb
	
   # Zipping and Push Kernel
   cd AnyKernel3 || exit 1
   zip -r9 ${ZIPNAME} *
   MD5CHECK=$(md5sum "$ZIPNAME" | cut -d' ' -f1)
   echo "Zip: $ZIPNAME"
   #curl -T $FINAL_ZIP_ALIAS temp.sh
   #curl -T $FINAL_ZIP_ALIAS https://oshi.at
   curl --upload-file $ZIPNAME https://free.keep.sh
   cd ..
else
   echo -e "\nCompilation failed!"
   exit 1
fi