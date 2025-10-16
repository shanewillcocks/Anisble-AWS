##!/bin/bash
age=$1
aws_acct=$2
delete_count=0
retain_count=0
epoch_ts=$(date +'%s')
log_file=/tmp/aws_resource_cleanup.log

echo "Step 5. Delete EBS snapshots older than $((${age}/60/60/24)) days" >> $log_file
ebs_snapshots=$(./aws ec2 describe-snapshots --filters "Name=owner-id,Values=${aws_acct}" | /usr/bin/jq '.Snapshots')
snapshot_count=$(echo $ebs_snapshots | /usr/bin/jq length)
if [ ${snapshot_count} == null ]; then
  echo "No EBS snapshots found, skipping this step" >> $log_file
else
  echo "Found ${snapshot_count} EBS snapshots" >> $log_file
  for ((count=0; count < ${snapshot_count}; ++count)); do
    snapshot_id=$(echo ${ebs_snapshots} | /usr/bin/jq ".[$count].SnapshotId" | /usr/bin/sed 's/\"//g')
    creation_date=$(echo ${ebs_snapshots} | /usr/bin/jq ".[$count].StartTime" | /usr/bin/sed 's/\"//g')
    # Convert the creation date to a timestamp
    ts=$(date -d "${creation_date}" +%s)
    delta=$((${epoch_ts} - ${ts}))
    # DEBUG - dump snapshot details
    #echo "Got EBS snapshot ID: ${snapshot_id} creation date: ${creation_date} and timestamp: ${ts}"
    if [ ${delta} -gt ${age} ]; then
      echo "Deleting EBS snapshot: ${snapshot_id} created ${creation_date}" >> $log_file
      ./aws ec2 delete-snapshot --snapshot-id ${snapshot_id} >/dev/null 2>&1
      rc=$?
      if [ ${rc} -eq 0 ]; then
        echo "Delete of snapshot ${snapshot_id} successful" >> $logfile
        delete_count=$(($delete_count+1))
      else
        echo "Delete of snapshot ${snapshot_id} failed: ${rc}" >> $logfile
      fi
    sleep 1
    else
      echo "Retaining EBS snapshot: ${snapshot_id} created ${creation_date}" >> $logfile
      retain_count=$((retain_count+1))
    fi
  done
  echo "Deleted ${delete_count} EBS snapshots" >> $log_file
  echo "Retained ${retain_count} EBS snapshots" >> $log_file
fi
echo -e "Done\n" >> $log_file
