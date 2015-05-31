#!/bin/bash

dir_osid=/etc/osid
dir_imgroot=${dir_osid}/imgroot
dir_system=${dir_osid}/system

#put the status for writing job into a variable
jobstatus=$(cat ${dir_system}/status.info)

#check if the status is equal to one
if [ $jobstatus -eq 1 ]
then

   #make sure the progress info file is empty
   cat /dev/null > ${dir_system}/progress.info
   
   #set the status of the job to two (in progress)
   echo "2" > ${dir_system}/status.info
   
   #put the contents of imagefile, devicelist, and unmount list into variables
   imagefile=$(cat ${dir_system}/imagefile.info)
   devicelist=$(cat ${dir_system}/devicelist.info)
   umountlist=$(cat ${dir_system}/umountlist.info)
   
   #make sure all devices are unmounted
   eval "$umountlist"

   #run the dcfldd command passing the imagefile and device list
   eval "/usr/bin/dcfldd bs=4M if=${dir_imgroot}/$imagefile $devicelist sizeprobe=if statusinterval=1 2>&1 | tee ${dir_system}/progress.info"
   
   #wait 5 seconds after dcfldd command has finished to ensure php script has a chance to read progress.info
   sleep 5

   #empty the contents of the info files ready for the next job
   for InfoFile in devicelist imagefile progress umountlist; do
      cat /dev/null > ${dir_system}/${InfoFile}.info
   done

   #set the status of the job to zero
   echo "0" > ${dir_system}/status.info

fi

exit
