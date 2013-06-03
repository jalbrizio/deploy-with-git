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
REPOBASE="/git/development"
DEPLOYBASE="/git/deploy-stage"
SERVERNAME=`hostname`
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
# Cleaning out any old veriables that could have been set previously.
#
LIVLOCSUB=""
LIVLOC=""
PRODIP=""
GDOMAIN=`echo $REPO | sed s/\.git//g`
echo "The location of the repo is /var/git/leadsystem.git"
echo ""

#echo ""
echo "What is the location of the live site data?"
echo "example, since all of your sites are saved in $LIVELOCBASE/ and your domain name is domain.com which is saved in the subdirectory Domain.com/httpdocs/"
echo "you would enter Domain.com/httpdocs"
read LIVLOC
echo ""

echo "What is the location of the live site sub module data?"
echo "example, since your live site data is saved in $LIVLOC/ sub module is saved in the subdirectory system/"
echo "you would enter system"
echo "What is the location of the live site sub module data?"
read LIVLOCSUB
echo ""

echo "What is the  production server you are using?"
echo "example whould be: web3 web4 web5"
read PRODIP
echo ""
sleep 3

SITEADD=`grep $LIVELOCBASE/$LIVLOC/$LIVLOCSUB $SUBDSCRIPTS/sites/$PRODIP.txt | wc -l`

echo "Building deployment repo"
echo "User: $SSHUSER" 
echo "Original repo: $REPO"
echo "Deployment repo:  $REPO" 
echo "Location on Production: $LIVELOCBASE/$LIVLOC/$LIVLOCSUB" 
echo "production server IP: $PRODIP"
sleep 6
echo ""

echo "sitebase='$LIVELOCBASE/$LIVLOC/$LIVLOCSUB'" > $DSCRIPTS/mid.txt
echo "ipadd='$PRODIP'" >> $DSCRIPTS/mid.txt
echo "depbase=$DEPLRP" >> $DSCRIPTS/mid.txt


cat $DSCRIPTS/head.txt $DSCRIPTS/mid.txt $DSCRIPTS/gitpull.sh-copy > $DSCRIPTS/gitpull.sh
cat $DSCRIPTS/head.txt $DSCRIPTS/mid.txt $DSCRIPTS/Gitpush.sh-copy > $DSCRIPTS/Gitpush.sh

mkdir -p $SUBDSCRIPTS/sites/
touch $SUBDSCRIPTS/sites/$PRODIP.txt

if [ $SITEADD -gt 0 ]
  then
    echo "there is already and entry in $SUBDSCRIPTS/sites/$PRODIP.txt."
    echo "Skipping the $SUBDSCRIPTS/sites/$PRODIP.txt update"
  else
    echo "No $SUBDSCRIPTS/sites/$PRODIP.txt entries found."
    echo "adding the $SUBDSCRIPTS/sites/$PRODIP.txt entry"
    echo "$PRODIP $LIVELOCBASE/$LIVLOC/$LIVLOCSUB" | cat >> $SUBDSCRIPTS/sites/$PRODIP.txt
fi
sleep 2
echo ""
echo backing up the site first.

ssh gituser@web5 sudo mkdir -p $LIVELOCBASE/$LIVLOC/$LIVLOCSUB --mode=777;
SITEUSER=`sudo ssh gituser@$PRODIP ls -l $LIVELOCBASE/$LIVLOC/$LIVLOCSUB/../../ | grep cgi-bin | awk '{print $3}'`
export SITEUSER
echo "Site user is: $SITEUSER"
ssh gituser@$PRODIP "cd $LIVELOCBASE/$LIVLOC/; cd ../; sudo tar -czf $GDOMAIN.tar.gz $LIVELOCBASE/$LIVLOC/$LIVLOCSUB;"
ssh gituser@$PRODIP "cd $LIVELOCBASE/$LIVLOC/$LIVLOCSUB;cd ..;sudo rm -Rf system;sudo git clone ssh://gituser@$LOCALIP$DEPLRP ./$LIVLOCSUB/;sudo chmod -R 775 $LIVELOCBASE/$LIVLOC/$LIVLOCSUB;sudo chown -R $SITEUSER $LIVELOCBASE/$LIVLOC/$LIVLOCSUB;sudo chgrp -R webdev $LIVELOCBASE/$LIVLOC/$LIVLOCSUB;"
cd $DSCRIPTS
scp gitpull.sh gituser@$PRODIP:$LIVELOCBASE/$LIVLOC/$LIVLOCSUB/gitpull.sh
scp gitignore-addition gituser@$PRODIP:$LIVELOCBASE/$LIVLOC/$LIVLOCSUB/gitignore-addition
ssh gituser@$PRODIP "cd $LIVELOCBASE/$LIVLOC/$LIVLOCSUB;cat gitignore-addition >> .gitignore;
echo ""
echo "done building deploying the sub-module"
echo""
echo ""
echo "As long as the sshkeys are on place you will be able to push to production when ever you do a commit from your deployment repo."
echo ""
echo "if you have more files you want to ignore then add them to the gitignore-additionfile so when you build your repo it will be added."
echo ""
echo "Have a nice day."
echo "
chown -R $DEPUSER.$DEPGRP $DEPLOYBASE/*.git
chgrp -R $DEVGRP $REPOBASE/*.git
chmod -R g+swX $DEPLOYBASE/*.git
chown -R $DEPUSER.$DEPGRP $DSCRIPTS
chmod -R $DEPPERMS $DSCRIPTS
find $DEPLOYBASE -name hooks -exec chmod -R 770 {} \;
exit
