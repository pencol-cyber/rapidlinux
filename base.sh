#!/bin/bash
#
#################################################################################
#                        Outhouse shell scripting for linux boxen at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
#################################################################################
#
# Define globals here to avoid my slow, buggy, inaccurate auto-detection routines
#          or to disable the sub modules you don't need and/or are not applicable
#
# IPv4 you connect from?
export MY_IPV4=undef
# IPv4 of this computer?
export BOX_IPV4=undef
# What OS we on?
export OS_NAME=undef
# Package Manager?
export OS_PKG_MGR=undef
# Where we at?
export SCRIPT_HOME=`pwd`
# where to store discovery items?
export SCRIPT_HOME_INFOS=$SCRIPT_HOME/infos
# where to store originals of files we modify?
export SCRIPT_HOME_BACKUPS=$SCRIPT_HOME/backups
# Username to add & allow in SSH?
export MY_USERNAME=bofh
# white team account name?
export SUPPORT_ACCOUNT=undef

# Do sanity checks?
DO_SANITY_CHECK=yes
# Do Package Manager check?
DO_PKG_MGR_CHECK=yes
# Do Account management?
DO_ACCT_MGMT=yes
# Do backups?
DO_BACKUPS=yes
# Do updates?
DO_UPDATES=yes
# Do SSHd Configuration?
DO_SSHD_CONFIG=yes
# Do Firewall Configuration?
DO_FIREWALL=yes
# Create file intergrity diffing?
DO_HASHING=yes
# Use modules for other services?
DO_OPT_SERVICES=yes

echo -e "\e[32m\e[1m__________________________________________________________________________\e[0m"
echo -e "\e[32m\e[1m################## ddd ####################################################\\ \e[0m"
echo -e "\e[32m\e[1m                   ddd                                       rapidlinux  ##\\ \e[0m"
echo -e "\e[32m\e[1m                   ddd                                                   ##\\ \e[0m"
echo -e "\e[32m\e[1m   r rrrrr       d ddd                                                   ##\\ \e[0m"
echo -e "\e[32m\e[1m  rrrr  rrr    ddd ddd                              prccdc toolkit 2016  ##\\ \e[0m"
echo -e "\e[32m\e[1m  rrr   rrr   ddd  ddd                                  bofh@pencol.edu  ##\\ \e[0m"
echo -e "\e[32m\e[1m  rrr         dddd ddd                                                   ##\\ \e[0m"
echo -e "\e[32m\e[1m  rrr          ddddddd                                                   ##\\ \e[0m"
echo -e "\e[32m\e[1m  rrr \e[0m"
echo ''
echo ''

