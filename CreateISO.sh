#!/bin/bash

#for the case for program yes or no 
#case $answer in
# Y|y|yes|Yes)
# *) for other options
#Example Locations of Ubuntu ISOs
#http://releases.ubuntu.com/16.04.2/
#http://releases.ubuntu.com/17.04/
#http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-server-amd64.iso
#http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-server-i386.iso

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

clear
echo "
...Checking if there is any leftovers from a Previous Install...

..........................Please Wait..........................."
#also create a check for /mnt/iso/md5sum.txt to see if an iso is mounted

if [ -d /opt/serveriso ]; then
echo "Found Serveriso Folder. Removing"
rm -r /opt/serveriso
fi
if [ -d /opt/Ubuntu-Server-Auto-Install ]; then
echo "Found Ubuntu-Server-Auto-Install Folder. Removing"
rm -r /opt/Ubuntu-Server-Auto-Install
fi
if [ -d /opt/ubuntu-*.iso ]; then
echo "Found ubuntu OS ISO File. Removing"
rm /opt/ubuntu-*.iso
fi
echo "Done.."
sleep 1
clear

echo "Installing Required Programs to Run Iso Script"
sleep 2
apt update
apt install git-core genisoimage mount -y
clear

echo "Fully Automated Script to Download Your Ubuntu ISO, "
echo "Unpack it, edit the MyApps Scripts and then Reimage the ISO back together for you"
echo " "
echo "Please only answer questions that are y & n with just y & n "
echo " "
echo "What version of Ubuntu?"
echo "desktop or server?"
read UbuntuDistro

echo "What Version of Ubuntu?"
echo "16.04.3 / 17.04 / Custom Iso?"
read UbuntuDistroVer

echo "What bit version of OS?"
echo "i386(32 bit) or amd64 (64 bit)"
read UbuntuBit

echo "Downloading Distro"
chmod -R 0777 /opt
wget http://releases.ubuntu.com/$UbuntuDistroVer/ubuntu-$UbuntuDistroVer-$UbuntuDistro-$UbuntuBit.iso -P /opt

echo "System Language for the install?"
echo " 'locale' running this Command shows your Current System Setting Format"
echo "ex. en_US is USA English"
currentlang=$(echo $LANG | grep -Poe "[\w]{2}_[\w]{2}")
echo "Current Lang is: $currentlang"
read SystemLanguage

echo "Setting up ISO Folder"
mkdir -p /mnt/iso
cd /opt
sudo mount -o loop /opt/ubuntu-$UbuntuDistroVer-$UbuntuDistro-$UbuntuBit.iso /mnt/iso
mkdir -p /opt/serveriso
echo "Copying over ISO files"
cp -rT /mnt/iso /opt/serveriso
chmod -R 777 /opt/serveriso/
cd /opt/serveriso

#(to set default/only Language of installer)
echo $SystemLanguage >isolinux/langlist 
#edit /opt/serveriso/isolinux/txt.cfg  At the end of the append line add ks=cdrom:/ks.cfg. You can remove quiet — and vga=788
sed -i "s#initrd.gz#initrd.gz ks=cdrom:/ks.cfg#" /opt/serveriso/isolinux/txt.cfg
#edit isolinux.cfg for the timeout option to allow a count down to auto start the installer for about 2 seconds
sed -i "s#timeout 0#timeout 10#" /opt/serveriso/isolinux/isolinux.cfg

#Grabbing Install Scripts from another Repo
git clone https://github.com/tazboyz16/Ubuntu-Server-Auto-Install.git /opt/serveriso
cd /opt/serveriso
#removing unwanted Repo files
rm .travis.yml LICENSE README.md _config.yml

# Setting up KickStart Config File
echo "Renaming Kickstart Config File"
mv ks-example.cfg ks.cfg

echo "Setting up Installer Language"
sed -i "s#en_US#$SystemLanguage#" /opt/serveriso/ks.cfg

echo "System Keyboard Setup ?"
#included grep System for Server edition showed LANG and a LANGUAGE location
currentkeyboard=$(localectl | grep System | grep -Poe "[\w]{2}_[\w]{2}")
echo "Current Keyboard layout: $currentkeyboard"
read SystemKeyboard
sed -i "s#keyboard us#keyboard $SystemKeyboard#" /opt/serveriso/ks.cfg

echo "TimeZone ?"
echo "if dont know the format for your timezone check out:"
echo "https://en.wikipedia.org/wiki/List_of_tz_database_time_zones for a list of TZ Zones"
CurrentTZ=$(cat /etc/timezone)
echo "Current Set TimeZone: $CurrentTZ"
read TimeZone
sed -i "s#America/New_York#$TimeZone#" /opt/serveriso/ks.cfg

echo "Admin Account UserName ?"
read AdminUsername
sed -i "s#xxxusernamexxx#$AdminUsername#g" /opt/serveriso/ks.cfg

echo "Admin Account Password ?"
read AdminPassword
sed -i "s#xxxpasswordxxx#$AdminPassword#" /opt/serveriso/ks.cfg
RandomSalt=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-8})    #Salt limit to 8 Char
AdminPasswordcrypt=$(openssl passwd -1 -salt $RandomSalt $AdminPassword)

echo "Is the password already Ubuntu encrypted?"
read AdminPasswd1
case $AdminPasswd1 in
  	n)
  	echo "Encrypting Paswword"
  	sed -i "s#$AdminPassword#$AdminPasswordcrypt#g" /opt/serveriso/ks.cfg
  ;;
  	*)
  	;;
esac

echo "Swap Partition Size ?"
echo "Partition Setup Does it under MB NOT AS GB"
read SwapPartition
sed -i "s#size 5000#size $SwapPartition#" /opt/serveriso/ks.cfg

