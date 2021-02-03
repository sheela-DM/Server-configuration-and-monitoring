#!/bin/bash

source util/echo.sh
source util/system.sh

require_root

trap '' 2 # You can't use Ctrl+C to terminate the process

# Servers
declare -a SERVER_MONITERING=("" "SERVER MONITERING")
declare -a WEB_SERVER=("apache2" "WEB Server")
declare -a SFTP_SERVER=("openssh-server" "SFTP Server")
declare -a SSH_SERVER=("ssh" "SSH Server")
declare -a SMB_SERVER=("samba" "SMB Server")

# Console text color
declare -A COLOR
COLOR[BLACK]="\e[1;30"
COLOR[RED]="\e[0m\e[1;31m" 
COLOR[GREEN]="\e[0m\e[1;32m" 
COLOR[YELLOW]="\e[0m\e[1;33m"
COLOR[BLUE]="\e[0m\e[1;34m"
COLOR[PURPLE]="\e[0m\e[1;35m"
COLOR[CYAN]="\e[0m\e[1;36m"
COLOR[WHITE]="\e[0m\e[1;37m"
COLOR[END]="\e[0m"

# Header about
function header() {
	clear
    echo.success_b "                                                         ";
    echo.success_b "                 __  ___ _ ____   _____ _ __             ";
    echo.success_b "               / __|/ _ \ '__\ \ / / _ \ '__|            ";
    echo.success_b "               \__ \  __/ |   \ V /  __/ |               ";
    echo.success_b "               |___/\___|_|    \_/ \___|_|               ";
    echo.success_b "                                                         ";
    echo.success_b "             +-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+         ";
    echo.success_b "             |D|e|v|e|l|o|p| |b|y| |D|i|t|i|s|s|         ";
    echo.success_b "             +-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+         ";
    # echo.info_b "File name: $0"
}


function sftp_conf() {

read -p 'Please enter path :' path
read -p 'Username :' user_n
read -p 'IP :' ip
read -p 'Which file you want to upload :' upload
read -p 'Which file you want to download :' download
sftp $user_n@$ip << EOF
cd $path
put $upload
get $download
bye
EOF
exit 0
}


function smb_conf() {
read -p 'Enter the path of file which you want to share :' path 
read -p 'Enter the permission for file :' per

# Install Samba

samba_not_installed=$(dpkg -s samba 2>&1 | grep "not installed")
if [ -n "$samba_not_installed" ];then
  echo "Installing Samba"
  apt-get install samba -y
fi

# Configure directory that will be accessed with Samba

echo "
[IT]
comment = My Public Folder
path = $path
public = yes
writable = yes
create mast = 0$per
force user = root
force group = root
guest ok = yes
security = SHARE
" | tee -a /etc/samba/smb.conf

# Restart Samba service

/etc/init.d/smbd restart

# Give persmissions to shared directory

chmod -R $per $path

exit 0
} 


function web_conf() {

echo " hello DITISS " > /var/www/html/index.html
echo " Web Server is READY " 
exit 0
}

function setup_svr()
{

case $server_package in
                    samba)
                        echo "Setup $server_name"
                        smb_conf
		    ;;
		    openssh-server)
		        echo "Setup $server_name"
		  	sftp_conf
		    ;;
		    apache2)
			echo "Setup $server_name"
			web_conf
		    ;;
                esac
}

function server_conf() {

    declare -a SERVER=("${!1}")
    local server_package=${SERVER[0]}
    local server_name=${SERVER[1]}

    while [[ "$REPLY" != 0 ]]; do
        clear
        header
        echo -e ${COLOR[YELLOW]}"-- $server_name options --";
        echo 
        echo "  1. Check if it is installed";
        echo "  2. Install";
        echo "  3. Uninstall";
        echo "  0. Exit";
        echo
        read -p "What do you want to do? " -n 1
        echo -e 

        case $REPLY in
            0)
                echo.success_b "Done"
            ;;
            1) 
                is_installed $server_package
                readKey
            ;;
            2)
                install_package $server_package
		readKey
                setup_svr
            ;;
            3)
                uninstall_package $server_package
                readKey
            ;;
            *) 
                echo.error_b "Invalid option"
                readKey
            ;;
        esac
    done
}

function server_moniter() {

# unset any variable which system may be using

# clear the screen
clear

unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

while getopts iv name
do
        case $name in
          i)iopt=1;;
          v)vopt=1;;
          *)echo "Invalid arg";;
        esac
done

if [[ ! -z $iopt ]]
then
{
wd=$(pwd)
basename "$(test -L "$0" && readlink "$0" || echo "$0")" > /tmp/scriptname
scriptname=$(echo -e -n $wd/ && cat /tmp/scriptname)
su -c "cp $scriptname /usr/bin/monitor" root && echo "Congratulations! Script Installed, now run monitor Command" || echo "Installation failed"
}
fi

