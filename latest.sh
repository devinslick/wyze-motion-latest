#!/bin/sh

# file below is /media/mmc/wz_mini/latest.sh
#
# to install this, add this line:
#* * * * * /media/mmc/wz_mini/latest.sh
# to this file: /media/mmc/wz_mini/etc/cron/root
#
# To use webhooks create a configuration file at this path: /media/mmc/wz_mini/.env
# Example file contents:
#alarmWebhookURL=https://subdomain.domain.com/api/webhook/my-secret-camera-alarm-url
#videoWebhookURL=https://subdomain.domain.com/api/webhook/my-secret-camera-alarm-url
#
# To access the last events and videos use http://camera-address/latest.jpg and http://camera-address/latest.mp4
#

#import variables for webhook notifications to home assistant
if [ -f /media/mmc/wz_mini/.env ]; then
    grep -v '^#' /media/mmc/wz_mini/.env
    export $(grep -v '^#' /media/mmc/wz_mini/.env | xargs)
fi

#get newest available alarm jpg and mp4 video (inode and path)
pathNewestJPG=$(ls $(find /media/mmc/alarm/$(ls /media/mmc/alarm/ | tail -1)/ -name "*.jpg" -print | tail -1))
pathNewestMP4=$(ls $(find /media/mmc/record/ -name "*.mp4" -print | tail -1))

#read the last jpg filename from disk into a var
if [ -f /media/mmc/wz_mini/lastMotionFileJPG ]; then
    lastJPGCopied=$(cat /media/mmc/wz_mini/lastMotionFileJPG)
    if [ $lastJPGCopied == $pathNewestJPG ]
    then
        echo "jpg files are the same"
    else
        echo "new jpg needs to be copied"
        cp -f $pathNewestJPG /media/mmc/wz_mini/www/latest.jpg
        echo $pathNewestJPG > /media/mmc/wz_mini/lastMotionFileJPG
        if test ${alarmWebhookURL}
        then
            echo "Notifying Home Assistant of the new alarm event..."
            curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestJPG" }' $alarmWebhookURL
        fi
    fi
else
    echo "New! new file needs to be copied"
    cp $pathNewestJPG /media/mmc/wz_mini/www/latest.jpg
    echo $pathNewestJPG > /media/mmc/wz_mini/lastMotionFileJPG
    if test ${alarmWebhookURL}
    then
        echo "Notifying Home Assistant of the new alarm event..."
        curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestJPG" }' $alarmWebhookURL
    fi
fi

#read the last mp4 filename from disk into a var
if [ -f /media/mmc/wz_mini/lastVideoFileMP4 ]; then
    lastMP4Copied=$(cat /media/mmc/wz_mini/lastVideoFileMP4)
    if [ $lastMP4Copied == $pathNewestMP4 ]
    then
        echo "mp4 files are the same"
    else
        echo "new mp4 needs to be copied"
        cp -f $pathNewestMP4 /media/mmc/wz_mini/www/latest.mp4
        echo $pathNewestMP4 > /media/mmc/wz_mini/lastVideoFileMP4
        if test ${videoWebhookURL}
        then
            echo "Notifying Home Assistant of the new video event..."
            curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestMP4" }' $videoWebhookURL
        fi
    fi
else
    echo "New! new file needs to be copied"
    cp $pathNewestMP4 /media/mmc/wz_mini/www/latest.mp4
    echo $pathNewestMP4 > /media/mmc/wz_mini/lastVideoFileMP4
    if test ${videoWebhookURL}
    then
        echo "Notifying Home Assistant of the new video event..."
        curl -kX POST -H "Content-Type: application/json" -d '{ "path": "$pathNewestMP4" }' $videoWebhookURL
    fi
fi
