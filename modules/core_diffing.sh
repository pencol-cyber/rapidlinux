#!/bin/bash
#
#################################################################################
#             		Outhouse shell scripting for file diffing at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
#
#delete this next line before going live
#SCRIPT_HOME=/home/r0tten

m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[32mCore Differential\e[0m]"
dont_descend=false

if [[ $SCRIPT_HOME_BACKUPS == "" || $SCRIPT_HOME_BACKUPS == undef ]] ; then
  backup_dir=/root/backups
  else
  backup_dir=$SCRIPT_HOME_BACKUPS
fi

if [[ -r $backup_dir/db.txt ]] ; then
  $m_inform"Sections you have already computed the differentials for"
  cat $backup_dir/db.txt
  echo 
fi

if [[ "$#" -lt 3 ]] ; then
  $m_issue"This script requires \e[31mthree\e[0m input parameters be passed to it:"
  $m_issue"\$1 - [\e[2mnew\e[0m|\e[2mcompare\e[0m] create or compare mode"
  $m_issue"\$2 - [\e[2m/var/www\e[0m]    section of filesystem to create or compare"
  $m_issue"\$3 - [\e[2mweb\e[0m]         short name describing filesystem diff db to use or create"
  $m_inform"\$4 - [\e[2mno_descend\e[0m]  optional parameter: do not descend into sub directories"
  echo
  $m_inform"Example -\e[32m core_diffing \e[0mnew /var/www/html web"
  exit 1
fi


# assign input 'mode'
param1=$1
# assign input '/example/dir'
param2=$2
# assign input cannocal name 'example'
param3=$3
# optional param4 - no_descend
if [[ "$4" == "no_descend" ]] ; then
  dont_descend=true
fi

function do_new_hashing() {

    # This is quite possibly the most in-elegant function you've ever seen
    # I looked for the opposing force to `basename` but couldn't find it
    # ... interates making long timestamp + filesize combos for quick & dirty
    # change detection
    # [requires params] $1r filesystem, $2r name
    # if param4 is passed, only operates on base directory and contents

  if [[ "$#" -ne 2 ]] ; then
    echo "An error occurred: not enough parameters supplied"
  fi

  section_root=$1
  backup_short=$2

  ls -lad --full-time $section_root/* > $backup_dir/$backup_short/diffing_orig.txt
  $m_inform"Creating diff for source ... \e[2m$section_root/\e[0m"

  if [[ $dont_descend == false ]] ; then
	
    for dirs in `ls -ad $section_root/*` ; do 
      if [ -d $dirs ] ; then
	$m_inform"Adding   diff for source ... \e[2m$dirs \e[0m"
	ls -lad --full-time $dirs/* >> $backup_dir/$backup_short/diffing_orig.txt
	  for sub_dirs in `ls -ad $dirs/*` ; do
	    if [ -d $sub_dirs ] ; then
	      $m_inform"Adding   diff for source ... \e[2m$sub_dirs \e[0m"
	      ls -lad --full-time $sub_dirs/* >> $backup_dir/$backup_short/diffing_orig.txt
		for nested_dirs in `ls -ad $sub_dirs/*` ; do
	    	    if [ -d $nested_dirs ] ; then
		      $m_inform"Adding   diff for source ... \e[2m$nested_dirs \e[0m"
		      ls -lad --full-time $nested_dirs/* >> $backup_dir/$backup_short/diffing_orig.txt
			for fourth_dirs in `ls -ad $nested_dirs/*` ; do
			  if [ -d $fourth_dirs ] ; then
			    $m_inform"Adding   diff for source ... \e[2m$fourth_dirs \e[0m"
			    ls -lad --full-time $fourth_dirs/* >> $backup_dir/$backup_short/diffing_orig.txt
			      for fifth_dirs in `ls -ad $fourth_dirs/*` ; do
				if [ -d $fifth_dirs ] ; then
				  $m_inform"Adding   diff for source ... \e[2m$fifth_dirs \e[0m"
				  ls -lad --full-time $fifth_dirs/* >> $backup_dir/$backup_short/diffing_orig.txt
				fi
			      done
			  fi
			done
		    fi
		done
	    fi
	  done
      fi
    done
  else
    $m_inform"Not descending into subdirs for \e[2m$section_root/\e[0m"
  fi

  $m_inform"Section \e[32m$backup_short\e[0m creation has finished"

  if [[ $dont_descend == true ]] ; then
    extra="\e[2m-no_subdirs\e[0m"
  fi
  echo -e "\e[2m`date`:\e[0m added \e[35m`printf %14s $section_root`\e[0m described by \e[32m$backup_short\e[0m $extra" >> $backup_dir/db.txt
  
}


function gen_hash_diff() {

    # Compares previously made hashes
    # [requires params] $1r filesystem, $2r name
    
  if [[ "$#" -ne 2 ]] ; then
    echo "An error occurred: not enough parameters supplied"
  fi

  section_root=$1
  tmpfile=$2

  ls -lad --full-time $section_root/* > $tmpfile

  if [[ $dont_descend == false ]] ; then
  
    for dirs in `ls -ad $section_root/*` ; do
      if [ -d $dirs ] ; then
	  ls -lad --full-time $dirs/* >> $tmpfile
	    for sub_dirs in `ls -ad $dirs/*` ; do
	      if [ -d $sub_dirs ] ; then
		ls -lad --full-time $sub_dirs/* >> $tmpfile
		  for nested_dirs in `ls -ad $sub_dirs/*` ; do
		      if [ -d $nested_dirs ] ; then
			ls -lad --full-time $nested_dirs/* >> $tmpfile
			  for fourth_dirs in `ls -ad $nested_dirs/*` ; do
			    if [ -d $fourth_dirs ] ; then
			      ls -lad --full-time $fourth_dirs/* >> $tmpfile
				for fifth_dirs in `ls -ad $fourth_dirs/*` ; do
				  if [ -d $fifth_dirs ] ; then
				    ls -lad --full-time $fifth_dirs/* >> $tmpfile
				  fi
				done
			    fi
			done
		      fi
		  done
	      fi
	  done
      fi
    done
  
  else
    $m_inform"Not descending into subdirs for \e[2m$section_root/\e[0m"
 fi
}

function create_backup_dir() {

newdir=$1

      if [[ -d "$backup_dir" ]] ; then
	$m_inform"\e[2m$backup_dir\e[0m already exists"
      else
	$m_inform"Initializing \e[32m$backup_dir\e[0m .. This is where are your differentials will be placed"
	mkdir $backup_dir
      fi
      
      if [[ -d "$backup_dir/$newdir" ]] ; then
	$m_inform"\e[2m$backup_dir/$newdir\e[0m already exists"
      else
	$m_inform"Creating     \e[32m$backup_dir/$newdir\e[0m"
	mkdir $backup_dir/$newdir
      fi
}

### Inoked as 'new' - make the orig diffs

if [[ "$param1" = new ]] ; then
    $m_inform"Now operating with logic for \e[33m$1\e[0m on filesytem \e[2m$2\e[0m described by \e[32m`basename $backup_dir/$3`\e[0m \e[2m$4\e[0m"
    echo
    sleep 2
    create_backup_dir $param3
    do_new_hashing $param2 $param3
fi

### Invoked as 'compare' recheck, and compare

if [[ "$param1" = compare ]] ; then
    $m_inform"Now operating with logic for \e[34m$1\e[0m on filesytem \e[2m$2\e[0m described by \e[32m`basename $backup_dir/$3`\e[0m \e[2m$4\e[0m"
    echo
    sleep 2
    comptime=`date +%b_%d_%A_%H%M`
    compare_file=/tmp/rapidlinux.diff."$param3"."$comptime".txt
    gen_hash_diff $param2 $compare_file
    diff $backup_dir/$param3/diffing_orig.txt $compare_file &> /dev/null
    if [[ $? -eq 0 ]] ; then
	$m_inform"diff returned status value: \e[34m$?\e[0m : No modifications have been detected for \e[32m$3\e[0m"
      else
	$m_issue"diff returned status value: \e[31m$?\e[0m : modifications have been detected for \e[32m$3\e[0m"
	echo
	$m_choose"Would you like to examine the changes?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
	read -p "> " -t 60 examine_diff
	    if [[ "$examine_diff" == y || "$examine_diff" == Y ]] ; then
		diff $backup_dir/$param3/diffing_orig.txt $compare_file | less
	    fi
     fi
fi


    