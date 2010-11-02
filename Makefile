BASE=$(shell cat packages.list)
XORG=$(shell cat packages.xorg)
EXTRA=$(shell cat packages.extra)
ARCH=i686

all:
	echo 'please read the document for making the live cd..... its README file in current dir :P' 
	echo 'thank you :D' 

prepare: mkdir pacman-sync copy-pac mount pacman-base pacman-kernel26 pacman-extra mkinitramfs

copy-pac:
	cp ./conf/pacman.conf ./root/etc/
	cp ./conf/mirrorlist ./root/etc/pacman.d/
mount:
	mount -t sysfs sysfs "root/sys"
	mount -t proc proc "root/proc"
	mount -o bind /dev "root/dev"
	mount -t tmpfs shm "root/dev/shm"
	mount -t devpts devpts "root/dev/pts"
	mount --bind /var/run "root/var/run"
	mount --bind /var/lib/dbus "root/var/lib/dbus"
	mount --bind /var/cache/pacman/pkg root/var/cache/pacman/pkg
umount:
	umount "root/sys" ; \
	umount "root/proc" ; \
	umount "root/dev/shm" ; \
	umount "root/dev/pts" ; \
	umount "root/dev" ; \
	umount "root/var/run" ; \
	umount "root/var/cache/pacman/pkg" ; \
	umount "root/var/lib/dbus" ; echo "----------------umount done-------------- "

mkdir: 
	mkdir -p boot root/{var/{lib/{pacman,dbus},cache/pacman/pkg,run},dev,proc,sys,etc/pacman.d,root,tmp} squashmod mkinitrd iso
clean: umount
	rm -rf boot squashmod mkinitrd root

# pacman maintenance operations
pacman-sync:
	setarch $(ARCH) pacman --config ./conf/pacman.conf --root ./root -Sy
pacman-update:
	setarch $(ARCH) pacman --config ./root/etc/pacman.conf --root ./root -Su
# package installation
pacman-base:
	rm root/etc/pacman.conf root/etc/pacman.d/mirrorlist;\
	setarch $(ARCH) pacman --config ./conf/pacman.conf --root ./root -S base $(BASE)
pacman-kernel26:
	sed -i s/autodetect/'usb lvm2'/ ./root/etc/mkinitcpio.conf;\
	sed -i s/'MODULES=""'/'MODULES="aufs squashfs loop"'/ ./root/etc/mkinitcpio.conf;\
	setarch $(ARCH) pacman --config ./root/etc/pacman.conf --root ./root -S kernel26
pacman-extra:
	setarch $(ARCH) pacman --root ./root/ --config ./root/etc/pacman.conf -S $(XORG) $(EXTRA)

mkinitramfs:
	cp -rf ./root/boot/* ./boot
	cp ./root/usr/lib/grub/i386-pc/stage2_eltorito ./boot/grub/
	rm ./boot/kernel26-fallback.img
	mkdir ./boot/ramfs -p
	gzip -d ./boot/kernel26.img -c > ./boot/ramfs/_cpio
	rm ./boot/kernel26.img
	cd ./boot/ramfs;bsdtar -x -f _cpio; rm _cpio;
	rm ./boot/ramfs/init
	cp ./conf/init ./boot/ramfs/
	cd ./boot/ramfs; find . | cpio -H newc -o | gzip > ../initrd.cpio.igz
	rm -rf ./boot/ramfs
	rm ./boot/grub/menu.lst
	echo "timeout   5" >> ./boot/grub/menu.lst
	echo "default   0	" >> ./boot/grub/menu.lst
	echo "title  poison's live cd  \m/" >> ./boot/grub/menu.lst
	echo "kernel  /boot/vmlinuz26 quiet ro" >> ./boot/grub/menu.lst
	echo "initrd  /boot/initrd.cpio.igz" >> ./boot/grub/menu.lst
	echo "boot" >> ./boot/grub/menu.lst
	echo "title  poison's live cd  \m/ ( nomodeset- for some nvidia GPU )" >> ./boot/grub/menu.lst
	echo "kernel  /boot/vmlinuz26 quiet ro nomodeset" >> ./boot/grub/menu.lst
	echo "initrd  /boot/initrd.cpio.igz" >> ./boot/grub/menu.lst
	echo "boot" >> ./boot/grub/menu.lst
	cp ./boot ./iso -rf
	
iso-image:
	genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o live_disk.iso ./iso
mksquashfs: umount
	mksquashfs ./root root.squashfs -always-use-fragments -comp lzma
	mv ./root.squashfs ./iso/root.squashfs