m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[32mBase\e[0m]"


function sanity_check {

  default_shell=`readlink -f /bin/sh`
  echo -e "\e[2m[\e[36m.\e[0m\e[2m]\e[0m Your default system shell appears to be \e[34m$default_shell\e[0m"
  echo -e "\e[2m[\e[36m.\e[0m\e[2m]\e[0m This script is currently running under \e[34m$SHELL\e[0m"
  
  if [[ "$default_shell" != /bin/bash && "$default_shell" != /usr/bin/bash ]] ; then
      $m_issue"\e[34m$default_shell\e[0m is not bash, this could be an issue"
      if [[ $BASH == "" ]] ; then
      `which bash`
      fi
  fi
sleep 2
clear

  if [[ "$EUID" -ne 0 ]] ; then
      $m_issue"Script invoked as \e[34m`whoami`\e[0m"
      $m_issue"You don\'t seem to be running with sufficient permissions."
      $m_issue".. you may need to \e[31msu\e[0m/\e[31msudo\e[0m first before invoking this script"
      echo
      exit 1
  fi
  
  # essential bins needed by this script and sub-modules
  missings_deps=0
  reqs="bash cut passwd useradd chpasswd iptables ip6tables usermod wc tr chattr grep netstat chmod ifconfig tar diff adduser su sed"
  for req_binary in $reqs ; do
    which $req_binary &> /dev/null
      if [[ $? -eq 0 ]] ; then
	  $m_inform"I have \e[34m`printf %10s $req_binary`\e[0m at \e[2m`which $req_binary`\e[0m "
	else
	  $m_issue"No \e[31m`printf %14s $req_binary`\e[0m found, please verify your coreutils installation"
	  let missings_deps=$((++missings_deps))
      fi
   done
   sleep 2

  if [[ $missings_deps -ge 1 ]] ; then
      echo
      $m_issue"You have \e[31m$missings_deps\e[0m missing binaries that this script is dependent upon"
      echo
      $m_issue"This could cause the script to go off the rails, up to and including trashing the entire system"
      $m_issue"It is recommended to quit now and fix these dependency issues before continuing"
      echo
      $m_choose"I understand the risks, continue anyway  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
      read -p "> " -t 60 continue_anyway
      
	if [[ $continue_anyway != "y" && $continue_anyway != "Y" ]] ; then
	  exit 1
	fi
  fi
  
}

function get_pkgmgr {

if [[ -r /etc/issue ]] ; then
    $m_inform"[\e[94m/etc/issue\e[0m] exists and is readable"
    OS_NAME=`head -n 1 /etc/issue | cut -f 1 -d " " | xargs`
    OSVersion=`head -n 1 /etc/issue | cut -f 2 -d " " | xargs`
    $m_inform"Invoking package manager determination based on found strings [\e[35m$OS_NAME\e[34m $OSVersion\e[0m]"
    
      case "$OS_NAME" in
	      [Uu]buntu)
		export OS_PKG_MGR=apt
		$m_inform"selected [\e[35m$OS_PKG_MGR\e[0m] for Ubuntu based system"
	      ;;
         
	      [Ff]edora)
		export OS_PKG_MGR=yum
		$m_inform"selected [\e[35m$OS_PKG_MGR\e[0m] for Fedora based system"	   
	      ;;

	[Cc]ent[Oo][Ss])
		export OS_PKG_MGR=yum
		$m_inform"selected [\e[35m$OS_PKG_MGR\e[0m] for CentOS based system"	   
	      ;;

	      [Dd]ebian)
		export OS_PKG_MGR=apt
		$m_inform"selected [\e[35m$OS_PKG_MGR\e[0m] for Debian based system"	    
	      ;;
	    
		      *)
		$m_issue"Unable to determine package manager using /etc/issue method"
		echo
	      
      esac
    
  else
    $m_issue"No [\e[34m/etc/issue\e[0m] found"
    
fi

  
  if [[ "$OS_PKG_MGR" == undef ]] ; then
      $m_issue"We seem to have a problem, boss"
      $m_issue"I can't determine your OS and package manager combination from issue method"
      $m_issue"... trying fallback methods"
      echo
      #exit 1
        try_names="yum dpkg apt slackpkg pacman zypper urpmi netpkg emerge"
	  for pkgman_tools in $try_names ; do
	    $m_inform"Trying to find a \e[2m$pkg_tools\e[0m on the system ..."
	    which $pkgman_tools &> /dev/null
		if [[ $? -eq 0 ]] ; then
		  export OS_PKG_MGR=`which $pkgman_tools`
		  $m_inform"Discovered \e[34m`printf %10s $pkgman_tools`\e[0m at \e[2m$OS_PKG_MGR\e[0m "
		fi
	    done
	    
	    #Still no go? the hell with it, quittin time
	  if [[ "$OS_PKG_MGR" == undef ]] ; then
	    $m_issue"Could not reliably determine the package management system ... quitting"
	    #exit 1
	  fi
  fi
}

  
# Go!
  if [[ "$DO_SANITY_CHECK" == yes ]] ; then
      sanity_check
  fi
  if [[ "$DO_PKG_MGR_CHECK" == yes ]] ; then  
    if [[ "$OS_PKG_MGR" == undef ]] ; then
      get_pkgmgr
    fi
  fi

  if [[ -d "$SCRIPT_HOME_INFOS" ]] ; then
    sleep 1
  else
    mkdir $SCRIPT_HOME_INFOS
  fi

  if [[ -d "$SCRIPT_HOME_BACKUPS" ]] ; then
    sleep 1
  else
    mkdir $SCRIPT_HOME_BACKUPS
  fi
  
  if [[ -n "$MY_USERNAME" && "$MY_USERNAME" != undef ]] ; then
    if [[ -r "$SCRIPT_HOME_INFOS/my_username.txt" ]] ; then
      sleep 1
    else
      echo $MY_USERNAME > $SCRIPT_HOME_INFOS/my_username.txt
    fi
  fi
  
