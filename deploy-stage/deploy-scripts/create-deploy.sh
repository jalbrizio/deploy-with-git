#!/bin/bash
#
#
# Created by Jeremi Albrizio 11/7/2012
# This file should never be placed in /
#
# 
#
SERVERTYPE="staging"
SITEGRP="webdeveloper"
BASE1="git"
REPOBASE1="development"
REPOBASE="/$BASE1/$REPOBASE1"
DEPLOYBASE1="deploy-stage"
DEPLOYBASE="/$BASE1/$DEPLOYBASE1"
SERVERNAME=`hostname`
LOCALIP="default-git-server-hostname.com"
#LOCALIP=`wget -qO- ifconfig.me/ip`
DSCRIPTS="$DEPLOYBASE/deploy-scripts"
HOSTBASE="/var/www/vhosts"
HOSTDOCS="httpdocs"
SSHUSER=gitusername
TODAYSDATE=`date`
##resetting variables incase there is something in memmory
LIVLOC=""
PRODIP=""
DEFSERV="staging-server-hostname.com"
#optional Date variable. Uncomment if you want to use this date format and comment out the one above
#TODAYSDATE=$(date +"$m%d%y-%H%M")

#optional user veriable if you want to use more than one user to ssh into different servers. 
#Uncomment if you want to to be asked what they ssh user will be and comment out the one above
#echo "What is the user you are using?"
#read SSHUSER

#
echo ""
echo "What is the location of the repo? the base directory is $REPOBASE."
echo "example domain_com.git"
read REPO

while [ ! -d $REPOBASE/$REPO ]
do
	echo ""
	echo "$REPOBASE/$REPO does not exist. Please try again."
	read REPO
done

echo ""
GD=`echo $REPO | sed s/\.git//g |sed s/\_/\./g | sed 's/\// /g' | awk '{ print $1 }'`
REPONAME=`echo $REPO |sed s/\_/\./g | sed 's/\// /g' | awk '{ print $2 }'`
echo "The repo name is $REPONAME"
echo ""
#
echo What is the domain? If you want to use the domain: $GD then hit enter.
read DOM
if [ -z "$DOM" ]
then
	GDOMAIN=$GD
else
	GDOMAIN=$DOM
fi

echo ""
#
echo "If you are setting up a subfolder only then enter the path relative to $GDOMAIN, otherwise hit enter"
read SUBF
if [ -z "$SUBF" ]
then
	echo "Your webserver uses $HOSTBASE for each domain and in the site directory the sites document root is $HOSTDOCS"
	echo "What is the directory name of your site? ** THis is case sensitive**"
	echo "example: Domain.com or hit enter to use $GDOMAIN"
	read LIVLOC
	if [ -z  "$LIVLOC" ]  
	then
        	LIVLOC=$GDOMAIN
	fi
	echo you entered $LIVLOC
	echo ""
	echo "you will be deploying to $HOSTBASE/$LIVLOC/$HOSTDOCS"
	DEPTO=$HOSTBASE/$LIVLOC/$HOSTDOCS
else
	echo ""
	echo "you will be deploying to $HOSTBASE/$GDOMAIN/$SUBF"
	DEPTO=$HOSTBASE/$GDOMAIN/$SUBF
fi
#
echo ""
echo "Where do you want to put the ${REPONAME} repo? hit enter to use $DEPLOYBASE/$REPO. The base directory is $DEPLOYBASE"
read DREPO
if [ "$DREPO" = "" ]
then
	DREPO="$REPO"
fi

#
echo ""
echo "What is the ip address of the $SERVERTYPE server you are using?"
echo "example: 68.2.16.30 or hostname or hit enter to use $DEFSERV"
read PRODIP
if [ -z  "$PRODIP" ]
then
        PRODIP=$DEFSERV
fi
echo You entered $PRODIP
echo ""
#
#
echo ""
sleep 1
DEPREPOPATH="$DEPLOYBASE/$DREPO/$REPONAME"
echo "Building deployment repo"
echo "User: $SSHUSER" 
echo "Original repo path: $REPOBASE/$REPO"
echo "Deployment repo path: $DEPREPOPATH" 
echo "Location on $SERVERTYPE: $DEPTO"
echo "$SERVERTYPE server IP: $PRODIP"
echo "dscripts: $DSCRIPTS"
sleep 3
echo ""
#
#
#
mkdir -p $DEPREPOPATH
cd $DEPREPOPATH
git init --bare
#

#
echo "sitebase='$DEPTO'" > $DSCRIPTS/mid.txt
echo "ipadd='$PRODIP'" >> $DSCRIPTS/mid.txt
echo "depbase=$DEPREPOPATH" >> $DSCRIPTS/mid.txt
echo "SITEGRP=$SITEGRP" >> $DSCRIPTS/mid.txt
#

#
git clone $REPOBASE/$REPO $DEPLOYBASE/paging

cp $DSCRIPTS/post-receive.sample  $REPOBASE/$REPO/hooks/post-receive
sudo chmod -R 770 $REPOBASE/$REPO/hooks/post-receive

echo "cloned Repo"

