##
siteuser=`sudo ssh gituser@xxxxxxxxxx ls -l yyyyyyyyyy/../ | grep cgi-bin | awk '{print $3}'`
#
sudo ssh gituser@xxxxxxxxxx "cd yyyyyyyyyy/;sudo chmod -R 775 yyyyyyyyyy;sudo git reset --hard HEAD;sudo git pull;sleep 5;sudo chmod -R 775 yyyyyyyyyy;sudo chown -R $siteuser.webdev yyyyyyyyyy;
##
#
