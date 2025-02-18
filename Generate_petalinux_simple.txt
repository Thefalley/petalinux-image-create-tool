## Este documento tiene las configuraciones necesarias para generar el proyecto de petalinux generado. 

## Crear variable de entrono
source /tools/Xilinx/PetaLinux/2022.2/settings.sh

## Crear proyecto de petalinux
petalinux-create -t project -s /project/shared/xilinx-zcu102-v2022.2-10141622.bsp --name lnx_event2Frame_v2_01
cd lnx_event2Frame_v2_01

## Configuración de hardware
petalinux-config --get-hw-description ../XSA_CODIGO_MODIFICADO_V_02.xsa --silentconfig 

## Filesystem Packages -> misc -> packagegroup-core-buildessential -> (*) core buildessential
petalinux-config -c rootfs 

## DMA suport --> DMA test client
petalinux-config -c kernel --silent

## Compilar kernel de linux
petalinux-build

## Petalinux package
petalinux-package --force --boot --fsbl --atf --pmufw --fpga --u-boot
petalinux-package --wic --wic-extra-args "-c xz"

## Simular
petalinux-boot --qemy --kernel

## Enviar por ssh a pc
cd images/linux/
scp -r petalinux-sdimage.wic.xz pmendoza@172.16.124.62:~/plx_codigo_modificado_v_02/
scp -r petalinux-sdimage.wic.xz pmendoza@172.16.124.55:~/AXIS-X4-TO-AXI-DM/


###### ALERTA ######
## Para flashear la imagen en la tarjeta (mucho cuidado!!)
## ls /dev | grep sd
## sudo umount /dev/sdb1
## sudo umount /dev/sdb2
## xz -dc petalinux-sdimage.wic.xz | sudo dd of=/dev/sdb conv=fdatasync bs=4M
###### ALERTA ######
