#!/bin/bash
#
#################################################################################
#			 Outhouse shell scripting for automatic disabling of IPv6
#								   at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[33mIPv6 Disabler\e[0m]"


function turnoff_ipv6 {

    which sysctl &> /dev/null
    if [[ $? -eq 0 ]] ; then
      sysctl_bin=`which sysctl`
      $m_inform"Found sysctl: $sysctl_bin"
    fi
    
    which ip6tables &> /dev/null
    if [[ $? -eq 0 ]] ; then
      ipt6=`which ip6tables`
      $m_inform"Found ip6tables: $ipt6"
    fi   
    
    $m_inform"If you are not required to support IPv6, it is a security issue, and can bypass IPv4 firewall restrictions"
    $m_inform"You can choose to disable it here"
    echo 
    $m_choose"Disable IPv6 now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_kill6
    
       if [[ "$invoke_kill6" == y || "$invoke_kill6" == Y ]] ; then
	  
	  if [[ -n $ipt6 && $ipt6 != undef ]] ; then
	    $m_inform"Flushing current IPv6 firewall ruleset (this does not affect IPv4 rules)"
	    $ipt6 -F
	    sleep 2
	    $m_inform"Setting default inbound IPv6 policy to DROP .."
	    $ipt6 -P INPUT DROP
	    $m_inform"Setting default outbound IPv6 policy to DROP .."
	    $ipt6 -P OUTPUT DROP
	    $m_inform"Setting default forward IPv6 policy to DROP .."
	    $ipt6 -P FORWARD DROP
	    $m_inform"Disabling IPv6 routing .."
	    
	    $ipt6 -t nat &> /dev/null
	    if [[ $? -eq 0 ]] ; then
	      $ipt6 -t nat -P INPUT DROP
	      $ipt6 -t nat -P OUTPUT DROP
	      $ipt6 -t nat -P PREROUTING DROP
	      $ipt6 -t nat -P POSTROUTING DROP
	      $m_inform"IPv6 NAT disabled"
	    else
	      $m_inform"NAT module for ipv6 not loaded, we can skip this"
	    fi
	    echo
	    sleep 2
	  else
	    $m_issue"No ip6tables found on this system"
	  fi
	  
	  $m_inform"Now we can ask the kernel to turn off IPv6"
	  echo
	  
	  which sysctl &> /dev/null
	  if [[ $? -eq 0 ]] ; then
	    $m_inform"sysctl found, using it .."
	    sysctl -w net.ipv6.conf.all.disable_ipv6=1
	  else
	    $m_inform"no sysctl found, falling back to basic kernelspace configuration toggle .."
	    echo "1" > /proc/sys/net/ipv6/conf/all/disable_ipv6
	  fi
	  
	  sleep 2
	  $m_inform"All IPv6 usage has been blocked and/or locked out"
	  $m_inform"You may need to if-down/if-up interfaces to remove any stale references"
	  $m_inform"However, this script will not do that, as it would kill any SSH login you may be currently using"
	  echo
	  
	  $m_inform"The IPv6 nerfing module has completed"
	  
	fi

}

turnoff_ipv6


# fini

	  
	  