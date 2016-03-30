#!/bin/bash
#
#################################################################################
#             	     Outhouse shell scripting for sshd management at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[32mCore SSHd\e[0m]"

confirm_single=false
sshd_conf=/etc/ssh/sshd_config
  
function define_allow_users {

   # MY_USERNAME will be defined if passed from base script, otherwise don't auto-set this
   
   if [[ -r $SCRIPT_HOME_INFOS/my_username.txt ]] ; then
	MY_USERNAME=`cat $SCRIPT_HOME_INFOS/my_username.txt`
	$m_inform"Using \e[31m$MY_USERNAME\e[0m as personal sshd account name, as you have already set it's value"
	echo
   else
         if [[ "$MY_USERNAME" != "" && "$MY_USERNAME" != "undef" ]] ; then
	  $m_inform"Using \e[31m$MY_USERNAME\e[0m as personal sshd account name, as you have already set it's value"
	  echo
	 fi
   fi
}

function confirm_single_allow {

	# Confirm rollover to single 'AllowUsers' entry of $MY_USERNAME in sshd_config
	
         if [[ "$MY_USERNAME" != "" && "$MY_USERNAME" != "undef" ]] ; then
          $m_issue"Possibly unsafe modification confirmation:"
          $m_issue"Defining \e[32mAllowUsers $MY_USERNAME\e[0m could lock everyone out of this server if this account is not already setup for authentication"
          echo
	  $m_choose"Should I setup rules where ONLY \e[31m$MY_USERNAME\e[0m will be allowed to SSH into this server? \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
	  read -p "> " -t 60 $confim_unsafe
	    if [[ "$confim_unsafe" == y || "$confim_unsafe" == Y ]] ; then
	      confirm_single=true
	    fi
	 fi
}

