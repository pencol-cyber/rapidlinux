#!/bin/bash
#
#################################################################################
#             Outhouse shell scripting for bulk account managment at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[95m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[96m=\e[0m\e[2m]\e[0m "

if [[ "$#" -lt 1 ]] ; then
  $m_issue"This script requires \e[31mone\e[0m input parameter(s) be passed to it:"
  $m_issue"\$1 - [\e[2mnew\e[0m|\e[2mmodify\e[0m] create or modify mode"
  $m_inform"\$2 - [\e[2mskip_create\e[0m]  optional parameter: do not create new account"
  echo
  $m_inform"Example -\e[32m core_accounts.sh \e[0mmodify"
  exit 1
fi

script_mode=$1
user_array=()
disable_array=()
let user_count=0
users=`cat /etc/passwd | cut -f 1 -d ":"`

if [[ "$SCRIPT_HOME_INFOS" != "" ]] ; then
    echo "$users" > $SCRIPT_HOME_INFOS/userlist.txt
fi
    

function set_my_acct {

   # if personal account name is unique (not empty/undef) use it and export the value
   # if not, ask if you want to set it now

   if [[ -r $SCRIPT_HOME_INFOS/my_username.txt ]] ; then
	MY_USERNAME=`cat $SCRIPT_HOME_INFOS/my_username.txt`
	$m_inform"Using \e[31m$MY_USERNAME\e[0m as personal account name, as you have already set it's value"
	echo
   else
         if [[ "$MY_USERNAME" != "" && "$MY_USERNAME" != "undef" ]] ; then
	  $m_inform"Using \e[31m$MY_USERNAME\e[0m as personal account name, as you have already set it's value"
	  echo
	 fi
   fi
   
  if [[ "$MY_USERNAME" == "" || "$MY_USERNAME" == "undef" ]] ; then
   $m_inform"You don't seem to have a personal account set"
   $m_choose"Should we setup one up now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
   read -p "> " -t 60 create_my_acct
      if [[ "$create_my_acct" == y || "$create_my_acct" == Y ]] ; then
	    echo
	    $m_choose"What should we name your account? "
	    read -p "> " -t 60 name_my_acct
	      reserved="root admin bin mysql postgres mail shutdown adm sshd http httpd apache nobody"
	      for acct_name in $reserved ; do
		  if [[ $acct_name == $name_my_acct ]] ; then
		      while [[ $acct_name == $name_my_acct ]] ; do
			$m_issue"You seem to have chosen the reserved account name \e[31m$name_my_acct\e[0m"
			$m_issue"Lets try this again, shall we .."
			echo
			sleep 5
			$m_choose"What should we name your account? "
			read -p "> " -t 60 name_my_acct
		      done    
		  else
		      export MY_USERNAME=$name_my_acct
			if [[ "$SCRIPT_HOME_INFOS" != "" ]] ; then
			    echo "$MY_USERNAME" > $SCRIPT_HOME_INFOS/my_username.txt
			fi
		  fi
	      done
      fi
   fi
}

function set_scoring_acct {

   # if white_team account is unique (not empty/undef) use it and export the value
   # if not, ask if you want to set it now

   if [[ -r $SCRIPT_HOME_INFOS/whiteteam_account.txt ]] ; then
	SUPPORT_ACCOUNT=`cat $SCRIPT_HOME_INFOS/whiteteam_account.txt`
	$m_inform"Using \e[31m$S\e[0m as white team account name, as you have already set it's value"
	echo
   else
      if [[ "$SUPPORT_ACCOUNT" != "" && "$SUPPORT_ACCOUNT" != "undef" ]] ; then
	  $m_inform"Using \e[31m$S\e[0m as white team account name, as you have already set it's value"
	  echo
      fi
   fi
   
    if [[ "$SUPPORT_ACCOUNT" == "" || "$SUPPORT_ACCOUNT" == "undef" ]] ; then
    $m_inform"Previously defined value for \e[31mWhite Team Account\e[0m not found"
    echo
    $m_choose"Do you have a white team account that you are required to support?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 create_white_acct
    
      if [[ "$create_white_acct" == y || "$create_white_acct" == Y ]] ; then
	    echo
	    $m_choose"What is the name of this account? "
	    read -p "> " -t 60 name_white_acct
	    
	      for acct_name in $users ; do
		  if [[ $acct_name == $name_white_acct ]] ; then
		      $m_inform"account \e[31m$name_white_acct\e[0m exists, and is valid"
		      export SUPPORT_ACCOUNT=$name_white_acct
		      	if [[ "$SCRIPT_HOME_INFOS" != "" ]] ; then
			    echo "$SUPPORT_ACCOUNT" > $SCRIPT_HOME_INFOS/whiteteam_account.txt
			fi
		  fi
	      done
      fi
    fi
}

