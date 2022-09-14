#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

puts() { printf "\n\n --- %s\n" "$*"; }

BUILD_CHANNEL=$1

#	Wrap APT commands in functions.

source /configs/scripts/apt_funcs.sh

#	Wrap Debian build commands in functions.

source /configs/scripts/builder/main.sh

#	Wrap Layout build commands in functions.

source /layouts/main.sh

puts "STARTING BOOTSTRAP."

#	Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences

#	Add key for Kaytime repository.

puts "ADDING REPOSITORY KEYS."

add_kaytime_key_compat

while :; do
	case $BUILD_CHANNEL in
	stable)
		add_kaytime_key_stable
		break
		;;
	unstable)
		add_kaytime_key_unstable
		break
		;;
	testing)
		add_kaytime_key_testing
		break
		;;
	*)
		echo "This branch $BUILD_CHANNEL doesn't not exist"
		exit
		break
		;;
	esac
done

#	Copy repository sources.

puts "ADDING SOURCES FILES."

adding_sources_file

#	Upgrade dpkg for zstd support.

UPGRADE_DPKG='
	dpkg=1.21.1ubuntu1
'

install_downgrades $UPGRADE_DPKG

#	Do dist-upgrade.

dist_upgrade

#	Add casper.
#
#	It's worth noting that casper isn't available anywhere but Ubuntu.
#	Debian doesn't use it; it uses live-boot, live-config, et. al.

puts "ADDING CASPER."

adding_casper

#	Add KUI meta-package.

install_ui_layout

#	Add Kaytime Apps meta-package.

install_apps_layout

#	Add Calamares.
#
#	The package from KDE Neon is compiled against libkpmcore12 (22.04) and libboost-python1.71.0 from
#	Ubuntu which provides the virtual package libboost-python1.71.0-py38. The package from Debian doesn't
#	offer this virtual dependency.

puts "ADDING CALAMARES INSTALLER."

adding_system_installer

#	Remove sources used to build the root.

puts "REMOVE BUILD SOURCES."

rm \
	/etc/apt/preferences \
	/etc/apt/sources.list.d/* \
	/usr/share/keyrings/kaytime-repo.gpg \
	/usr/share/keyrings/kaytime-compat.gpg

update

#	Update Appstream cache.

clean_all
update
appstream_refresh_force

#	Add repository configuration.

puts "ADDING REPOSITORY SETTINGS."

KAYTIME_REPO_PKG='
	system-repositories-config
'

install $KAYTIME_REPO_PKG

#	Unhold initramfs and casper packages.

unhold $INITRAMFS_CASPER_PKGS

#	WARNING:
#	No apt usage past this point.

#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

rm \
	/etc/default/grub \
	/etc/casper.conf

cat /configs/files/grub >/etc/default/grub
cat /configs/files/casper.conf >/etc/casper.conf

rm \
	/boot/{vmlinuz,initrd.img,vmlinuz.old,initrd.img.old} || true

cat /configs/files/motd >/etc/motd

printf '%s\n' fuse nouveau amdgpu >>/etc/modules

cat /configs/files/adduser.conf >/etc/adduser.conf

#	Generate initramfs.

puts "UPDATING THE INITRAMFS."

update-initramfs -c -k all

#	Before removing dpkg, check the most oversized installed packages.

puts "SHOW LARGEST INSTALLED PACKAGES.."

list_pkgs_size
list_number_pkgs
list_installed_pkgs

#	WARNING:
#	No dpkg usage past this point.

puts "PERFORM MANUAL CHECKS."

ls -lh \
	/boot \
	/etc/runlevels/{boot,default,nonetwork,off,recovery,shutdown,sysinit} \
	/{vmlinuz,initrd.img} \
	/etc/{init.d,sddm.conf.d} \
	/usr/lib/dbus-1.0/dbus-daemon-launch-helper \
	/Applications || true

stat /sbin/init \
	/bin/sh \
	/bin/dash \
	/bin/bash

cat \
	/etc/{casper.conf,sddm.conf,modules} \
	/etc/default/grub \
	/etc/environment \
	/etc/adduser.conf

puts "EXITING BOOTSTRAP."
