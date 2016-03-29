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

declare -a ipv4_addr_array

  for ips in `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -v "127.0.0.1" | grep -Eo '([0-9]*\.){3}[0-9]*'` ; do
    ipv4_addr_array+=("$ips")
  done

  for ips in "${ipv4_addr_array[@]}" ; do
    echo I have an ipv4 adress of: $ips
    my_socket=`netstat -tnp -4 | grep $ips:22 | grep "sshd" | cut -f 2 -d : | sed s"/^22 //"g | tr -d " " 
  done