function user_finder {

  for user in $users ; do
  
	# reiterate through, only grabbing hashes this time
	# strnlen them for lockedout/null/noauth

	userhash=`cat /etc/shadow | grep -e ^$user: | cut -f 2 -d ":"`
	hashlen=$(echo "$userhash"| tr -d "\n" | wc -m)


	if [[ "$hashlen" -le 1 ]] ; then
		# 1 or 0 chars in pwd hash? Handle these cases here
		# echo hash is short

		if [[ "$userhash" == "" ]] ; then
			usershell=`cat /etc/passwd | grep -e ^$user: | cut -f 7 -d ":"`
			userhome=`cat /etc/passwd | grep -e ^$user: | cut -f 6 -d ":"`
			$m_inform"Processing active user \e[34m`printf %16s $user`\e[0m using shell \e[35m`printf %16s $usershell`\e[0m and home directory \e[35m$userhome\e[0m"
			$m_issue"Found a \e[31mNULL Password\e[0m for \e[32m$user\e[0m ... this a major security concern"
			$m_issue""
			user_array+=("$user")
			let user_count=$((++user_count))
  		fi

 
		if [[ "$userhash" == "*" ]] ; then
			$m_inform"not processing \e[37m`printf %16s $user`\e[0m , who cannot auth against: \e[37m$userhash\e[0m"
		fi


		if [[ "$userhash" == "!" ]] ; then 
			$m_inform"not processing \e[37m`printf %16s $user`\e[0m , who is currently locked out by: \e[37m$userhash\e[0m"
                fi
	
	else
		# Seems legit, add this account to the user list array
		# we are going to operate on
		# and keep running tally for comparison verification
		
		usershell=`cat /etc/passwd | grep -e ^$user: | cut -f 7 -d ":"`
		userhome=`cat /etc/passwd | grep -e ^$user: | cut -f 6 -d ":"`
		$m_inform"Processing active user \e[34m`printf %16s $user`\e[0m using shell \e[35m`printf %16s $usershell`\e[0m and home directory \e[35m$userhome\e[0m"
		user_array+=("$user")
		let user_count=$((++user_count))	
	fi	
  done
  $m_inform"function returns \e[35m$user_count\e[0m active accounts"
}

function set_pass_new {

    # Prompt for new password
    # import ${user_array[@]} of active accounts
    # iterate through with catches for `whoami`, $SUPPORT_ACCOUNT, $MY_USERNAME
    # then change their fuckin passwords
    me=`whoami`
    
    $m_inform"Let's choose a new password for these users now"
    echo
    $m_choose"New password"
    read -p "> " -t 90 new_pass
    $m_choose"Please confirm the password"
    read -p "> " -t 90 confirm_pass
	while [[ "$new_pass" != "$confirm_pass" ]] ; do
	  $m_issue"Passwords did not match"
	  echo
	  $m_inform"Let\'s try that again"
	  echo 
	  sleep 5
	  $m_choose"New password"
	  read -p "> " -t 90 new_pass
	  $m_choose"Please confirm the password"
	  read -p "> " -t 90 confirm_pass
	 done
	 
       if [[ "$new_pass" == "$confirm_pass" ]] ; then
	  $m_inform"New Password \e[32m$confirm_pass\e[0m will be used"
	else
	  $m_issue"An unanticipated error has occured, exiting"
	  exit 1
       fi

       num_changed=${#user_array[@]}
       
	  for chpass_user in "${user_array[@]}" ; do
            
            case $chpass_user in
            
		  $me)
		    $m_inform"Skipping user \e[32m$me\e[0m as it has already been changed"
		    let num_changed=$((--num_changed))
		  ;;
		    *)
		    $m_inform" .. changing password for user e[32m$chpass_user\e[0m"
		    echo $chpass_user:$confirm_pass | chpasswd xargs
		    if [ $? -eq 0 ]] ; then
		      $m_inform"returned status code \e[34mSuccess\e[0m"
		    else
		      $m_issue"pipeline returned a failure code \e[31mNot Success\e[0m"
		    fi
	    esac
	  done

	$m_inform"Password changes completed for \e[34m$num_changed\e[0m users"
}


