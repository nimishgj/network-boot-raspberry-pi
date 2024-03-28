

wget https://downloads.raspberrypi.com/raspios_arm64/images/raspios_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64.img.xz
wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz

sudo -pv /mnt/imgfiles
sudo mkdir -pv /home/odroid/bootfiles
sudo mkdir -pv /home/odroid/userfiles

xz --decompress 2024-03-15-raspios-bookworm-arm64-lite.img.xz.1

sudo mount -o loop,offset=$((1056768 * 512)) 2024-03-15-raspios-bookworm-arm64-lite.img /mnt/imgfiles

cp -a /mnt/imgfiles/* /home/odroid/userfiles

sudo umount /mnt/imgfiles

xz --decompress 2024-03-15-raspios-bookworm-arm64.img.xz

sudo mount -o loop,offset=$((8192 * 512)) 2024-03-15-raspios-bookworm-arm64.img.xz /mnt/imgfiles

cp -a /mnt/imgfiles/* /home/odroid/bootfiles

sudo umount /mnt/imgfiles

sudo rm 2024-03-15-raspios-bookworm-arm64.img.xz 2024-03-15-raspios-bookworm-arm64-lite.img.xz
sudo rm -rf /mnt/imgfiles

sudo cp pxe.service /etc/systemd/system
sudo cp pxeService.sh /usr/bin

sudo touch /run/pxeService.pid
sudo touch /opt/addresslist.txt

chmod 777 /opt/addresslist.txt
