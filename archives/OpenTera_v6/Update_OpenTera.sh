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
#	26 Jul 2010	itimpi	     Added query option to allow selective install of
#				     optional packages.
#				     Added check that archives exist before trying to install
#				     Updated to following packages:
#					- busybox 1.16.2
#					- coreutils 8.5
#					- diffutils 3.0
#					- grep 2.6.3
#					- ushare-1.1a_ppc_v8
#				     Removed PCast package
#				     Added 
#					- texinfo 4.13
#					- nano v2.2.5
#
#	18 Jul 2011	itimpi	     v6: Updated to following packages:
#					- coreutils v8.12
#					- less v4.43
#					- nano v2.3.1
#					- grep v2.9
#					- groff v2.21
#				     Added
#					- e2fsprogs-1.41.14
#					- tar v2.15
#

# The script can take one parameter which is the 'root' directory
# relative to which the changes must be applied.  If omitted then
# the update is relative to /

BASEDIR=$1

#----------------- Functions to support install ----------------------

missing_package ()
{
	echo "[OpenTera] ERROR: ** Archive $1 Not Found **"
	echo "[OpenTera] ERROR: package cannot be installed "
	echo "[OpenTera] Press ENTER to continue"
	read $dummayanswer
}

#	Install a ZIP package which has Update script
#	$1 is package file (without .zip extension)
#	$2 is variable part of script name

# 	Install waiting for ENTER if 'all'not active
install_zip_package ()
{
	if [ "$opentera_answer" = "q" ]
	then
		echo "[OpenTera] Ready to install $1"
		echo "[OpenTera] Do you want this package[y/n]:"
		read dummyanswer
		if [ "$dummyanswer" = "y" ]
		then
			install_zip_package2 $1 $2
		fi
	else
		install_zip_package2 $1 $2
		if [ "$opentera_answer" = "y" ]
		then
			echo "[OpenTera] Press ENTER to continue"
			read dummyanswer
		fi
	fi
}

#	Install without waiting for ENTER at end
install_zip_package2 ()
{
	echo "[OpenTera]======================================= Installing $1 "
	if [ -f $1.zip ]
	then
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
	else
		missing_package "$1.zip"
	fi
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
		if [ "$opentera_answer" = "y" ]
	then
		echo "[OpenTera] Press ENTER to continue"
		read dummyanswer
	fi
}

#	Install without waiting for ENTER at end
install_tgz_package2 ()
{
	echo "[OpenTera]======================================= Installing $1 "
	if [ -f $1.tgz ]
	then

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
	else
		missing_package "$1.tgz"
	fi
	echo "[OpenTera]======================================= Completed $1 "
}


echo ""
echo "[OpenTera] =============== OpenTera Install Starting ================="
echo ""
echo "[OpenTera] Messages originating in the master OpenTera install"
echo "[OpenTera] are all preceded by [OpenTera] (like this one)."
echo "[OpenTera] Other messages originate in that stage's install script."
echo ""
echo "[OpenTera] The way the install works depends on the answer you give below:"
echo "[OpenTera] n       The install is immediately abandoned"
echo "[OpenTera] y       All packages are installed, and after each you are given"
echo "[OpenTera]         a chance to read the messages and decide whether to go on"
echo "[OpenTera] a(ll)   All packages are installed with no none-essential prompts"
echo "[OpenTera]         Simplest to use but esiest to miss error messages."
echo "[OpenTera] q(uery) Before any packages are installed you are asked to"
echo "[OpenTera]         confirm that you want them.  Critical packages are"
echo "[OpenTera]         installed without asking for confirmation".
echo ""
echo "[OpenTera] Press ENTER to continue"
read dummyanswer

#Check free disk space (need approximately 95MB).

echo "[OpenTera] Complete installation of the OpenTera package"
echo "[OpenTera] requires sbout 95MB of free disk space on /dev/md0"
echo "[OpenTera] Your current disk usage:"
df -h /
opentera_answer=""
while [ "$opentera_answer" != "y" -a "$opentera_answer" != "n" -a "$opentera_answer" != "a" -a "$opentera_answer" != "q" ]
do
	echo "[OpenTera] Shall we continue? [y/n/a/q]"
	read opentera_answer
done

#If no, exit gracefully.
if [ "$opentera_answer" = "n" ]
then
	exit 0
fi

install_zip_package  "busybox-1.16.2_ppc" "Busybox"
install_zip_package  "Libraries_ppc_v1" "Libraries"
install_tgz_package2 "libupnp-1.6.6_ppc" "/usr/local"
install_tgz_package  "libdlna-0.2.3_ppc" "/"
install_zip_package  "libiconv-1.13.1_ppc" "libiconv"
install_tgz_package  "ffmpeg-0.5_ppc" "/usr/local"
install_tgz_package2 "ldconfig-binaries-ppc" "/"
if [ ! - f $1/etc/ld.so.conf ] ; then
	echo "/lib" >> $1/etc/ld.so.conf
	echo "/usr/lib" >> $1/etc/ld.so.conf
fi
grep "/usr/local/lib" $1/etc/ld.so.conf || echo "/usr/local/lib" >> $1/etc/ld.so.conf
ldconfig
install_zip_package  "zlib-1.2.4_ppc" "zlib"
install_zip_package  "coreutils-8.11_ppc" "coreutils"
install_zip_package  "diffutils-3.0_ppc" "diffutils"
install_tgz_package  "e2fsprogs-1.41.14_ppc" "/usr/local"
install_zip_package  "findutils-4.4.2_ppc" "findutils"
install_zip_package  "grep-2.9_ppc" "grep"
install_tgz_package  "groff-1.21_ppc" "/usr/local"
install_zip_package  "less-443_ppc" "less"
install_tgz_package  "man-1.6b_ppc" "/"
install_zip_package  "nano-2.3.1_ppc" "nano"
install_zip_package  "tar-1.25_ppc" "tar"
install_zip_package  "rsync-3.0.7_ppc" "rsync"
install_tgz_package  "texinfo-4.13_ppc" "/usr/local"
install_tgz_package2 "unrar-3.9.2_ppc" "/usr/local"
install_zip_package2 "tera_zip_v1" "zip"
install_zip_package  "gzip-1.4_ppc" "gzip"
install_zip_package  "ushare-1.1a_ppc_v8" "ushare"

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
echo "                                 NOTE"
echo "[OpenTera] You can free up around 50MB of extra disk space on the"
echo "[OpenTera] system partition (/dev/md0) if you run the " `ls MakeSpace*` 
echo "[OpenTera] script to move non-critical files to the share."
echo ""
echo "[OpenTera] Space currently left on /dev/md0 is shown below"
df -h /
echo ""
echo "[OpenTera] ============ OpenTera Install Completed ==============="

echo ""

