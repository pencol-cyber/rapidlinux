#!/bin/bash
#
#################################################################################
#             	      Outhouse shell scripting for quick updating at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[95m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[96m=\e[0m\e[2m]\e[0m "

# override the autodetection of package manager here
# 	OS_PKG_MGR=undef
# or dir for info + crontabs
# 	SCRIPT_HOME_INFOS=../infos


function apt_do_base {
    deb_core="bash openssh-server openssl libc-bin coreutils linuxtools apparmor"
    deb_opt="iptraf"
    for pkg in $deb_core ; do
	apt-get upgrade $pkg -y
    done
        for pkg in $deb_opt ; do
	apt-get install $pkg -y
    done
}

function apt_do_mysql {
    apt-get upgrade mysql-server -y
}

function apt_do_apache {
    apt-get upgrade apache2 -y
    a2opt="libapache2-mod-apparmor libapache2-modsecurity"
    for pkg in $a2opt ; do
	 apt-get install $pkg -y
    done
}

function apt_do_dovecot {
    apt-get upgrade dovecot-core -y
}

function apt_schedule_cron {

    # you should totally change the dates on this
    # mine are one-time usage for 2016-04-01
    
    $m_inform"This subsection attempts to do two things:"
    $m_inform"    1) schedule a full update to kick off at \e[33m7:08pm\e[0m on \e[33m04/01\e[0m"
    $m_inform"    2) schedule a reboot for \e[32m3:01am\e[0m on \e[32m04/02\e[0m"
    echo
    $m_inform"Hopefully this gets you a hardened server, and zero effective down-time"
    echo
    $m_choose"Add scheduler now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_scheduler
            if [[ "$invoke_scheduler" == y || "$invoke_scheduler" == Y ]] ; then
	    
	    #minute/hour/day of month/month/day in week
	    which
	    echo "apt-get upgrade -y" > $SCRIPT_HOME_INFOS/rapid-upgrade-deb.sh
	    chmod 700 $SCRIPT_HOME_INFOS/rapid-upgrade-deb.sh
	    echo "8 19 1 4 * $SCRIPT_HOME_INFOS/rapid-upgrade-deb.sh" >> $SCRIPT_HOME_INFOS/mycronjobs.cron
	    echo "31 3 2 4 * /sbin/reboot" >> $SCRIPT_HOME_INFOS/mycronjobs.cron
	    crontab file $SCRIPT_HOME_INFOS/mycronjobs.cron

if [[ $1 == new ]] ; then
  if [[ "$OS_PKG_MGR" != undef && "$OS_PKG_MGR" != "" ]] ; then
      
       case "$OS_PKG_MGR" in
	    apt)
		$m_inform"Using [\e[94m$OS_PKG_MGR\e[0m] for Debian / Ubuntu based systems"
		apt-get update
		apt_do_base
		apt_schedule_cron
	      ;;
         
	    yum)
		$m_inform"selected [\e[94m$OS_PKG_MGR\e[0m] for Fedora / CentOS based systems"
		yum check-update
		yum_do_base
		yum_schedule_cron
	      ;;

	 zypper)
		$m_inform"selected [\e[94m$OS_PKG_MGR\e[0m] for SuSE based systems"
		zypper refresh
		zypper_do_base
	      ;;

	 something_i_never_defined)
	 
	      ;;
	    
	      *)
		$m_issue"No loginc defined for your currently set package manager [\e[94m$OS_PKG_MGR\e[0m]"
		echo
		exit 1
	      
      esac

if [[ $1 != new ]] ; then
  if [[ "$OS_PKG_MGR" != undef && "$OS_PKG_MGR" != "" ]] ; then
      
       case "$OS_PKG_MGR" in
	    apt)
		$m_inform"Using [\e[94m$OS_PKG_MGR\e[0m] for Debian / Ubuntu based systems"
		case $1 in
		      mysql)
		      apt_do_mysql
		      ;;
		      apache)
		      apt_do_apache
		      ;;
		      postgres)
		      apt-get upgrade $1 -y
		      ;;
		      postfix)
		      apt-get upgrade $1 -y
		      ;;
		      dovecot)
		      apt_do_dovecot
		      ;;
		      nginx)
		      apt-get upgrade $1 -y
		      ;;
		      *)
		      $m_inform"No predefined rule found for $1, trying to upgrade it anyway ..."
		      apt-get upgrade $1		
	      ;;
         
	    yum)
		$m_inform"selected [\e[94m$OS_PKG_MGR\e[0m] for Fedora / CentOS based systems"
		yum upgrade $1
	      ;;

	 zypper)
		$m_inform"selected [\e[94m$OS_PKG_MGR\e[0m] for SuSE based systems"
		zypper update -t $1
	      ;;

	 something_i_never defined)
		$m_inform"selected [\e[94m$OS_PKG_MGR\e[0m] for () based systems"
	      ;;
	    
	      *)
		$m_issue"No logic defined for your currently set package manager [\e[94m$OS_PKG_MGR\e[0m]"
		echo
		exit 1
	      
      esac
  fi
fi


    