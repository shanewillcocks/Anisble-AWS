##!/bin/bash
log_file=/tmp/aws_resource_cleanup.log

echo "Step 3. Terminate running Packer EC2 instances" >> $log_file
# Query for all instances with a key pair starting with 'packer_'
instances=$(./aws ec2 describe-instances --filters "Name=key-name,Values=builder_*" --query "Reservations[*].Instances[*].InstanceId" --output text)
# Terminate the instances
if [ -z "$instances" ]; then
  echo "No Builder initiated EC2 instances found, skipping step" >> $log_file
else
  delete_count=0
  for instance in $instances
  do
    echo "Terminating instance ${instance}" >> $log_file
    ./aws ec2 terminate-instances --instance-ids $instance >/dev/null 2>&1
    rc=$?
    if [ ${rc} -eq 0 ]; then
      echo "Terminate succeeded" >> $log_file
      delete_count=$(($delete_count+1))
    else
      echo "Terminate request failed: ${rc}" >> $log_file
    fi
    sleep 1
  done
  echo "Terminated ${delete_count} EC2 instances" >> $log_file
  echo -e "Done\n" >> $log_file
fi
