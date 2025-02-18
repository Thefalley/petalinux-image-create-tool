scp -r petalinux-sdimage.wic.xz pmendoza@172.16.124.55:~/AXIS-X4-TO-AXI-DM/

###### ALERTA ######
## Para flashear la imagen en la tarjeta (mucho cuidado!!)
## ls /dev | grep sd
## sudo umount /dev/sdb1
## sudo umount /dev/sdb2
## xz -dc petalinux-sdimage.wic.xz | sudo dd of=/dev/sdb conv=fdatasync bs=4M
###### ALERTA ######
