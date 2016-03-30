#!/bin/bash
#
#################################################################################
#             	     Outhouse shell scripting for SSH key hunting at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[33mSSH Key Hunter\e[0m]"

function purge_ssh_key {
    # ... it's the only way to be sure
    
    $m_inform"Nuking \e[31m$1\e[0m from orbit"
    rm -f $1
    echo
}

function backup_before_deleting {
    # why you would want this, i dont really know
    
    if [[ -d ../backups/ ]] ; then
      sleep 1
    else
      mkdir ../backups
    fi
    
    if [[ -d ../backups/ssh ]] ; then
      sleep 1
    else
      mkdir ../backups/ssh
    fi
    
    if [[ -d ../backups/ssh/found_keys ]] ; then
      sleep 1
    else
      mkdir ../backups/ssh/found_keys
    fi

    $m_inform"Backing up the key for \e[31m$2\e[0m to \e[2mbackups/ssh/found_keys\e[0m, and then removing it."
    somecrap=$((RANDOM%10000))
    cp $1 ../backups/ssh/found_keys/user.$2.sshd.key.$somecrap.pub
    rm -f $1
    
}


function find_keys {

      # expects one arg, mode switch [check/backup/destroy]
      # usage should be obvious
      
mode=$1
violations=0
users=`cat /etc/passwd | cut -f 1 -d ":"`

    for user in $users ; do
	userhome=`cat /etc/passwd | grep -e ^$user: | cut -f 6 -d ":"`
	$m_inform"Checking user \e[34m$user\e[0m files in \e[35m$userhome\e[0m ..."

	if [[ -e $userhome/.ssh/authorized_keys ]] ; then
	  $m_issue"User \e[31m$user\e[0m has a v1.0 ssh keyfile in home directory \e[35m$userhome/.ssh/\e[0m"
	  
	  if [[ $mode == check ]] ; then
	    let violations=$((++violations))
	  fi
	  if [[ $mode == backup ]] ; then
	    backup_before_deleting $userhome/.ssh/authorized_keys $user
	  fi
	  if [[ $mode == kill ]] ; then
	    purge_ssh_key $userhome/.ssh/authorized_keys
	  fi
	fi
	
	if [[ -e $userhome/.ssh/authorized_keys2 ]] ; then
	  # did you know this would work too? i didn't, but hooray for manpages
	  
	  $m_issue"User \e[31m$user\e[0m has a v2.0 ssh keyfile in home directory \e[35m$userhome/.ssh/\e[0m"
	  
	  if [[ $mode == check ]] ; then
	    let violations=$((++violations))
	  fi
	  if [[ $mode == backup ]] ; then
	    backup_before_deleting $userhome/.ssh/authorized_keys2 $user
	  fi
	  if [[ $mode == kill ]] ; then
	    purge_ssh_key $userhome/.ssh/authorized_keys2
	  fi
	fi
    done
}


    find_keys check

    if [[ $violations -eq 0 ]] ; then
	$m_inform"\e[32mNo ssh keys\e[0m found, good"
    else
	$m_issue"Discovered \e[31m$violations\e[0m SSH Keys in use on this system"
	echo
	$m_issue"Do you want me to [\e[32mb\e[0m]ackup them up, [\e[31md\e[0m]elete them, or do [\e[33mn\e[0m]othing?  \e[2m[\e[32m\e[1mb\e[0m\e[2m|\e[31m\e[1md\e[0m\e[2m|\e[33m\e[1mn\e[0m\e[2m] \e[0m"
	read -p "> " -t 60 ssh_key_action
	
	if [[ $ssh_key_action == b ]] ; then
	  find_keys backup
	fi
	
	if [[ $ssh_key_action == d ]] ; then
	  find_keys kill
	fi
    fi
	 cat /etc/ssh/sshd_config | grep -e "^AuthorizedKeysFile" &> /dev/null
	  if [[ "$?" -eq 0 ]] ; then
	    $m_issue"Someone has defined \e[31m`cat /etc/ssh/sshd_config | grep -e "^AuthorizedKeysFile" | tr -s`\e[0m in /etc/ssh/sshd_config"
	    $m_issue"You want to look into this"
	    sleep 3
	  fi
	  
	if [[ "$ssh_key_action" != b && "$ssh_key_action" != d ]] ; then
	   $m_inform"Bye! "
	fi
	