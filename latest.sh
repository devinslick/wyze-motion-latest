#!/bin/sh

# file below is /media/mmc/wz_mini/latest.sh
#
# to install this, add this line:
#* * * * * /media/mmc/wz_mini/latest.sh
# to this file: /media/mmc/wz_mini/etc/cron/root
#
# create a configuration file at this path: /media/mmc/wz_mini/.env
# Example file contents:
#alarmWebhookURL=https://subdomain.domain.com/api/webhook/my-secret-camera-alarm-url
#videoWebhookURL=https://subdomain.domain.com/api/webhook/my-secret-camera-alarm-url

#variables
grep -v '^#' /media/mmc/wz_mini/.env
export $(grep -v '^#' /media/mmc/wz_mini/.env | xargs)

#check for latest files
if [ ! -f /media/mmc/wz_mini/www/latest.jpg ]; then
    echo "latest.jpg not found, creating placeholder for mount with touch..."
    touch /media/mmc/wz_mini/www/latest.jpg
fi
if [ ! -f /media/mmc/wz_mini/www/latest.mp4 ]; then
    echo "latest.mp4 not found, creating placeholder for mount with touch..."
    touch /media/mmc/wz_mini/www/latest.mp4
fi

#script
currentAlarmFile=$(ls -i /media/mmc/wz_mini/www/latest.jpg)
currentVideoFile=$(ls -i /media/mmc/wz_mini/www/latest.mp4)
newAlarmFile=$(ls -id $(find /media/mmc/alarm/$(ls /media/mmc/alarm/ | tail -1)/ -name "*.jpg" -print | tail -1))
newVideoFile=$(ls -id $(find /media/mmc/record/ -name "*.mp4" -print | tail -1))

cINodeAlarm=$(echo $currentAlarmFile | cut -d ' ' -f 1)
nINodeAlarm=$(echo $newAlarmFile | cut -d ' ' -f 1)
cINodeVideo=$(echo $currentVideoFile | cut -d ' ' -f 1)
nINodeVideo=$(echo $newVideoFile | cut -d ' ' -f 1)
if [ $cINodeAlarm == $nINodeAlarm ]
then
  echo "Alarm iNodes are the same ($cINodeAlarm), file has not changed"
else
  newPath=$(echo $newAlarmFile | cut -d ' ' -f 2)
  echo "Alarm iNodes are different ($cINodeAlarm vs $nINodeAlarm); file has changed. Mount being updated to $newPath"
  /bin/mount --bind $newPath /opt/wz_mini/www/latest.jpg
  echo "Notifying Home Assistant of the new alarm event..."
  curl -kX POST -d '{ "key": "value" }' $alarmWebhookURL
fi
if [ $cINodeVideo == $nINodeVideo ]
then
  echo "Video iNodes are the same ($cINodeVideo), file has not changed"
else
  newPath=$(echo $newVideoFile | cut -d ' ' -f 2)
  echo "Video iNodes are different ($cINodeAlarm vs $nINodeAlarm); file has changed. Mount being updated to $newPath"
  /bin/mount --bind $newPath /opt/wz_mini/www/latest.mp4
  echo "Notifying Home Assistant of the new video event..."
  curl -kX POST -d '{ "key": "value" }' $videoWebhookURL
fi
