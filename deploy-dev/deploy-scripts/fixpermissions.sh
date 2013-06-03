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
#
#
chown -R $DEPUSER.$DEPGRP $DEPLOYBASE/*.git
chgrp -R $DEVGRP $REPOBASE/*.git
chmod -R g+swX $DEPLOYBASE/*.git
chown -R $DEPUSER.$DEPGRP $DSCRIPTS
chmod -R $DEPPERMS $DSCRIPTS
find $DEPLOYBASE -name hooks -exec chmod -R 770 {} \;
rm -Rf $DEPLOYBASE/paging/
exit
