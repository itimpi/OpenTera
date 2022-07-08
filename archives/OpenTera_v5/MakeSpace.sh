#!/bin/sh
#	MakeSpace.sh
#
#       Script to link folders from system partition to share area.
#
#	The purpose is to make space on the system partition.
#	Used primarily on development system, although valid on all systems
#
#	If necessary files are also moved to new location
#	Safe to re-run if link is broken to re-establish link without data loss.
#
#	CHANGE HISTORY
#	~~~~~~~~~~~~~~
#	14 Aug 2009	itimpi	- Added Error checking
#	22 Dec 2009	itimpi  - Added checks and progress messages
#	24 Mar 2010	itimpi	- Added rename/copying of data if hard link exists
#				- Information messages added to get ready for general use
#	05 Apr 2010	itimpi	- Added Perl v5 link
#				- Added Python v2.6 link
#				- Added Python v2.7 link
#				- Added Python v3.1 link
#	14 Apr 2010	itimpi	- Added swat (for Samba 3) link

#	Default names for path to share and folder on share
#	Users should ideally edit these to suit there own systems
#	(although values can also be applied at runtime)
DEV=/mnt/array1/share
LOCAL=_local

echo ""
echo "[INFO] ----------------- Starting MakeSpace.sh v3  ---------------------"

# Check that soft links exists.
# If necessary files are moved to create space
# $1	Location on share for real target relative to $DEV/$LOCAL
# $2	Location in normal file system for symbolic link
checkLink ()
{
	if [ ! -d $DEV/$LOCAL/$1 ]
	then
		mkdir $DEV/$LOCAL/$1
		echo "[INFO] directory '$DEV/$LOCAL/$1' created"
	fi
	chmod 755 $DEV/$LOCAL/$1


	if [ -h $2 ]
	then
		echo "[INFO] $2 already set as symbolic link"
	else
		# See if hard link exists
		if [ -d $2 ]
		then
			echo "[INFO] Moving files from $2 to $DEV/$LOCAL/$1"
			cp -rp $2/* $DEV/$LOCAL/$1
			rm -fr $2
		fi
		ln -s $DEV/$LOCAL/$1 $2
		echo "[INFO] $2 linked to $DEV/$LOCAL/$1"
	fi
	chmod 755 $DEV/$LOCAL/$1
	chmod 755 $2
}

echo "[INFO] The purpose of this script is to free up space on the system partition"
echo "[INFO] by moving files not critical to the startup phase to the share.  After"
echo "[INFO] the files have been moved, then symbolic links are set up so that the"
echo "[INFO] old paths remain valid."
echo ""
echo "[INFO] Current file system usage is:"
df -h /
echo "[INFO] Please confirm you want to proceed [y/n]: "
read userreply
if [ "$userreply" != "y" ]
then
	echo "[INFO] ------------------- Aborted MakeSpace script -------------------------"
	exit 0
fi

# Get folder names to be used

echo "[INFO] Please provide following settings (or press ENTER to accept default)"
echo "[INFO] Path to share [$DEV]: "
read userreply
if [ "$userreply" != "" ]
then
	DEV=$userreply
fi
if [ ! -d "$DEV" ]
then
	echo "[ERROR] Specified share does not exist"
	echo "[INFO] ------------------- Aborted MakeSpace script -------------------------"
fi
echo "[INFO] Folder to hold moved folders [$LOCAL]: "
read userreply
if [ "$userreply" != "" ]
then
	LOCAL=$userreply
fi

if [ ! -d $DEV/$LOCAL ]
then
	mkdir $1
	echo "[INFO] directory '$DEV/$LOCAL' created"
fi
chmod 755 $DEV/$LOCAL


checkLink "opt" "/opt"
checkLink "www" "/www"
checkLink "include" "/usr/local/include"
# *** Not sure that library should use symbolic link ***
# *** (May be required before share mounted)         ***
# checkLink "lib" "/usr/local/lib"
checkLink "man" "/usr/local/man"
checkLink "mediaserver" "/usr/local/mediaserver"
checkLink "PCast" "/usr/local/PCast"
checkLink "theme", "/etc/pcast/theme"
checkLink "theme_us", "/etc/pcast/theme_us"
checkLink "samba" "/usr/local/samba"
checkLink "samba2" "/usr/local/samba2"
checkLink "samba3" "/usr/local/samba3"
checkLink "swat" "/usr/local/swat"
checkLink "share" "/usr/local/share"
checkLink "src" "/usr/local/src"
# ensure /usr/local/lib exists for next few opptions to work
if [ ! -d /usr/local/lib -a ! -h /usr/local/lib ]
then
	mkdir /usr/local/lib
fi
checkLink "perl5" "/usr/local/lib/perl5"
checkLink "python2.6" "/usr/local/lib/python2.6"
checkLink "python2.7" "/usr/local/lib/python2.7"
checkLink "python3.1" "/usr/local/lib/python3.1"

# Also set up special link for navigating to linux system via share
if [ ! -h ${DEV}/_root ]
then
	echo ""
	echo "[INFO] It can be convenient to have a way of looking at the"
	echo "[INFO] linux system partition contents from Windows Explorer."
	echo "[INFO] If you want a link called '_root' can be set up"
	echo "[INFO] under your share to support this."
	echo ""
	echo "[INFO] Set up link to system partition [y/n]: "
	read userreply
	if [ "$userreply" = "" ]
	then
		ln -s / $DEV/_root
		echo "[INFO] $DEV/_root linked to '/'"
	fi
fi

echo ""
echo "[INFO] New file system usage is:"
df -h /
echo "[INFO] ------------------- Completed MakeSpace script -------------------------"
exit 0
