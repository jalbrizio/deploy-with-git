#!/bin/bash
#
#
# Created by Jeremi Albrizio 11/7/2012
# This file should never be placed in /
#
# 
#
DEPUSER=root
DEPGRP=deploy
DEVGRP=dev
DEPPERMS=770
SERVERNAME=`hostname`
REPOBASE="/git/development"
DEPLOYBASE="/git/deploy-stage"
LOCALIP=`wget -qO- ifconfig.me/ip`
DSCRIPTS="$DEPLOYBASE/deploy-scripts"
#TODAYSDATE=$(date +"$m%d%y-%H%M")
TODAYSDATE=`date`
SSHUSER=gituser
DEPLRP="$DEPLOYBASE/leadsystem.git"
REPO="$REPOBASE/leadsystem.git"
SUBDSCRIPTS=$DSCRIPTS/submodule
LIVELOCBASE="/var/www/vhosts"
PATH=`pwd`:$PATH
#
#

cd $SUBDSCRIPTS
cat ./head.sh > $SUBDSCRIPTS/dep-lead3.sh
cat ./head.sh > ./deplead.sh
cat ./sites/*.txt |sed s/\ /\|/g | sed s/\\//\\\\\\\\\\//g | sed s/\|/\\\\\ \\/g\ \|\ sed\ s\\/yyyyyyyyyy\\//g | sed s/^/cat\ dep\-lead\.sh\ \|\ sed\ s\\/xxxxxxxxxx\\//g | sed s/$/\\/g\ \\\>\\\>\ dep\-lead3\.sh/g >> deplead.sh
sh ./deplead.sh
