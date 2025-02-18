## ========================================================================== ##
## 4-image-gen.sh
##
## PetaLinux v2022.2 project generation script (to be run on the workstation)
##
## ToDo: handle ikerlan-logo.h, etc. (recipe + backup)
##
## This file was created by Jorge Botana Mtz. de Ibarreta.
##
## Copyright (c) 2024-2025 Ikerlan S. Coop. All rights reserved.
## ========================================================================== ##

BSP_FILE=/project/shared/xilinx-zcu102-v2022.2-10141622.bsp
XSA_FILE=XSA_test_bridge_DM_01-zcu102.xsa
PRJ_NAME=plnx-prj
PRJ_NAME_VIVADO=vivado-prj

APP_NAME=dvscfg-app

M_1_NAME=dvscfg-zlt
M_2_NAME=dvscfg-e2f
M_3_NAME=dvscfg-fil
M_4_NAME=dvscfg-dac
M_5_NAME=dvscfg-gct

ETH_IPV4=172.16.102.48
ETH_MASK=255.255.255.0
USERNAME=petalinux
PASSWORD=1234

REC_PREF=project-spec/meta-user/recipes

## Avoid running this script from another directory.
if ! test -f ../../workspace/${PRJ_NAME_VIVADO}/${XSA_FILE}; then
    echo "Not in the correct directory!"
    exit
fi

## Avoid running this script accidentally.
echo "This script regenerates the whole project."
read -p "Proceed? Write \"yes\" (lowercase and no quotes) to continue: "
if [ ! $REPLY = yes ]; then
    exit
fi

## Source the PetaLinux environment.
source /tools/Xilinx/PetaLinux/2022.2/settings.sh

# Change to the repository root directory.
cd ../../

## Remove the old PetaLinux project.
rm -rf workspace/${PRJ_NAME}/

## Change to the workspace directory.
cd workspace/

## Create the current PetaLinux project.
petalinux-create -t project -n ${PRJ_NAME} -s ${BSP_FILE}

## Change to the project directory.
cd ${PRJ_NAME}/

## Import the hardware design.
petalinux-config --get-hw-description ../${PRJ_NAME_VIVADO}/${XSA_FILE} --silentconfig

## Create the app in /usr/bin/
petalinux-create -t apps    -n ${APP_NAME} --enable

## Create the modules in /lib/modules/5.15.36-xilinx-v2022.2/extra/ (one is
## disabled by default).
## petalinux-create -t modules -n ${M_1_NAME} --enable
## petalinux-create -t modules -n ${M_2_NAME} --enable
## petalinux-create -t modules -n ${M_3_NAME} --enable
## petalinux-create -t modules -n ${M_4_NAME} --enable
## petalinux-create -t modules -n ${M_5_NAME} --enable

## Change to the repository root directory.
## cd ../../

## Copy the user files to the current PetaLinux project.
## rm      workspace/${PRJ_NAME}/${REC_PREF}-apps/${APP_NAME}/files/${APP_NAME}.c
## cp sources/app/* \
##         workspace/${PRJ_NAME}/${REC_PREF}-apps/${APP_NAME}/files/
## cp sources/core/system-user.dtsi \
##         workspace/${PRJ_NAME}/${REC_PREF}-bsp/device-tree/files/
## cp sources/drivers/${M_1_NAME}.c \
##         workspace/${PRJ_NAME}/${REC_PREF}-modules/${M_1_NAME}/files/
## cp sources/drivers/${M_2_NAME}.c \
##         workspace/${PRJ_NAME}/${REC_PREF}-modules/${M_2_NAME}/files/
## cp sources/drivers/${M_3_NAME}.c \
##         workspace/${PRJ_NAME}/${REC_PREF}-modules/${M_3_NAME}/files/
## cp sources/drivers/${M_4_NAME}.c \
##         workspace/${PRJ_NAME}/${REC_PREF}-modules/${M_4_NAME}/files/
## cp sources/drivers/${M_5_NAME}.c \
##         workspace/${PRJ_NAME}/${REC_PREF}-modules/${M_5_NAME}/files/

## Change to the project directory.
cd workspace/${PRJ_NAME}/

## Set a static IPv4 network configuration.
sed -i "s/\
CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP=y/\
# CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_USE_DHCP is not set\n\
CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_IP_ADDRESS=\"${ETH_IPV4}\"\n\
CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_IP_NETMASK=\"${ETH_MASK}\"\n\
CONFIG_SUBSYSTEM_ETHERNET_PSU_ETHERNET_3_IP_GATEWAY=\"${ETH_IPV4}\"\
/"   project-spec/configs/config

## Add build essential config in linux
sed -i 's/^# CONFIG_packagegroup-core-buildessential is not set/CONFIG_packagegroup-core-buildessential=y/' project-spec/configs/rootfs_config

## Do not copy files to /tftpboot/
sed -i "s/\
CONFIG_SUBSYSTEM_COPY_TO_TFTPBOOT=y/\
# CONFIG_SUBSYSTEM_COPY_TO_TFTPBOOT is not set\
/"   project-spec/configs/config
sed -i  "/\
CONFIG_SUBSYSTEM_TFTPBOOT_DIR=\"\/tftpboot\"\
/d"  project-spec/configs/config