# Kick off subscripts - accts/firewall/services query/patching
#
#
  if [[ "$DO_ACCT_MGMT" == yes ]] ; then
    # script anticipates: $1r [new|modify]  $2o [skip_create]
    $m_choose"Should we do some account management now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_usermod
      if [[ "$invoke_usermod" == y || "$invoke_usermod" == Y ]] ; then
	echo
	$SCRIPT_HOME/modules/core_accounts.sh new
      fi
    fi

  if [[ "$DO_BACKUPS" == yes ]] ; then
    # script anticipates: $1r [new| 'name of location to backup ]
    $m_choose"Should we backup existing files now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_backups
      if [[ "$invoke_backups" == y || "$invoke_backups" == Y ]] ; then
	echo
	$SCRIPT_HOME/modules/core_backups.sh new 
      fi
    fi

  if [[ "$DO_UPDATES" == yes ]] ; then
    # script anticipates: $1o [new| or 'name of package to update']
    $m_choose"Should we do some updates and patching now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_updates
      if [[ "$invoke_updates" == y || "$invoke_updates" == Y ]] ; then
	echo
	$SCRIPT_HOME/modules/core_updates.sh new
      fi
    fi

   if [[ "$DO_SSHD_CONFIG" == yes ]] ; then
    $m_choose"Should we configure the Secure Shell (sshd) Server now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_sshd
      if [[ "$invoke_sshd" == y || "$invoke_sshd" == Y ]] ; then
	echo
	# no params
	$SCRIPT_HOME/modules/core_sshd.sh
	# no params
	$SCRIPT_HOME/modules/hunt_sshd_keys.sh
      fi
    fi
    
   if [[ "$DO_FIREWALL" == yes ]] ; then
   # script anticipates: $1r [new|add] $2o 'name of service to allow' $3o '.. but only from this $3 ipv4 address
    $m_choose"Should we configure the firewall now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_firewall
      if [[ "$invoke_firewall" == y || "$invoke_firewall" == Y ]] ; then
	echo
	$SCRIPT_HOME/modules/core_networking.sh new
	$SCRIPT_HOME/modules/firewall_cron.sh
	$SCRIPT_HOME/modules/ipv6_disable.sh
      fi
    fi

    if [[ "$DO_OPT_SERVICES" == yes ]] ; then
    $m_choose"Should we try to determine what services this server runs?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_opt_services
      if [[ "$invoke_opt_services" == y || "$invoke_opt_services" == Y ]] ; then
	echo
	$SCRIPT_HOME/modules/http_service_check.sh
	$SCRIPT_HOME/modules/sql_service_check.sh
	$SCRIPT_HOME/modules/mail_service_check.sh
      fi
    fi
    
   if [[ "$DO_HASHING" == yes ]] ; then
    # script aticipates: 3-4 params, descibed below
    
    $m_choose"Should we setup a base for file intergrity monitoring now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_diffing
      if [[ "$invoke_diffing" == y || "$invoke_diffing" == Y ]] ; then
	echo
	# core_diffing -1r (new|compare) -2r filesystem -3r name -4o [no_descend] dont examine subfolders
	$SCRIPT_HOME/modules/core_diffing.sh new /etc etc no_descend
	$SCRIPT_HOME/modules/core_diffing.sh new /etc/init.d init.d no_descend
	$SCRIPT_HOME/modules/core_diffing.sh new /etc/ssh ssh no_descend
	$SCRIPT_HOME/modules/core_diffing.sh new /bin bin
	$SCRIPT_HOME/modules/core_diffing.sh new /sbin sbin
	$SCRIPT_HOME/modules/core_diffing.sh new /tmp tmp
	$SCRIPT_HOME/modules/core_diffing.sh new /root root
      fi
    fi
    
    echo
    $m_inform" .. rapidlinux has completed it's run!"