if [[ ! -z $vopt ]]
then
{
echo -e "tecmint_monitor version 0.1\nDesigned by cloudnetwork.in\nReleased Under Apache 2.0 License"
}
fi

if [[ $# -eq 0 ]]
then
{


# Define Variable tecreset
tecreset=$(tput sgr0)

# Check if connected to Internet or not
ping -c 1 google.com &> /dev/null && echo -e '\E[32m'"Internet: $tecreset Connected" || echo -e '\E[32m'"Internet: $tecreset Disconnected"

# Check OS Type
os=$(uname -o)
echo -e '\E[32m'"Operating System Type :" $tecreset $os

# Check OS Release Version and Name
cat /etc/os-release | grep 'NAME\|VERSION' | grep -v 'VERSION_ID' | grep -v 'PRETTY_NAME' > /tmp/osrelease
echo -n -e '\E[32m'"OS Name :" $tecreset  && cat /tmp/osrelease | grep -v "VERSION" | cut -f2 -d\"
echo -n -e '\E[32m'"OS Version :" $tecreset && cat /tmp/osrelease | grep -v "NAME" | cut -f2 -d\"

# Check Architecture
architecture=$(uname -m)
echo -e '\E[32m'"Architecture :" $tecreset $architecture

# Check Kernel Release
kernelrelease=$(uname -r)
echo -e '\E[32m'"Kernel Release :" $tecreset $kernelrelease

# Check hostname
echo -e '\E[32m'"Hostname :" $tecreset $HOSTNAME

# Check Internal IP
internalip=$(hostname -I)
echo -e '\E[32m'"Internal IP :" $tecreset $internalip

# Check External IP
externalip=$(curl -s ipecho.net/plain;echo)
echo -e '\E[32m'"External IP : $tecreset "$externalip

# Check DNS
nameservers=$(cat /etc/resolv.conf | sed '1 d' | awk '{print $2}')
echo -e '\E[32m'"Name Servers :" $tecreset $nameservers

# Check Logged In Users
who>/tmp/who
echo -e '\E[32m'"Logged In users :" $tecreset && cat /tmp/who

# Check RAM and SWAP Usages
free -h | grep -v + > /tmp/ramcache
echo -e '\E[32m'"Ram Usages :" $tecreset
cat /tmp/ramcache | grep -v "Swap"
echo -e '\E[32m'"Swap Usages :" $tecreset
cat /tmp/ramcache | grep -v "Mem"

# Check Disk Usages
df -h| grep 'Filesystem\|/dev/sda*' > /tmp/diskusage
echo -e '\E[32m'"Disk Usages :" $tecreset
cat /tmp/diskusage

# Check Load Average
loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $10 $11 $12}')
echo -e '\E[32m'"Load Average :" $tecreset $loadaverage

# Check System Uptime
tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e '\E[32m'"System Uptime Days/(HH:MM) :" $tecreset $tecuptime

# Unset Variables
unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

# Remove Temporary Files
rm /tmp/osrelease /tmp/who /tmp/ramcache /tmp/diskusage
}
fi
shift $(($OPTIND -1))

echo -e '\E[32m'"SERVER STATUS           ";
smanager=$(ps -p1 | grep "init\|systemd" | awk '{print $4}')
for serv in ssh apache2 smbd 
do
if (( $(pgrep $serv | wc -l) > 0 ))
then
echo -e '\E[37m'"$serv is running!!!"
elif [ "$smanager" == "init" ]
then 
service $serv start
echo "$serv service is UP now.!"
else
systemctl start $serv
echo "$serv service is UP now.!"
fi
done
}



while [[ "$REPLY" != 0 ]]; do
    header
    echo -e ${COLOR[YELLOW]}"-- Main menu --"
    echo
    echo "This script will help you install and configure the following servers quickly:";
    echo
    echo "  1. ${SERVER_MONITERING[1]}";
    echo "  2. ${WEB_SERVER[1]}";
    echo "  3. ${SFTP_SERVER[1]}";
    echo "  4. ${SSH_SERVER[1]}";
    echo "  5. ${SMB_SERVER[1]}";
    echo "  0. Exit";
    echo
    read -p "Choose an option > " -n 1
    echo -e

    case $REPLY in
        0)
            echo -e ${COLOR[GREEN]}"Program terminated .... [OK]"
        ;;
        1)
            server_moniter
	    break
        ;;
        2)
            server_conf WEB_SERVER[@]
            break
	;;
        3)
            server_conf SFTP_SERVER[@]
	    break
	;;
        4)
            server_conf SSH_SERVER[@]
            break
	;;
	5)
	    server_conf SMB_SERVER[@]
	    break
	;;
        *)
            echo -e ${COLOR[RED]}"Invalid option"
            readKey "press a key to continue..."
        ;;
    esac

done

