#!/bin/sh
#
#    Name:         Update_OpenTera.sh
#
#    Description:  Install all the OpenTera packages that are not
#                  development oriented.
#
#                  Relevant to the following:
#
#                    OpenTera      Original
#                                  Home Server
#                                  Pro v1
#                  Should also work for
#                    OpenLink      LS1
#                                  HG
#                  Designed to be called from a master script that is
#                  controlling the overall upgrade.  Assumes that the
#                  script is being called from the root of the image
#                  it is trying to update
#
#    Change History:
#       14 Aug 2009	itimpi	     first version for OpenTera
#	24 Dec 2009     itimpi       Updated (v2) for:
#					- busybox v15.3
#					- coreutils v8.2
#					- pcast_ppc_tera_v4
#	31 Mar 2010	itimpi	     Updated (v3) for: 
#					- busybox 1.16.1
#					- coreutils v8.4
#					- grep 2.6.2
#					- gzip 1.4
#					- ushare-1.1a_ppc_v7 (new package)
#				     Corrected error on PCast install (wrong package name)
#				     Corrected error on man install (wrong install folder)
#				     Updated for packages with Update_xxx.sh script added
#					- coreutils
#					- findutils
#					= grep
#					- gzip
#					- less
#				     OpenSSH package not installed if already present
#				     (Leaves system unbootable if done via SSH session)
#				     install_xxx_package functions added to simplify code
#				     Install methods altered to try and preserve symbolic links.
#				     User asked to press ENTER after each package install.
#
#	14 Apr 2010	itimpi	     Ensure that target folders exist for copying
#				     Added following packages:
#					- diffutils (2.9)
#
#	28 Apr 2010	itimpi	     Updated to following packages:
#					- coreutils 8.5
#					- grep 2.6.3
#					- ushare-1.1a_ppc_v8
#				     Removed PCast package

# The script can take one parameter which is the 'root' directory
# relative to which the changes must be applied.  If omitted then
# the update is relative to /

BASEDIR=$1

#----------------- Functions to support install ----------------------

#	Install a ZIP package which has Update script
#	$1 is package file (without .zip extension)
#	$2 is variable part of script name

# 	Install waiting for ENTER if 'all'not active
install_zip_package ()
{
	install_zip_package2 $1 $2
	if [ "$opentera_answer" != "all" ]
	then
		echo "[OpenTera] Press ENTER to continue"
		read dummyanswer
	fi
}

#	Install without waiting for ENTER at end
install_zip_package2 ()
{
	echo "[OpenTera]======================================= Installing $1 "
	mkdir $1
	echo "[OpenTera] unpacking ZIP archive..."
	./unzip $1.zip -d $1
	chown -R root $1
	chgrp -R root $1
	cd $1
	echo "[OpenTera] running Update script from archive ..."
	sh ./Update_$2.sh
	cd ..
	rm -fr $1
	echo "[OpenTera]======================================= Completed $1 "
}


#	Install a TGZ package which has no Update script
#	$1 is source tgz file 
#	$2 is target location for install
#	We use an unpack/copy technique to avoid clobbering
#	any directory symbolic links that might exist in target
#	(this is one way of freeing space on system partition)

# 	Install waiting for ENTER if 'all'not active
install_tgz_package ()
{
	install_tgz_package2 $1 $2
	if [ "$opentera_answer" != "all" ]
	then
		echo "[OpenTera] Press ENTER to continue"
		read dummyanswer
	fi
}

