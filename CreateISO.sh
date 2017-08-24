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
echo
echo
echo "...Checking if there is any leftovers from a Previous Install...


..........................Please Wait..........................."

if [ -d /opt/serveriso || /opt/Ubuntu-Server-Auto-Install || -d /opt/ubuntu-*.iso ]; then
echo "Removing Old Config Files"
rm -r /opt/serveriso
rm -r /opt/Ubuntu-Server-Auto-Install
rm /opt/ubuntu-*.iso
fi
echo "Done.."
sleep 1
clear

echo "Installing Required Programs to Run Iso Script"
sleep 1
apt update
apt install git-core genisoimage mount -y

clear
echo "Fully Automated Script to Download Your Ubuntu ISO, "
echo "Unpack it, edit the MyApps Scripts and then ReImage the ISO back together for you"
echo " "
echo "Please only answer questions that are y & n with just y & n "
echo " "
echo "What version of Ubuntu?"
echo "desktop or server?"
read UbuntuDistro

echo "What Version of Ubuntu?"
echo "16.04.3 17.04?"
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
read SystemLanguage

echo "Setting up ISO Folder"
sudo mkdir -p /mnt/iso
cd /opt
sudo mount -o loop ubuntu-$UbuntuDistroVer-$UbuntuDistro-$UbuntuBit.iso /mnt/iso
sudo mkdir -p /opt/serveriso
echo "Copying over ISO files"
sudo cp -rT /mnt/iso /opt/serveriso
sudo chmod -R 777 /opt/serveriso/
cd /opt/serveriso

#(to set default/only Language of installer)
echo $SystemLanguage >isolinux/langlist 
#edit /opt/serveriso/isolinux/txt.cfg  At the end of the append line add ks=cdrom:/ks.cfg. You can remove quiet — and vga=788
sed -i "s#initrd.gz#initrd.gz ks=cdrom:/ks.cfg#" /opt/serveriso/isolinux/txt.cfg
#edit isolinux.cfg for the timeout option to allow a count down to auto start the installer for about 2 seconds
sed -i "s#timeout 0#timeout 10#" /opt/serveriso/isolinux/isolinux.cfg


cd /opt && git clone https://github.com/tazboyz16/Ubuntu-Server-Auto-Install.git
cd /opt/Ubuntu-Server-Auto-Install

rm README.md
rm _config.yml
cd /opt/serveriso
mv /opt/Ubuntu-Server-Auto-Install/ks-example.cfg /opt/serveriso
mv /opt/Ubuntu-Server-Auto-Install/myapps /opt/serveriso

echo "Setting up KickStart Config File"

echo "Renaming Kickstart Config File"
mv ks-example.cfg ks.cfg

echo "Setting up Installer Language"
sed -i "s#en_US#$SystemLanguage#" /opt/serveriso/ks.cfg

#dpkg-reconfigure keyboard-configuration
echo "System Keyboard Setup ?"
read SystemKeyboard
sed -i "s#keyboard us#keyboard $SystemKeyboard#" /opt/serveriso/ks.cfg

echo "TimeZone ?"
echo "if dont know the format for your timezone check out:"
echo "https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
read TimeZone
sed -i "s#America/New_York#$TimeZone#" /opt/serveriso/ks.cfg

echo "Admin Account UserName ?"
read AdminUsername
sed -i "s#xxxusernamexxx#$AdminUsername#g" /opt/serveriso/ks.cfg

echo "Admin Account Password ?"
read AdminPassword
sed -i "s#xxxpasswordxxx#$AdminPassword#" /opt/serveriso/ks.cfg
RandomSalt=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-8})
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

echo "Install iRedMail ?"
read Installiredmail
case $Installiredmail in
  n|N|no|No)
    sed -i "s#mailinstaller.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Apache2 ?"
echo "If no, No webservers will be installed due to only have Apache2 setup scripts"
read InstallApache2
case $InstallApache2 in
  n|N|no|No)
    sed -i "s#Apache2-install.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Cerbot (Lets Encrypt Cert) ?"