function update_support_pass {

    # if isdef $SUPPORT_ACCOUNT (whiteteam) , offer to set a new unique pwd to overwrite
    # the generic one given during bluk password changes

   if [[ "$SUPPORT_ACCOUNT" != "" && "$SUPPORT_ACCOUNT" != "undef" ]] ; then
      $m_choose"Would you like to set a unique password for the white team account \e[33m$SUPPORT_ACCOUNT\e[0m now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
      read -p "> " -t 60 reset_support_pwd
      
	  if [[ "$reset_support_pwd" == y || "$reset_support_pwd" == Y ]] ; then
	     $m_inform"Let's choose a new password for these users now"
	      echo
	      $m_choose"New password"
	      read -p "> " -t 90 new_sup_pass
	      $m_choose"Please confirm the password"
		read -p "> " -t 90 confirm_sup_pass
		
		  while [[ "$new_sup_pass" != "$confirm_sup_pass" ]] ; do
		    $m_issue"Passwords did not match"
		    echo
		    $m_inform"Let\'s try that again"
		    echo 
		    sleep 5
		    $m_choose"New password"
		    read -p "> " -t 90 new_sup_pass
		    $m_choose"Please confirm the password"
		    read -p "> " -t 90 confirm_sup_pass
		  done
		
		if [[ "$new_sup_pass" == "$confirm_sup_pass" ]] ; then
		    $m_inform"New Password \e[32m$confirm_pass\e[0m will be used"
		else
		    $m_issue"An unanticipated error has occured, exiting"
		    exit 1
		fi
		
		$m_inform" .. changing password for user e[32m$SUPPORT_ACCOUNT\e[0m"
		echo $SUPPORT_ACCOUNT:$confirm_sup_pass | chpasswd xargs
		   if [ $? -eq 0 ]] ; then
		      $m_inform"returned status code \e[34mSuccess\e[0m"
		      echo
		      $m_inform"Remember to convey this password change to the scoring engine"
		   else
		      $m_issue"pipeline returned a failure code \e[31mNot Success\e[0m"
		   fi
}
	  

function disable_superflous_users {

    # Pull our userlist array back in and offer to lock out any accounts that are not:
    #   1) me (whoami)
    #   2) defined personal account ($MY_USERNAME)
    #	3) white team ($SUPPORT_ACCOUNT)
    
    disable_array=${user_array[@]}
    me=`whoami`
    disable_array=( "${disable_array[@]/$me}" )
    
    if [[ "$MY_USERNAME" != "" && "$MY_USERNAME" != "undef" ]] ; then
      disable_array=( "${disable_array[@]/$MY_USERNAME}" )
    fi
    
    if [[ "$SUPPORT_ACCOUNT" != "" && "$SUPPORT_ACCOUNT" != "undef" ]] ; then
      disable_array=( "${disable_array[@]/$SUPPORT_ACCOUNT}" )
    fi
    
    $m_inform"This script has identified the following accounts as possible candidates for lockout"
    $m_inform"This also prevents SSH based logins by using enforced expiry dates"
    for to_disable in ${disable_array[@]} ; do
	usershell=`cat /etc/passwd | grep -e ^$to_disable: | cut -f 7 -d ":"`
	userhome=`cat /etc/passwd | grep -e ^$to_disable: | cut -f 6 -d ":"`
	$m_inform"User \e[34m`printf %16s $to_disable`\e[0m using shell \e[35m`printf %16s $usershell`\e[0m and home directory \e[35m$userhome\e[0m"
    done
    
    echo
    $m_choose"Shall I lock them out now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 do_lockouts
    	  if [[ "$do_lockouts" == y || "$do_lockouts" == Y ]] ; then
	     for to_disable in ${disable_array[@]} ; do
		  $m_inform"Setting \e[32m$to_disable\e[0m account as expired + locked out"
		  usermod -L -e"1999-12-31" -c"Locked out by rapidlinux" -s"/bin/false" $to_disable
	     done
	   $m_inform"${#disable_array[@]} accounts were locked out"     
	  fi
	  
}
    
    
if [[ "$1" = new ]] ; then
    $m_inform"Now operating with \e[33m$1\e[0m account managment logic chain"
    echo
    $m_inform"First, .. let's change your current password"
    passwd
    echo
    set_my_acct
    set_scoring_acct
    user_finder
      #returns ${user_array[@]}
    set_pass_new
    update_support_pass
    disable_superflous_users
fi

if [[ "$1" = modify ]] ; then
    # maybe i'll do this later
    $m_inform"The lazy script author forgot to write anything for this section"
fi