#cat $DSCRIPTS/htaccess-addition | sed s/xxxxxxxxxx/$GDOMAIN/g >> $DEPLOYBASE/paging/.htaccess
#echo "updated htaccess file"
cat $DSCRIPTS/gitignore-addition >> $DEPLOYBASE/paging/.gitignore
cd $DEPLOYBASE/paging/ 
git add -A
git commit -m "initial deploy repo setup" -a
git remote add deploy $DEPREPOPATH
sudo chown -R root.deploy $DEPLOYBASE/*.git
git push deploy master
git push
mkdir -p $DEPREPOPATH/hooks/
sudo chmod -R 777 $DEPREPOPATH/hooks/
touch $DEPREPOPATH/hooks/Gitpush.sh
touch $DEPREPOPATH/hooks/gitpull.sh
sudo chmod -R 777 $DEPREPOPATH/hooks/
cat $DSCRIPTS/head.txt $DSCRIPTS/mid.txt $DSCRIPTS/gitpull.sh-copy > $DEPREPOPATH/hooks/gitpull.sh
cat $DSCRIPTS/head.txt $DSCRIPTS/mid.txt $DSCRIPTS/Gitpush.sh-copy > $DEPREPOPATH/hooks/Gitpush.sh

cp $DSCRIPTS/post-commit $DEPREPOPATH/hooks/
sudo chmod -R 777 $DEPREPOPATH/hooks/
#cat $DSCRIPTS/post-receive | sed s/xxxxxxxxxx/$DEPLOYBASE\\/$REPO/hooks/g > $DEPLOYBASE/$REPO/hooks/post-receive
cat $DEPLOYBASE/deploy-scripts/post-receive | sed s/xxxxxxxxxx/\\/$BASE1\\/$DEPLOYBASE1\\/$DREPO\\/$REPONAME\\/hooks/g > $DEPREPOPATH/hooks/post-receive
sleep 2

echo backing up the site first.
ssh -t gituser@$PRODIP "sudo mkdir -p $DEPTO --mode=777;sudo chmod -R 777 $DEPTO;ls $DEPTO/../ | grep $HOSTDOCS"
siteuser=`ssh -t gituser@$PRODIP ls -l $DEPTO/../ | grep cgi-bin | awk '{print $3}'`
export siteuser
echo "sites user is: $siteuser"
ssh -t gituser@$PRODIP "sudo mkdir -p $DEPTO --mode=777;sudo chmod -R 777 $DEPTO; sudo tar -czf $DEPTO/../$GDOMAIN.$REPONAME.tar.gz $DEPTO;"

if grep -i $HOSTBASE $DEPTO
then
	ssh -t gituser@$PRODIP "sudo rm -Rf $DEPTO;"
fi

sudo chown -R root.deploy $DEPLOYBASE/*.git
sudo chmod -R g+swX $DEPLOYBASE/*.git
sudo chown -R root.deploy $DSCRIPTS
sudo chmod -R 770 $DSCRIPTS
sudo find $DEPLOYBASE -name hooks -exec chmod -R 770 {} \;

#ssh -t gituser@$PRODIP "sudo mkdir -p $DEPTO --mode=777;sudo chmod -R 777 $DEPTO/;"
ssh -t gituser@$PRODIP "sudo mkdir -p $DEPTO --mode=777;sudo chmod -R 777 $DEPTO/;"
ssh -t gituser@$PRODIP "cd $DEPTO;cd ../;sudo git clone ssh://gituser@$LOCALIP$DEPREPOPATH $DEPTO;sudo chmod -R 775 $DEPTO;sudo "chown -R $siteuser.$SITEGRP $DEPTO";"
cd $DEPREPOPATH/hooks/
scp $DEPREPOPATH/hooks/gitpull.sh gituser@$PRODIP:$DEPTO/gitpull.sh
cd $DSCRIPTS/
scp $DSCRIPTS/gitignore-addition gituser@$PRODIP:$DEPTO/gitignore-addition
ssh -t gituser@$PRODIP "cd $DEPTO;cat $DEPTO/gitignore-addition >> $DEPTO/.gitignore;"
echo ""
sudo rm -Rf $DEPLOYBASE/paging/
echo "done building deployment"
echo""
echo "Make sure the Gitpush.sh and gitpull.sh files get placed in your developement repo"
echo ""
echo "Then go to the production server and do a git clone ssh://gituser@$LOCALIP$DREPO"
echo ""
echo "As long as the sshkeys are on place you will be able to push to production when ever you do a commit from your deployment repo."
echo ""
echo "if you have more files you want to ignore then add them to the gitignore-additionfile so when you build your repo it will be added"
echo ""

sudo chgrp -R $SITEGRP $REPOBASE/*.git
sudo chown -R root.deploy $DEPLOYBASE/*.git
sudo chmod -R g+swX $DEPLOYBASE/*.git
sudo chown -R root.deploy $DSCRIPTS
sudo chmod -R 770 $DSCRIPTS
sudo find $DEPLOYBASE -name hooks -exec chmod -R 770 {} \;
if [ -d $DEPLOYBASE/paging ]
then
	sudo rm -Rf $DEPLOYBASE/paging/
fi