## Add xauth (required to use GTK+3 based apps).
sed -i "s/\
# CONFIG_xauth is not set/\
CONFIG_xauth=y\
/"   project-spec/configs/rootfs_config

## Add the Adwaita icon theme (required to avoid graphical issues with GTK+3
## based apps, and as an alternative to GTK_THEME=win32).
sed -i "s/\
# CONFIG_adwaita-icon-theme is not set/\
CONFIG_adwaita-icon-theme=y\
/"   project-spec/configs/rootfs_config

## Enable the root login (including via SSH).
sed -i "s/\
# CONFIG_imagefeature-debug-tweaks is not set/\
CONFIG_imagefeature-debug-tweaks=y\
/"   project-spec/configs/rootfs_config

## Enable autologin on startup.
sed -i "s/\
# CONFIG_auto-login is not set/\
CONFIG_auto-login=y\
/"   project-spec/configs/rootfs_config

## Set "root" and "user" password.
sed -i "s/\
CONFIG_ADD_EXTRA_USERS=\"root:root;petalinux::passwd-expire;\"/\
CONFIG_ADD_EXTRA_USERS=\"root:${PASSWORD};${USERNAME}:${PASSWORD};\"\
/"   project-spec/configs/rootfs_config

## Change from "root" to "petalinux" as the autologin user.
echo -n "\
AUTOLOGIN_USER = \"${USERNAME}\"
" >> project-spec/meta-user/conf/petalinuxbsp.conf

## Prevent Yocto from deleting the app and modules builds after packaging the
## PetaLinux image (this is useful in order not to generate the whole image
## if we want to update the binaries).
echo -n "\
RM_WORK_EXCLUDE += \"${APP_NAME}\"
RM_WORK_EXCLUDE += \"${M_1_NAME}\"
RM_WORK_EXCLUDE += \"${M_2_NAME}\"
RM_WORK_EXCLUDE += \"${M_3_NAME}\"
RM_WORK_EXCLUDE += \"${M_4_NAME}\"
RM_WORK_EXCLUDE += \"${M_5_NAME}\"
" >> project-spec/meta-user/conf/petalinuxbsp.conf

## Modify the app Makefile to add all the sources.
sed -i "s/\
APP_OBJS = ${APP_NAME}.o/\
APP_OBJS = \$(patsubst %.c, %.o, \$(wildcard *.c))\
/"   ${REC_PREF}-apps/${APP_NAME}/files/Makefile

## Modify the app recipe to add all the sources.
for SRC_NAME in ${REC_PREF}-apps/${APP_NAME}/files/*; do
    if [ -f ${SRC_NAME} ]; then
        SRC_LIST+="file:\/\/$(basename ${SRC_NAME}) "
    fi
done
sed -i "s/\
SRC_URI = \"file:\/\/${APP_NAME}.c \\\/\
SRC_URI = \"${SRC_LIST}\"\
/"   ${REC_PREF}-apps/${APP_NAME}/${APP_NAME}.bb
sed -i "s/\
\t   file:\/\/Makefile \\\/\
\t   file:\/\/Makefile \\\ \
/"   ${REC_PREF}-apps/${APP_NAME}/${APP_NAME}.bb
sed -i  "/\
\t   file:\/\/Makefile \\\ \
/d"  ${REC_PREF}-apps/${APP_NAME}/${APP_NAME}.bb
sed -i  "/\
\t\t  \"\
/d"  ${REC_PREF}-apps/${APP_NAME}/${APP_NAME}.bb

## Modify the app recipe to link with GTK+3.
echo -n "\
DEPENDS = \"gtk+3 librsvg\"
CFLAGS += \" \`pkg-config --cflags gtk+-3.0 librsvg-2.0\` \"
LDFLAGS += \" \`pkg-config --libs gtk+-3.0 librsvg-2.0\` \"
" >> ${REC_PREF}-apps/${APP_NAME}/${APP_NAME}.bb

## Include the kernel sources in the SDK.
mkdir -p ${REC_PREF}-core/images/
echo -n "\
TOOLCHAIN_TARGET_TASK += \"kernel-devsrc\"
" >> ${REC_PREF}-core/images/petalinux-image-minimal.bbappend

# Create a custom OpenEmbedded Kickstart file.
echo -n "\
part /boot --source bootimg-partition --ondisk mmcblk0 --fstype=vfat --label \
boot --active --align 4
part / --source rootfs --ondisk mmcblk0 --fstype=ext4 --label root --align 4 \
--extra-space 100M
" >> project-spec/sdimage.wks

## Build the current PetaLinux project.
petalinux-build

## Package the BOOT.BIN
petalinux-package --boot --force --u-boot --fpga

## Package the WIC image.
petalinux-package --wic --wic-extra-args "-c xz" --wks project-spec/sdimage.wks

## Build the SDK (not required, but useful for the linter of VS Code).
petalinux-build -s

## Extract the SDK.
petalinux-package --sysroot --sdk images/linux/sdk.sh

## Prepare the SDK.
source images/linux/sdk/environment-setup-cortexa72-cortexa53-xilinx-linux

## Change to the kernel source directory.
cd images/linux/sdk/sysroots/cortexa72-cortexa53-xilinx-linux/usr/src/kernel/

## Generate some includes used by kernel modules.
make modules_prepare
