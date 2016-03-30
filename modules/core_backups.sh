#!/bin/bash
#
#################################################################################
#                        Outhouse shell scripting for auto-backup at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
#################################################################################
#

m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[32mCore Backups\e[0m]"

  if [[ -d "$SCRIPT_HOME_BACKUPS" ]] ; then
    sleep 1
  else
      if [[ $SCRIPT_HOME_BACKUPS == "" || $SCRIPT_HOME_BACKUPS == undef ]] ; then
	guess_dir=`pwd`/../backups
	$m_issue"The value for \e[2m\$SCRIPT_HOME_BACKUPS\e[0m was not passed to this script"
	$m_inform"We'll guesstimate that it is maybe \e[2m$guess_dir\e[0m"
	SCRIPT_HOME_BACKUPS=$guess_dir
      fi
    mkdir $SCRIPT_HOME_BACKUPS
  fi
  
function process_args {

    dir=$1
    prune=`echo $1 | tr -d "*"`
    backup_fol=`basename $prune`
    section_name=`echo $prune | tr [:punct:] "."`
    ext=`date +%b_%d_%A_%H%M`
    
  if [[ -d "$SCRIPT_HOME_BACKUPS/$backup_fol" ]] ; then
      sleep 1
    else
      mkdir $SCRIPT_HOME_BACKUPS/$backup_fol
  fi
  
    raw_size=`du -hm --max-depth=0 $prune | cut -f 1`
    if [[ $raw_size == 0 ]] ; then
	comp_size=no
      else
	let size_in_mb=$((raw_size))
	let comp_size=$((size_in_mb/2))
    fi
  
    if [[ "$1" != "/" && "$1" != "*" ]] ; then
      $m_inform"Section \e[35m$prune\e[0m uses \e[33m$raw_size\e[0m MB of space, it may take \e[33m$comp_size\e[0m MB to back it up .."
      sleep 3
      tar_file=$SCRIPT_HOME_BACKUPS/$backup_fol/rapidbackup.$section_name.$ext.tar.gz
      nice tar -zcvf $tar_file $1
      $m_inform"Created \e[36m`basename $tar_file`\e[0m backing up: \e[35m$prune\e[0m"
      $m_inform"Should you need it, look in: \e[38m$SCRIPT_HOME_BACKUPS/$backup_fol\e[0m"
      sleep 2
    else
      $m_issue"This script was invoked to backup: \e[31m$1\e[0m "
      $m_issue"This is likely a typo, .. ignoring request"
      echo
    fi
  
}


if [[ "$1" == new ]] ; then
  # new, back it all up
  
  bfiles="/etc/shadow /etc/group /etc/passwd /etc/sudoers"
  for has_f in $bfiles ; do
    if [[ -f $has_f ]] ; then
      process_args $has_f
    fi
  done
  
  bdirs="/etc/init /etc/ssh /etc/apache2 /etc/phpmyadmin /etc/apparmor /etc/network /etc/mysql /etc/postgresql /var/www "
  for has_d in $bdirs ; do
    if [[ -d $has_d ]] ; then
      process_args $has_d
    fi
  done
  
fi
 
if [[ "$1" != new ]] ; then
  $m_inform"No pre-defined rule to operate on: \e[33m$1\e[0m, but we'll try it anyway .."
  echo
  process_args "$1"
fi
      