function confirm_changes {

  # only called if something has changed, at the close of fix_insecure_settings
  # Backup the original, just in case, force manual config review
  # confirm -> cp -f -> restart sshd
  
  tmp_ssh_conf=$1
  ext=`date +%b_%d_%A_%H%M`
 
  if [[ -d $SCRIPT_HOME_BACKUPS ]] ; then
      if [[ -d $SCRIPT_HOME_BACKUPS/ssh ]] ; then
	cp $sshd_conf $SCRIPT_HOME_BACKUPS/ssh/sshd.conf.orig.$ext.conf
      else
	mkdir $SCRIPT_HOME_BACKUPS/ssh
	cp $sshd_conf $SCRIPT_HOME_BACKUPS/ssh/sshd.conf.orig.$ext.conf
      fi
  $m_inform"Your original SSHd config is being backed up to: \e[2m$SCRIPT_HOME_BACKUPS/ssh/sshd.conf.orig.$ext.conf\e[0m"
  else
    guess_dir=echo `pwd`/..
    $m_issue"The value for \e[2m\$SCRIPT_HOME\e[0m was not passed to this script"
    $m_inform"We'll guesstimate that it is maybe \e[2m$guess_dir\e[0m"
    mkdir ../backups
    mkdir ../backups/ssh
    cp $sshd_conf ../backups/ssh/sshd.conf.orig.$ext.conf
    $m_inform"Your original SSHd config is being backed up to: \e[2m$guess_dir/backups/ssh/sshd.conf.orig.$ext.conf\e[0m"
  fi
  
  $m_inform"Because there are many things that could go wrong, I am going to ask that you to verify the SSHD config script generated"
  $m_inform"Please review it for errors and/or issues"
  echo
  sleep 5
  cat $1 | less
  
  $m_inform"If this looks correct to you, let\'s use it, and also restart the SSH daemon"
  $m_choose"Proceed?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 do_it
      if [[ "$do_it" == y || "$do_it" == Y ]] ; then
      cp -f $1 $sshd_conf
      sleep 1
      which service &> /dev/null
	  if [[ $0 -eq 0 ]] ; then
	      service sshd restart
	  else
	    /etc/rc.d/rc.sshd restart
	    sleep 5
	    /etc/init.d/ssh restart
	  fi
	$m_inform"Service restarted with new .config, this module has completed"
      else
	$m_inform"User declined to use new config and restart SSHD"
	$m_inform"If you decide to use it later, the file is at: $1"
      fi
}    
	  
    
function fix_insecure_settings {
  
  # copy original to temp
  # sed inline editing for crappy settings pre-set / unfuck them
  
  
  ext=`date +%b_%d_%A_%H%M`
  tmp_ssh_conf=/tmp/rapidsshd.$ext.config

  if [[ -r $sshd_conf ]] ; then
      cp $sshd_conf $tmp_ssh_conf
      
      
	$m_inform"Checking for \e[2mSSH v1 protocol\e[0m usage"
	cat $tmp_ssh_conf | grep -e "^Protocol " | grep 1
	if [[ "$?" == 0 ]] ; then
	   sed -i 's/^Protocol .*/Protocol 2/' $tmp_ssh_conf
	   sshd_modified=true
	   $m_inform"SSH rule for \e[31mProtocol\e[0m was modified"
	else
	   $m_inform"Nothing to do for \e[2mProtocol\e[0m, continuing .."
	fi
	
	
	$m_inform"Checking for '\e[2mEmpty Passwords\e[0m' usage"
	cat $tmp_ssh_conf | grep -e "^PermitEmptyPasswords " | grep "yes"
	if [[ "$?" == 0 ]] ; then
	   sed -i 's/^PermitEmptyPasswords .*/PermitEmptyPasswords no/' $tmp_ssh_conf
	   sshd_modified=true
	   $m_inform"SSH rule for \e[31mPermitEmptyPasswords\e[0m was modified"
	else
	   $m_inform"Nothing to do for \e[2mPermit Empty Passwords\e[0m, continuing .."
	fi
		
		
	$m_inform"Checking for '\e[2mGlobal Keyfiles\e[0m' usage"
	cat $tmp_ssh_conf | grep -e "^AuthorizedKeysFile"
	if [[ "$?" == 0 ]] ; then
	   sed -i 's/^AuthorizedKeysFile .*//' $tmp_ssh_conf
	   sshd_modified=true
	   $m_inform"SSH rule for \e[31mAuthorizedKeysFile\e[0m was modified"
	else
	   $m_inform"Nothing to do for \e[2mGlobal Keyfiles\e[0m, continuing .."
	fi
	
	
	$m_inform"Checking for '\e[2mRemote hosts\e[0m' usage"
	cat $tmp_ssh_conf | grep -e "^IgnoreRhosts " | grep "no"
	if [[ "$?" == 0 ]] ; then
	   sed -i 's/^IgnoreRhosts .*/IgnoreRhosts yes/' $tmp_ssh_conf
	   sshd_modified=true
	   $m_inform"SSH rule for \e[31mIgnoreRhosts\e[0m was modified"
	else
	   $m_inform"Nothing to do for \e[2mRemote hosts\e[0m, continuing .."
	fi
	
	
	$m_inform"Checking for '\e[2mRemote hosts RSA\e[0m' usage"
	cat $tmp_ssh_conf | grep -e "^RhostsRSAAuthentication " | grep "yes"
	if [[ "$?" == 0 ]] ; then
	   sed -i 's/^RhostsRSAAuthentication .*/RhostsRSAAuthentication no/' $tmp_ssh_conf
	   sshd_modified=true
	   $m_inform"SSH rule for \e[31mRhostsRSAAuthentication\e[0m was modified"
	else
	   $m_inform"Nothing to do for \e[2mRSA Remote hosts\e[0m, continuing .."
	fi

	
	$m_inform"Checking for '\e[2mX11 Forwarding\e[0m' usage"
	cat $tmp_ssh_conf | grep -e "^X11Forwarding " | grep "yes"
	if [[ "$?" == 0 ]] ; then
	   sed -i 's/^X11Forwarding .*/X11Forwarding no/' $tmp_ssh_conf
	   sshd_modified=true
	   $m_inform"SSH rule for \e[31mX11Forwarding\e[0m was modified"
	else
	   $m_inform"Nothing to do for \e[2mX11 Forwarding\e[0m, continuing .."
	fi

	
	$m_inform"Checking for '\e[2mPermit Root Login\e[0m' usage"
	cat $tmp_ssh_conf | grep -e "^PermitRootLogin " | grep "yes"
	if [[ "$?" == 0 ]] ; then
	   echo
	   $m_inform"Disabling the ability of 'root' to login directly to SSHd is advised"
	   $m_inform"But may break things if you do not have an alternative account to use" 
	   $m_inform"You are currently logged in as `whoami`"
	   echo
	   $m_choose"Should I disable direct SSH logins by \e[31m$root\e[0m to this server? \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
	      read -p "> " -t 60 disable_ssh_as_root
	      	if [[ "$disable_ssh_as_root" == y || "$disable_ssh_as_root" == Y ]] ; then
		    sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' $tmp_ssh_conf
		    sshd_modified=true
		    $m_inform"SSH rule for \e[31mPermitRootLogin\e[0m was modified"
		fi
	   $m_inform"User opted out of mofiying SSH rule for \e[2mPermitRootLogin\e[0m"
	else
	   $m_inform"Nothing to do for \e[2mPermit Root Login\e[0m, continuing .."
	fi

	
	$m_inform"Checking for '\e[2mSingle user SSH\e[0m' preference"	  
	if [[ "$confirm_single" == true ]] ; then
	   echo
	   $m_inform"If you enable this rule, \e[32m$MY_USERNAME\e[0m will be the only user who can ssh in"
	   echo
	   $m_choose"Are you absolutely certain that is what you want? \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
	      read -p "> " -t 60 i_know_the_risks
	      	if [[ "$i_know_the_risks" == y || "$i_know_the_risks" == Y ]] ; then		  
		    sed -i '/^AllowUsers .*/ d' $tmp_ssh_conf
		    sed -i '/^DenyUsers .*/ d' $tmp_ssh_conf
		    echo "AllowUsers $MY_USERNAME" >> $tmp_ssh_conf
		    sshd_modified=true
		    $m_inform"SSH rule for \e[31mAllowUsers\e[0m was modified"
		    $m_inform"Only \e[32m$MY_USERNAME\e[0m will be allowed to login"
		else
		  $m_inform"User opted out of mofiying SSH rule for \e[2mAllowUsers\e[0m, finished generating sshd config"
		fi
	else
	   $m_inform"Nothing to do for \e[2mSingle User Restricted\e[0m Login, finished generating sshd config"
	fi

	
  echo
  if [[ $sshd_modified == true ]] ; then
    confirm_changes $tmp_ssh_conf
  else
    $m_inform"No changes to your \e[34m$sshd_conf\e[0m file are required, exiting"
  fi
  
}

  define_allow_users
  confirm_single_allow
  fix_insecure_settings
  
 