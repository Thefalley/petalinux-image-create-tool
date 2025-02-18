###### ALERTA ######
## Para flashear la imagen en la tarjeta (mucho cuidado!!)
## ls /dev | grep sd
## sudo umount /dev/sdb1
## sudo umount /dev/sdb2
## xz -dc petalinux-sdimage.wic.xz | sudo dd of=/dev/sdb conv=fdatasync bs=4M
###### ALERTA ######
