#!/bin/bash
#
#################################################################################
#			  Outhouse shell scripting for automatic firewall restore
#							(via cron) at PRCCDC 2016
#
#                  Do not run this on anything that is actually important to you
#						                 bofh@pencol.edu
#
m_issue="echo -e \e[2m[\e[33m\e[1m!\e[0m\e[2m]\e[0m "
m_inform="echo -e \e[2m[\e[36m.\e[0m\e[2m]\e[0m "
m_choose="echo -e \e[2m[\e[34m=\e[0m\e[2m]\e[0m "
$m_inform"Now using rapid module: [\e[33mOne Time firewall restore\e[0m]"


function firewall_schedule_cron {

    # you should totally change the dates on this
    # mine are one-time usage for 2016-04-02
    
    $m_inform"This subsection attempts to do one thing:"
    $m_inform"    \e[2m1\e[0m) schedule a restore of the current firewall to kick off at \e[33m5:00am\e[0m on \e[33m04/02\e[0m"
    echo
    $m_inform"If the update script has scheduled a full update/reboot combo, it should finish around 4:30am"
    $m_inform"Concept assumes existing crontab rules, as otherwise it is unneccisary"
    echo 
    $m_choose"Add firewall restore scheduler now?  \e[2m[\e[32m\e[1my\e[0m\e[2m|\e[31m\e[1mn\e[0m\e[2m] \e[0m"
    read -p "> " -t 60 invoke_scheduler
       if [[ "$invoke_scheduler" == y || "$invoke_scheduler" == Y ]] ; then
          
	    ext=`date +%b_%d_%A_%H%M`
	    ipts=`which iptables-save`
	    iptr=`which iptables-restore`
	    ipt_save_file=rapidnet.generated.firewall.$ext.iptables
    
	  if [[ -d $SCRIPT_HOME_BACKUPS ]] ; then
	    if [[ -d $SCRIPT_HOME_BACKUPS/firewall ]] ; then
	      $ipts > $SCRIPT_HOME_BACKUPS/firewall/$ipt_save_file
	    else
	      mkdir $SCRIPT_HOME_BACKUPS/firewall
	      $ipts > $SCRIPT_HOME_BACKUPS/firewall/$ipt_save_file
	    fi
	  fi
	  
	$m_inform"Your current firewall is now backed up to: \e[2m$SCRIPT_HOME_BACKUPS/firewall/$ipt_save_file\e[0m"
	    
      	    echo "$iptr $SCRIPT_HOME_BACKUPS/firewall/$ipt_save_file" > $SCRIPT_HOME_INFOS/onetime-firewall-restore.sh
	    chmod 700 $SCRIPT_HOME_INFOS/onetime-firewall-restore.sh
	    
	    #minute/hour/day of month/month/day in week
	    echo "2 5 2 4 * $SCRIPT_HOME_INFOS/onetime-firewall-restore.sh" >> $SCRIPT_HOME_INFOS/mycronjobs.cron
	    cat $SCRIPT_HOME_INFOS/mycronjobs.cron | crontab - xargs
      else
	$m_inform"Nothing to do in firewall scheduler .."
      fi
      
     $m_inform"The firewall scheduler module has finished" 
}

  firewall_schedule_cron
  

# fini
