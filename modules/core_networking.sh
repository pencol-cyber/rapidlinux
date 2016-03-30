#!/bin/bash
#
#################################################################################
#             Outhouse shell scripting for bulk account managment at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[32mCore Networking\e[0m]"

    # hopes to recieve the following args:
    # $1r [new|add]
    # $2o [ service rule ]
    # $3o [ 'IPv4 address user connects to this server from' ]

declare -a ipv4_addr_array

  
 
function collect_netinfo {
  # thanks to awesome freenode slackers who helped me with this regex, you rock
  
  eth_addrs=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]{1,3}' | grep -v "127.0.0.1" | grep -Eo '([0-9]*\.){3}[0-9]*'`
  
  for ips in $eth_addrs ; do
    ipv4_addr_array+=("$ips")
  done

  for ips in "${ipv4_addr_array[@]}" ; do
    $m_inform"I have an ipv4 address of: \e[35m$ips\e[0m"
  done
  
      ip4_count=${#ipv4_addr_array[@]}
      $m_inform"for a total of $ip4_count ipv4 address(es)"
      echo
}


function determine_sshuser_ip {
  # fuck this is ugly, but needed to work on various linuxes
  # only called by socket_assign should better methods fail
    
    for ips in "${ipv4_addr_array[@]}" ; do
      my_socket=`netstat -tnp -4 | grep $ips:22 | grep "sshd" | cut -f 2 -d ":" | sed s"/^22 //"g | tr -d " "`
    done
    
    #     me=`whoami`  
    # this is better , but doesn't handle su/sudo situtations
    #my_socket=`netstat -tnp -4 | grep $me | grep $ips:22 | grep "sshd" | cut -f 2 -d ":" | sed s"/^22 //"g | tr -d " "`
    
    if [[ $my_socket != "" && $my_socket != "127.0.0.1" ]] ; then
      
      $m_inform"Your socket origin appears to be \e[33m$my_socket\e[0m"
      echo
    else
      $m_issue"Unable to determine socket (\e[2mperhaps you are not using one?\e[0m)"
      $m_issue"No backup handler available at this time"
      $m_issue"Manually specify something like \e[31m\$MY_IPV4=\e[0m\e[2m192.168.10.1\e[0m and try re-running the script"
      sleep 4
      # fix this before going live
      # exit 1
    fi
}
 

function ipv4_assign {
    # time to make assignments

    if [[ $BOX_IPV4 == "" || $BOX_IPV4 == undef ]] ; then
      $m_inform"BOX_IPV4 argument not explicitly passed to script"
      
	for ips in "${ipv4_addr_array[@]}" ; do
	  $m_inform".. assuming usage of: \e[35m$ips\e[0m"
	  echo
	done
      
    else
      $m_inform"Using \e[35m$BOX_IPV4\e[0m as your supported IPv4 address"
      ipv4_addr_array=("$BOX_IPV4")
      echo
    fi
}


function socket_assign {
    # this really is a busted way to do this

    if [[ $MY_IPV4 == "" || $MY_IPV4 == undef ]] ; then
      $m_inform"MY_IPV4 argument not explicitly passed to script"
	determine_sshuser_ip
	$m_inform".. assuming usage of: \e[33m$my_socket\e[0m"
    else
      $m_inform"Using \e[33m$MY_IPV4\e[0m as your supported IPv4 address"
      my_socket=$MY_IPV4
    fi
}  

function backup_firewall {
    # iptables-save, in all it's glory
  
    ext=`date +%b_%d_%A_%H%M`
    
     if [[ -d $SCRIPT_HOME_BACKUPS ]] ; then
	if [[ -d $SCRIPT_HOME_BACKUPS/firewall ]] ; then
	  iptables-save > $SCRIPT_HOME_BACKUPS/firewall/rapidnet.orig.firewall.$ext.iptables
	else
	  mkdir $SCRIPT_HOME_BACKUPS/firewall
	  iptables-save > $SCRIPT_HOME_BACKUPS/firewall/rapidnet.orig.firewall.$ext.iptables
	fi
	$m_inform"Your original firewall is now backed up to: \e[2m$SCRIPT_HOME_BACKUPS/firewall/rapidnet.orig.firewall.$ext.iptables\e[0m"
      else
	guess_dir=echo `pwd`/..
	$m_issue"The value for \e[2m\$SCRIPT_HOME\e[0m was not passed to this script"
	$m_inform"We'll guesstimate that it is maybe \e[2m$guess_dir\e[0m"
	mkdir ../backups
	mkdir ../backups/firewall
	iptables-save > ../backups/firewall/rapidnet.orig.firewall.$ext.iptables
	$m_inform"Your original firewall is now backed up to: \e[2m$guess_dir/backups/firewall/rapidnet.orig.firewall.$ext.iptables\e[0m"
     fi

    echo
    sleep 2    
}

