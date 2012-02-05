#!/bin/sh

# script installs
# arguments: mirror disks
# example:
# sysinstall.sh /dev/gpt/disk0 /dev/gpt/disk1

. ../functions.sh

#ifos FreeBSD "Script works only in \033[1;31mFreeBSD\033[0m"

if [ $# -lt 1 ]
then
	echo "You must specify at least one disk"
	exit
fi

i "Creating zroot..."
if [ $# -eq 2 ]
then
	zpool create -f zroot $@
else
	zpool create -f zroot mirror $@
fi

i "Configuring zroot..."
zpool set bootfs=zroot zroot
zfs set checksum=fletcher4 zroot
zfs set mountpoint=/mnt zroot

i "Creating zpool.cache..."
zpool export zroot
zpool import -o cachefile=/var/tmp/zpool.cache zroot

i "Creating zfs dirs..."
p "zroot/usr";                 zfs create                                               zroot/usr
p "zroot/usr/home";            zfs create                                               zroot/usr/home
p "zroot/tmp";                 zfs create -o compression=on   -o exec=on  -o setuid=off zroot/tmp
p "zroot/usr/ports";           zfs create -o compression=lzjb             -o setuid=off zroot/usr/ports
p "zroot/usr/ports/distfiles"; zfs create -o compression=off  -o exec=off -o setuid=off zroot/usr/ports/distfiles
p "zroot/usr/ports/packages";  zfs create -o compression=off  -o exec=off -o setuid=off zroot/usr/ports/packages
p "zroot/usr/src";             zfs create -o compression=lzjb -o exec=off -o setuid=off zroot/usr/src
p "zroot/var";                 zfs create                                               zroot/var
p "zroot/var/crash";           zfs create -o compression=lzjb -o exec=off -o setuid=off zroot/var/crash
p "zroot/var/db";              zfs create                     -o exec=off -o setuid=off zroot/var/db
p "zroot/var/db/pkg";          zfs create -o compression=lzjb -o exec=on  -o setuid=off zroot/var/db/pkg
p "zroot/var/empty";           zfs create                     -o exec=off -o setuid=off zroot/var/empty
p "zroot/var/log";             zfs create -o compression=lzjb -o exec=off -o setuid=off zroot/var/log
p "zroot/var/mail";            zfs create -o compression=gzip -o exec=off -o setuid=off zroot/var/mail
p "zroot/var/run";             zfs create                     -o exec=off -o setuid=off zroot/var/run
p "zroot/var/tmp";             zfs create -o compression=lzjb -o exec=on  -o setuid=off zroot/var/tmp
p_end

#zfs create -V 2G zroot/swap
#zfs set org.freebsd:swap=on zroot/swap
#zfs set checksum=off zroot/swap

chmod 1777 /mnt/tmp
cd /mnt
ln -s usr/home home
chmod 1777 /mnt/var/tmp

cd /usr/freebsd-dist
export DESTDIR=/mnt

BASE='kernel.txz base.txz'
PORTS='ports.txz src.txz'
DOC='doc.txz'
#LIB32='lib32.txz'
#GAMES='games.txz'
for file in ${BASE} ${PORTS} ${DOC} ${LIB32} ${GAMES};
do
	i "Unpacking $file"
	(cat $file | tar --unlink -xpJf - -C ${DESTDIR:-/});
done

i "Copying zpool.cache into system..."
cp /var/tmp/zpool.cache /mnt/boot/zfs/zpool.cache

i "Configuring zfs..."
echo 'zfs_enable="YES"' >> /mnt/etc/rc.conf
echo 'zfs_load="YES"' >> /mnt/boot/loader.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> /mnt/boot/loader.conf
touch /mnt/etc/fstab

i "Finishing..."
zfs set readonly=on zroot/var/empty
zfs umount -af
zfs set mountpoint=legacy zroot
zfs set mountpoint=/tmp zroot/tmp
zfs set mountpoint=/usr zroot/usr
zfs set mountpoint=/var zroot/var
