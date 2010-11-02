ADONS=ca-certificates fakeroot psutils netpbm crda mkinitcpio-nfs-utils wireless_tools bridge-utils
XORG=xorg xf86-input-evdev hal xf86-input-synaptics xterm xorg-xkb-utils xorg-xinit xorg-xfs xorg-xauth \
xorg-utils xorg-util-macros xorg-twm xorg-server-utils xorg-server xorg-res-utils xorg-fonts-misc \
xorg-fonts-encodings xorg-fonts-alias xorg-fonts-75dpi xorg-fonts-100dpi xorg-font-utils xorg-docs \
xorg-apps xf86-video-voodoo xf86-video-vesa xf86-video-v4l xf86-video-tseng xf86-video-trident \
xf86-video-tdfx xf86-video-sisusb xf86-video-sis xf86-video-siliconmotion xf86-video-savage \
xf86-video-s3virge xf86-video-s3 xf86-video-rendition xf86-video-r128 xf86-video-nv \
xf86-video-neomagic xf86-video-mga xf86-video-mach64 xf86-video-intel xf86-video-i740 \
xf86-video-i128 xf86-video-glint xf86-video-fbdev xf86-video-cirrus xf86-video-chips \
xf86-video-ati xf86-video-ark xf86-video-apm xf86-input-penmount xf86-input-mutouch \
xf86-input-mouse xf86-input-keyboard xf86-input-elographics xf86-input-aiptek \
xf86-input-acecad dri2proto inputproto libpciaccess libx11 libxau libxfont libxinerama libxp libxpm \
libxrandr libxres libxv libxxf86dga randrproto xproto 
XFCE=libxfce4menu libxfce4util terminal thunar thunar-archive-plugin \
thunar-volman xarchiver xfce-utils xfce4-appfinder xfce4-artwork \
xfce4-clipman-plugin xfce4-diskperf-plugin xfce4-genmon-plugin xfce4-mount-plugin \
xfce4-netload-plugin xfce4-notes-plugin xfce4-notifyd xfce4-panel xfce4-quicklauncher-plugin xfce4-session \
xfce4-settings xfce4-systemload-plugin xfce4-taskmanager xfce4-verve-plugin xfce4-wavelan-plugin \
xfce4-xkb-plugin xfconf xfdesktop xfwm4 
all:
	echo 'please read the document for making the live cd..... its README file in current dir :P' 
	echo 'thank you :D' 

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

pacman-base:
	rm root/etc/pacman.conf root/etc/pacman.d/mirrorlist;\
	pacman --config ./conf/pacman.conf --root ./root -S base
pacman-sync:
	pacman --config ./conf/pacman.conf --root ./root -Sy
pacman-kernel26:
	sed -i s/autodetect/'usb lvm2'/ ./root/etc/mkinitcpio.conf;\
	sed -i s/'MODULES=""'/'MODULES="aufs squashfs loop"'/ ./root/etc/mkinitcpio.conf;\
	pacman --config ./root/etc/pacman.conf --root ./root -S kernel26
pacman-squashfs:
	pacman --config ./root/etc/pacman.conf --root ./root -S squashfs-tools
pacman-aufs:
	pacman --config ./root/etc/pacman.conf --root ./root -S aufs2 #aufs2-util
pacman-update:
	pacman --config ./root/etc/pacman.conf --root ./root -Su
pacman-adons:
	pacman --root ./root/ --config ./root/etc/pacman.conf -S $(ADONS)

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
	mksquashfs ./root root.squashfs -always-use-fragments
	mv ./root.squashfs ./iso/root.squashfs
pacman-xorg:
	pacman --config ./root/etc/pacman.conf --root ./root -S ${XORG}
pacman-xfce:
	pacman --config ./root/etc/pacman.conf --root ./root -S ${XFCE}