function flush_firewall {
	
	# currently only called by confirm_new_firewall
	
	$m_inform"Flushing current firewall policies .."
	iptables -F
	$m_inform"Flushing NAT .."
	iptables -F -t nat
	iptables -Z
	sleep 1
	echo
}

function new_firewall {

	# currently only called from within confirm_new_firewall
	
	$m_inform"Setting \e[2mESTABLISHED\e[0m rules"
	iptables -A INPUT -p all -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A INPUT -i lo -j ACCEPT
	if [[ $my_socket != "" && $my_socket != undef ]] ; then
	  $m_inform"Setting firewall allow \e[34mall\e[0m from $my_socket/32 rule"
	  iptables -A INPUT -p all --source $my_socket/32 -j ACCEPT
	else
	  $m_inform"Setting firewall \e[34mallow all\e[0m to \e[32mSSH\e[0m port 22 rule"
	  iptables -A INPUT -p tcp -m tcp -m state --state NEW --dport 22 -j ACCEPT
	fi
	
}

function firewall_failsafe {

	echo "sleep 300" > /tmp/ipt_failsafe.sh
	echo "iptables -F" >> /tmp/ipt_failsafe.sh
	chmod 700 /tmp/ipt_failsafe.sh
	nohup /tmp/ipt_failsafe.sh &
	$m_inform"In case something goes wrong, I have setup a \e[32mfailsafe\e[0m"
	$m_inform"The script \e[36m/tmp/ipt_failsafe.sh\e[0m will kick in after \e[34m5\e[0m minutes to reset everything"
	$m_inform".. just in case you are unable to continue to continue responding to these dialogs"
	echo
	sleep 3
}

function set_drop_policy {

	 iptables -P INPUT DROP
	 $m_inform"Setting firewall default policy to: \e[36mDROP\e[0m"
}

function kill_failsafe {
	
	 $m_inform"If you can read this, it is now \e[32msafe\e[0m to kill the failsafe feature"
	 echo
	 $m_choose"Should we kill the failsafe now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
	  read -p "> " -t 90 kill_emergency
	  
	    if [[ "$kill_emergency" == y || "$kill_emergency" == Y ]] ; then
	      echo
	      $m_inform" .. attempting to \e[2mkill failsafe\e[0m"
	      failsafe_pid=`ps a | grep ipt_failsafe.sh | grep -v grep | cut -c 1-5 | tr -d " "`
	      $m_inform".. located failsafe module in PID: \e[36m$failsafe_pid\e[0m"
	      $m_inform".. sending \e[36mSIGTERM\e[0m to PID: \e[36m$failsafe_pid\e[0m"
	      kill $failsafe_pid &> /dev/null
	      sleep 2
	      $m_inform".. sending \e[31mSIGKILL\e[0m to PID: \e[36m$failsafe_pid\e[0m"
	      kill -9 $failsafe_pid &> /dev/null
	      sleep 5
	      ps a | grep "ipt_failsafe.sh" | grep -v grep &> /dev/null
	      if [[ $? -eq 1 ]] ; then
		  $m_inform"Failsafe has been succesfully \e[32mde-activated\e[0m"
	      else
		  $m_issue"\e[31mSomething went wrong\e[0m, .. uh oh!"
	      fi
	    rm /tmp/ipt_failsafe.sh
	    fi
}

function display_finished {
  
	echo
	$m_inform"I have completed the firewall setup"
	$m_inform"Please review it for errors"
	iptables -L -n -v
	sleep 5
	echo
	$m_inform"Networking and firewall module has finished"
}
	