echo "If Apache2 was not Selected to be installed, This will not install properly!!!"
read InstallCerbot
case $InstallCerbot in
  n|N|no|No)
    sed -i "s#Certbot.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Mysql and PhpMyAdmin ?"
read InstallMysql
case $InstallMysql in
  n|N|no|No)
    sed -i "s#Mysql.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Noip2 Client ?"
read InstallNoip2
case $InstallNoip2 in
  n|N|no|No)
    sed -i "s#Noip2Install.sh# #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Deluge with web UI ?"
read InstallDeluge
case $InstallDeluge in
  n|N|no|No)
    sed -i "s#deluge_webui.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install CouchPotato ?"
read InstallCouchPotato
case $InstallCouchPotato in
  n|N|no|No)
    sed -i "s#couchpotato-installer.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install HeadPhones?"
read InstallHeadPhones
case $InstallHeadPhones in
  n|N|no|No)
    sed -i "s#headphones-installer.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Mylar ?"
read InstallMylar
case $InstallMylar in
  n|N|no|No)
    sed -i "s#mylar-installer.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install SickRage ?"
read InstallSickRage
case $InstallSickRage in
  n|N|no|No)
    sed -i "s#sickrage-installer.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Webmin ?"
read InstallWebmin
case $InstallWebmin in
  n|N|no|No)
    sed -i "s#webmin-installer.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Plex Media Server?"
read InstallPlexServer
case $InstallPlexServer in
  n|N|no|No)
    sed -i "s#plexupdate.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    sed -i "s#PlexAddons.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Emby Media Server?"
read InstallEmbyServer
case $InstallEmbyServer in
  n|N|no|No)
    sed -i "s#EmbyServerInstall.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Grive (Google Drive Sync) ?"
read InstallGrive
case $InstallGrive in
  n|N|no|No)
    sed -i "s#GriveInstaller.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install ZoneMinder?"
read InstallZoneMinder
case $InstallZoneMinder in
  n|N|no|No)
    sed -i "s#zminstall.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install TeamSpeak 3 Server?"
read InstallTeamSpeakServer
case $InstallTeamSpeakServer in
  n|N|no|No)
    sed -i "s#ts3install.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Sonarr?"
read InstallSonarr
case $InstallSonarr in
  n|N|no|No)
    sed -i "s#sonarrinstall.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Jackett?"
read InstallJackett
case $InstallJackett in
  n|N|no|No)
    sed -i "s#jackettinstall.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Samba?"
read InstallSamba
case $InstallSamba in
  n|N|no|No)
    sed -i "s#samba.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Muximux?"
read InstallMuximux
case $InstallMuximux in
  n|N|no|No)
    sed -i "s#Muximuxinstall.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install HTPC-Manager?"
read InstallHTPCManager
case $InstallHTPCManager in
  n|N|no|No)
    sed -i "s#HTPCManager.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install LazyLibrarian?"
read InstallLazyLibrarian
case $InstallLazyLibrarian in
  n|N|no|No)
    sed -i "s#Lazylibrarian.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Shinobi?"
read InstallShinobi
case $InstallShinobi in
  n|N|no|No)
    sed -i "s#Shinobi.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install MadSonic?"
read InstallMadSonic
case $InstallMadSonic in
  n|N|no|No)
    sed -i "s#MadSonic.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Organizr?"
read InstallOrganizr
case $InstallOrganizr in
  n|N|no|No)
    sed -i "s#Organizr.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Ubooquity?"
read InstallUbooquity
case $InstallUbooquity in
  n|N|no|No)
    sed -i "s#Ubooquity.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
    ;;
  *)
    ;;
esac

echo "Install Sinusbot?"
read InstallSinusbot
case $InstallSinusbot in
  n|N|no|No)
    sed -i "s#sinusbot.sh#  #" /opt/serveriso/myapps/FirstbootInstall.sh
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
sudo chmod -R 777 /opt

echo "Done Creating Custom Ubuntu Server ISO!!!  Enjoy!!!"
