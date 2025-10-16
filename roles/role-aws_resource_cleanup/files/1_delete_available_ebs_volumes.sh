##!/bin/bash

log_file=/tmp/aws_resource_cleanup.log

echo "Step 1. Delete available EBS volumes" >> $log_file
ebs_volumes=$(./aws ec2 describe-volumes --filters "Name=status,Values=available" --query 'Volumes[*].VolumeId' --output text)
delete_count=0
for volume in $ebs_volumes
do
  echo "Deleting volume ${volume}" >> $log_file
  ./aws ec2 delete-volume --volume-id ${volume} >/dev/null 2>&1
  rc=$?
  if [ ${rc} -eq 0 ]; then
    echo "Delete successful" >> $log_file
    delete_count=$(($delete_count+1))
  else
    echo "Delete failed: ${rc}" >> $log_file
  fi
  sleep 1
done
if [ ${delete_count} -gt 0 ]; then
  echo "Deleted ${delete_count} EBS volumes" >> $log_file
else
  echo "No EBS volumes found for deletion" >> $log_file
fi
echo -e "Done\n" >> $log_fil