function show_current_firewall {

	$m_inform"Displaying current \e[32mfirewall\e[0m .."
	iptables -L -n -v
	$m_inform"Displaying current \e[35mNAT tables\e[0m .."
	iptables -t nat -L -n -v
	sleep 3

}


function confirm_new_firewall {

	$m_inform"The assumptions is that the firewall I just showed you sucks"
	echo
	$m_inform"However, if it is what you'd rather use right now"
	$m_inform"You can keep it by declining the next choice"
	echo
	$m_choose"Should we setup a new firewall now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
	  read -p "> " -t 60 invoke_new_fw
	    if [[ "$invoke_new_fw" == y || "$invoke_new_fw" == Y ]] ; then
	      echo
	      $m_inform"User accepted construction of \e[32mnew firewall\e[0m .."
	      do_new_firewall=true
	      flush_firewall
	      new_firewall
	      firewall_failsafe
	      set_drop_policy
	      kill_failsafe
	      display_finished
	   else
	     $m_inform"User decided to \e[2mkeep existing firewall\e[0m rules in place" 
	   fi
}
	   
	   
if [[ "$1" == new ]] ; then

  # new invocation, so do it all
  
  collect_netinfo
  ipv4_assign
  socket_assign
  backup_firewall
  show_current_firewall
  confirm_new_firewall
  
fi


if [[ "$1" == add ]] ; then

      if [[ "$3" == "" || "$3" == undef ]] ; then
    
	case $2 in
      
	  mysql)
	      iptables -A INPUT -m tcp -p tcp -m state --state NEW --dport 3306 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow all\e[0m to \e[32mMySQL\e[0m port 3306 rule"
	      ;;	      
	  http)
	      iptables -A INPUT -m tcp -p tcp -m state --state NEW --dport 80 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow all\e[0m to \e[32mHTTP\e[0m port 80 rule"
	      ;;
	  smtp)
	      iptables -A INPUT -m tcp -p tcp -m state --state NEW --dport 25 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow all\e[0m to \e[32mSMTP\e[0m port 25 rule"
	      ;;
	  https)
	      iptables -A INPUT -m tcp -p tcp -m state --state NEW --dport 443 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow all\e[0m to \e[32mHTTPS\e[0m port 443 rule"
	      ;;
	      
	      *)
	      $m_inform"I do not have any predefined rules to \e[2madd $2\e[0m"
	  esac
	  
      fi
      
      if [[ "$3" != "" && "$3" != undef ]] ; then
	  # debug, wtf doober
	  # echo reached here
	  echo $3 | grep -Eo '([0-9]*\.){3}[0-9]{1,3}' | grep -v 127.0.0.1 &> /dev/null
	    if [[ $? -eq 0 ]] ; then
	      new_src="$3"/32
	      # echo $new_src
	    else
	      m_issue"the parameter \e[2m$3\e[0m was passed incorrectly, or is not formatted as an IPv4 address"
	      exit 1
	    fi
	  
	  case $2 in
      
	  mysql)
	      iptables -A INPUT -m tcp -p tcp -m state --source $new_src --state NEW --dport 3306 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow $3\e[0m to \e[32mMySQL\e[0m port 3306 rule"
	      ;;
	  http)
	      iptables -A INPUT -m tcp -p tcp -m state --source $new_src --state NEW --dport 80 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow $3\e[0m to \e[32mHTTP\e[0m port 80 rule"
	      ;;
	  smtp)
	      iptables -A INPUT -m tcp -p tcp -m state --source $new_src --state NEW --dport 25 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow $3\e[0m to \e[32mSMTP\e[0m port 25 rule"
	      ;;
      	  https)
	      iptables -A INPUT -m tcp -p tcp -m state --source $new_src --state NEW --dport 443 -j ACCEPT
	      $m_inform"Setting firewall \e[34mallow $3\e[0m to \e[32mHTTPS\e[0m port 443 rule"
	      ;;
	      
	      *)
	      $m_inform"I do not have any predefined rules to \e[2madd $2\e[0m using \e[2m$3\e[0m"

	  esac 
	fi
	
fi
