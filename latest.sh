#!/bin/sh
# You can use the following 3 lines to install this script.  On first execution it will run for 60 seconds unless interrupted.  
# If you stop it then cron will have it continue running in the background.
#  
#   curl -kL https://raw.githubusercontent.com/devinslick/wyze-motion-latest/main/latest.sh > /media/mmc/wz_mini/latest.sh
#   chmod +x /media/mmc/wz_mini/latest.sh
#   /media/mmc/wz_mini/latest.sh
#
#  If you do *not* want it running via the cronjob, just add a line for the script in the cron file manually.  Ex: '#lastest.sh'
#
# To access the last events and videos use http://camera-address/latest.jpg and http://camera-address/latest.mp4
#
# To use webhooks you will need ALARM_WEBHOOK and/or VIDEO_WEBHOOK defined in /media/mmc/wz_mini/wz_mini.conf
# As an example, you may append the following to the bottom of the file:
###### LATEST #####
#ALARM_WEBHOOK="https://subdomain.domain.com/api/webhook/my-secret-camera-alarm-url"
#VIDEO_WEBHOOK="https://subdomain.domain.com/api/webhook/my-secret-camera-alarm-url"

#import variables for webhook notifications to home assistant
alarmWebhookURL=$(cat /media/mmc/wz_mini/wz_mini.conf | grep ALARM_WEBHOOK | cut -d '=' -f 2 | sed 's/"//g')
videoWebhookURL=$(cat /media/mmc/wz_mini/wz_mini.conf | grep VIDEO_WEBHOOK | cut -d '=' -f 2 | sed 's/"//g')

# install cron job if it doesnt exist already
cronjobexists=$(cat /media/mmc/wz_mini/etc/cron/root | grep latest.sh | wc -l)
if [ "$cronjobexists" == "1" ]; then
    echo "Cron job already installed"
else
    echo "Installing cron job to /media/mmc/wz_mini/etc/cron/root"
    echo '* * * * * /bin/timeout 60 bash -c /media/mmc/wz_mini/latest.sh' > /media/mmc/wz_mini/etc/cron/root
fi

n=0
while [ "$n" -lt 60 ]; do
  #get newest available alarm jpg and mp4 video (inode and path)
  n=$(( n + 1 ))
  pathNewestJPG=$(ls $(find /media/mmc/alarm/$(ls /media/mmc/alarm/ | tail -1)/ -name "*.jpg" -print | tail -1))
  pathNewestMP4=$(ls $(find /media/mmc/record/ -name "*.mp4" -print | tail -1))
  #read the last jpg filename from disk into a var
  if [ -f /media/mmc/wz_mini/lastMotionFileJPG ]; then
      lastJPGCopied=$(cat /media/mmc/wz_mini/lastMotionFileJPG)
      if [ $lastJPGCopied == $pathNewestJPG ]
      then
          echo "The last created jpg file was already copied to latest.jpg.  Skipping."
      else
          echo "New JPG! Copying $pathNewestJPG to latest.jpg..."
          cp -f $pathNewestJPG /media/mmc/wz_mini/www/latest.jpg
          echo $pathNewestJPG > /media/mmc/wz_mini/lastMotionFileJPG
          if test ${alarmWebhookURL}
          then
              echo "Triggering webhook for new alarm JPG"
              curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestJPG" }' $alarmWebhookURL
          fi
      fi
  else
      echo "New JPG! Copying $pathNewestJPG to latest.jpg..."
      cp $pathNewestJPG /media/mmc/wz_mini/www/latest.jpg
      echo $pathNewestJPG > /media/mmc/wz_mini/lastMotionFileJPG
      if test ${alarmWebhookURL}
      then
          echo "Triggering webhook for new alarm JPG"
          curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestJPG" }' $alarmWebhookURL
      fi
  fi
  #read the last mp4 filename from disk into a var
  if [ -f /media/mmc/wz_mini/lastVideoFileMP4 ]; then
      lastMP4Copied=$(cat /media/mmc/wz_mini/lastVideoFileMP4)
      if [ $lastMP4Copied == $pathNewestMP4 ]
      then
          echo "The last created mp4 file was already copied to latest.mp4.  Skipping."
      else
          echo "New MP4! Copying $pathNewestJPG to latest.mp4..."
          cp -f $pathNewestMP4 /media/mmc/wz_mini/www/latest.mp4
          echo $pathNewestMP4 > /media/mmc/wz_mini/lastVideoFileMP4
          if test ${videoWebhookURL}
          then
              echo "Triggering webhook for new mp4 video creation"
              curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestMP4" }' $videoWebhookURL
          fi
      fi
  else
      echo "New MP4! Copying $pathNewestJPG to latest.mp4..."
      cp $pathNewestMP4 /media/mmc/wz_mini/www/latest.mp4
      echo $pathNewestMP4 > /media/mmc/wz_mini/lastVideoFileMP4
      if test ${videoWebhookURL}
      then
          echo "Triggering webhook for new mp4 video creation"
          curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestMP4" }' $videoWebhookURL
      fi
  fi
  sleep 1
done