#	Install without waiting for ENTER at end
install_tgz_package2 ()
{
	echo "[OpenTera]======================================= Installing $1 "
	mkdir temp
	echo "[OpenTera] Processing $1 archive"
	echo "[OpenTera] unpacking ..."
	tar -xzf $1.tgz --directory=temp
	chown -R root temp
	chgrp -R root temp
	echo "[OpenTera] installing ..."
	for d in `ls temp`
	do
		# Ensure that required target folder exists
		if [ -d temp/$d ]
		then
			if [ ! -d ${BASEDIR}/$2/$d -a ! -h ${BASEDIR}/$2/$d ]
			then
				mkdir ${BASEDIR}/$2/$d
				echo "[OpenTera] Created folder ${BASEDIR}/$2/$d"
			fi
		fi
		# Copy across files
		cp -pr temp/$d/* ${BASEDIR}/$2/$d
	done
	echo "[OpenTera] tidying up ..."
	rm -fr temp
	echo "[OpenTera]======================================= Completed $1 "
}


echo ""
echo "[OpenTera] =============== OpenTera Install Starting ================="
echo ""

echo "[OpenTera] After each stage completes you will be asked to press"
echo "[OpenTera] ENTER to proceed if you answer 'y' to the continue prompt."
echo "[OpenTera] This give you a chance to see any error or information"
echo "[OpenTera] messages relating to that stage.  If you respond 'all'"
echo "[OpenTera] then the install proceeds through installing all packages"
echo "[OpenTera] without waiting for any any further user input."
echo ""
echo "[OpenTera] Messages originating in the master OpenTera install"
echo "[OpenTera] are all preceded by [OpenTera] (like this one)."
echo "[OpenTera] Other messages originate in that stage's install script."
echo ""
echo "[OpenTera] Press ENTER to continue"
read dummyanswer

#Check free disk space (need approximately 95MB).

echo "[OpenTera] Complete installation of the OpenTera package"
echo "[OpenTera] requires sbout 95MB of free disk space on /dev/md0"
echo "[OpenTera] Your current disk usage:"
df -h /
opentera_answer=""
while [ "$opentera_answer" != "y" -a "$opentera_answer" != "n" -a "$opentera_answer" != "all" ]
do
	echo "[OpenTera] Shall we continue? [y/n/all]"
	read opentera_answer
done

#If no, exit gracefully.
if [ "$opentera_answer" = "n" ]
then
	exit 0
fi

install_zip_package  "busybox-1.16.1_ppc" "Busybox"
install_zip_package  "Libraries_ppc_v1" "Libraries"
install_tgz_package2 "libupnp-1.6.6_ppc" "/usr/local"
install_tgz_package  "libdlna-0.2.3_ppc" "/"
install_zip_package  "libiconv-1.13.1_ppc" "libiconv"
install_tgz_package  "ffmpeg-0.5_ppc" "/usr/local"
install_tgz_package2 "ldconfig-binaries-ppc" "/"
touch $1/etc/ld.so.conf
grep "$1/usr/local/lib" $1/etc/ld.so.conf || echo "$1/usr/local/lib" >> $1/etc/ld.so.conf
ldconfig
install_zip_package  "zlib-1.2.4_ppc" "zlib"
install_zip_package  "coreutils-8.5_ppc" "coreutils"
install_zip_package  "diffutils-2.9_ppc" "diffutils"
install_zip_package  "findutils-4.4.2_ppc" "findutils"
# install_zip_package  "grep-2.6.3_ppc" "grep"
install_tgz_package  "groff-1.20.1_ppc" "/usr/local"
install_zip_package  "less-418_ppc" "less"
install_tgz_package  "man-1.6b_ppc" "/"
install_zip_package  "rsync-3.0.7_ppc" "rsync"
install_tgz_package2 "unrar-3.9.2_ppc" "/usr/local"
install_zip_package2 "tera_zip_v1" "zip"
install_zip_package  "gzip-1.4_ppc" "gzip"
install_zip_package "ushare-1.1a_ppc_v8" "ushare"

if ( test -f /usr/local/etc/ssh_host_dsa_key.pub )
then
	echo ""
	echo "[OpenTera]======================================= Installing OpenSSH "
	echo ""
	echo "[OpenTera] *** Install of OpenSSH skipped as already present ***"
	echo "[OpenTera] (installing over old copy causes a problem if connected via SSH)"
	echo "[OpenTera] You will need to install this separately if you still want to."
	echo "[OpenTera]=============================== Skipped Installing OpenSSH "
	echo "[OpenTera] Press ENTER to continue"
	read dummyanswer
else
	install_zip_package "Openssh_ppc_tera_v1" "Openssh"
fi

echo ""
echo "[OpenTera] ============ OpenTera Install Completed ==============="
echo ""
echo "                                 NOTE"
echo "[OpenTera] You can free up around 50MB of extra disk space on the"
echo "[OpenTera] system partition (/dev/md0) if you run the MakeSpace.sh"
echo "[OpenTera] script to move non-critical files to the share."
echo ""
echo "[OpenTera] Space currently left on /dev/md0 is shown below"
df -h /

echo ""