echo "Editing FirstbootInstall.sh File"
echo "What Programs to be installed ?"

# Just to renforce FirstbootInstall edit for Program installs
cd /opt/serveriso/myapps/

echo "Install iRedMail ?"
read Installiredmail
case $Installiredmail in
  n|N|no|No)
    sed -e "/mailinstaller.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Apache2 ?"
echo "If no, No webservers will be installed due to only have Apache2 setup scripts"
read InstallApache2
case $InstallApache2 in
  n|N|no|No)
    sed -e "/Apache2-install.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Certbot (Letsencrypt Cert) ?"
echo "If Apache2 was not Selected to be installed, This will not install properly!"
read InstallCertbot
case $InstallCertbot in
  n|N|no|No)
    sed -e "/Certbot.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Mysql and PhpMyAdmin ?"
read InstallMysql
case $InstallMysql in
  n|N|no|No)
    sed -e "/Mysql.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Noip2 Client ?"
read InstallNoip2
case $InstallNoip2 in
  n|N|no|No)
    sed -e "/Noip2Install.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Deluge with web UI ?"
read InstallDeluge
case $InstallDeluge in
  n|N|no|No)
    sed -e "/deluge_webui.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install CouchPotato ?"
read InstallCouchPotato
case $InstallCouchPotato in
  n|N|no|No)
    sed -e "/couchpotato-installer.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install HeadPhones?"
read InstallHeadPhones
case $InstallHeadPhones in
  n|N|no|No)
    sed -e "/headphones-installer.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Mylar ?"
read InstallMylar
case $InstallMylar in
  n|N|no|No)
    sed -e "/mylar-installer.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install SickRage ?"
read InstallSickRage
case $InstallSickRage in
  n|N|no|No)
    sed -e "/sickrage-installer.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Webmin ?"
read InstallWebmin
case $InstallWebmin in
  n|N|no|No)
    sed -e "/webmin-installer.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Plex Media Server?"
read InstallPlexServer
case $InstallPlexServer in
  n|N|no|No)
    sed -e "/plexupdate.sh/d" FirstbootInstall.sh
    	echo "Install Extra Addons to Plex Like WebTools, SickRage, CouchPotato, SpeedTest, Headphones, SS-Plex and SubZero?"
	read Webtoolsoption
	case $Webtoolsoption in
		n|N|no|No)
		sed -e "/Webtools.sh/d" FirstbootInstall.sh;;
		*) ;;
	esac
	echo "Install Plexpy?"
	read Plexpyoption
	case $Plexpyoption in
		n|N|no|No)
		sed -e "/plexpy.sh/d" FirstbootInstall.sh;;
		*) ;;
	esac	
	echo "Install Ombi (Plex Requests) ?"
	read Ombioption
	case $Ombioption in
		n|N|no|No)
		sed -e "/ombi.sh/d" FirstbootInstall.sh;;
		*) ;;
	esac	
	;;
  *)
    ;;
esac

echo "Install Emby Media Server?"
read InstallEmbyServer
case $InstallEmbyServer in
  n|N|no|No)
    sed -e "/EmbyServerInstall.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Grive (Google Drive Sync) ?"
read InstallGrive
case $InstallGrive in
  n|N|no|No)
    sed -e "/GriveInstaller.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install ZoneMinder?"
read InstallZoneMinder
case $InstallZoneMinder in
  n|N|no|No)
    sed -e "/zminstall.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install TeamSpeak 3 Server?"
read InstallTeamSpeakServer
case $InstallTeamSpeakServer in
  n|N|no|No)
    sed -e "/ts3install.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Sonarr?"
read InstallSonarr
case $InstallSonarr in
  n|N|no|No)
    sed -e "/sonarrinstall.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Jackett?"
read InstallJackett
case $InstallJackett in
  n|N|no|No)
    sed -e "/jackettinstall.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Samba?"
read InstallSamba
case $InstallSamba in
  n|N|no|No)
    sed -e "/samba.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Muximux?"
read InstallMuximux
case $InstallMuximux in
  n|N|no|No)
    sed -e "/Muximuxinstall.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install HTPC-Manager?"
read InstallHTPCManager
case $InstallHTPCManager in
  n|N|no|No)
    sed -e "/HTPCManager.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install LazyLibrarian?"
read InstallLazyLibrarian
case $InstallLazyLibrarian in
  n|N|no|No)
    sed -e "/Lazylibrarian.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Shinobi?"
read InstallShinobi
case $InstallShinobi in
  n|N|no|No)
    sed -e "/Shinobi.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install MadSonic?"
read InstallMadSonic
case $InstallMadSonic in
  n|N|no|No)
    sed -e "/MadSonic.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Organizr?"
read InstallOrganizr
case $InstallOrganizr in
  n|N|no|No)
    sed -e "/Organizr.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Ubooquity?"
read InstallUbooquity
case $InstallUbooquity in
  n|N|no|No)
    sed -e "/Ubooquity.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Sinusbot?"
read InstallSinusbot
case $InstallSinusbot in
  n|N|no|No)
    sed -e "/sinusbot.sh/d" FirstbootInstall.sh
    ;;
  *)
    ;;
esac


#https://www.cyberciti.biz/tips/linux-unix-pause-command.html
echo "Pausing in Case for extra edits of myapps"
read -p "Press [Enter] key to Continue"

echo "What Would You like the Disc Labeled As?"
read UbuntuLabel
sudo mkisofs -D -r -V "$UbuntuLabel" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o /opt/$UbuntuLabel.iso /opt/serveriso
sudo chmod -R 777 /opt/$UbuntuLabel.iso

echo "Done Creating Custom Ubuntu Server ISO!!!  Enjoy!!!"
