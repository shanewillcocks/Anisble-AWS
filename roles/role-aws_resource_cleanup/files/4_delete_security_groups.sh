##!/bin/bash
log_file=/tmp/aws_resource_cleanup.log

echo "Step 4. Delete temporary Builder security groups" >> $log_file
security_groups=$(./aws ec2 describe-security-groups --filters "Name=group-name,Values=builder_*" --query 'SecurityGroups[*].GroupId' --output text)
if [ "${security_groups}" == "" ]; then
  echo "No Builder security groups found, skipping step" >> $log_file
else
  delete_count=0
  for builder_sg in $security_groups
  do
    echo "Deleting Builder security group ${builder_sg}" >> $log_file
    ./aws ec2 delete-security-group --group-id ${builder_sg} >/dev/null 2>&1
    rc=$?
    if [ ${rc} -eq 0 ]; then
      echo "Delete successful"
      delete_count=$(($delete_count+1))
    else
      echo "Delete failed: ${rc}" >> $log_file
    fi
    sleep 1
  done
  echo "Deleted ${delete_count} Builder security groups" >> $log_file
fi
echo -e "Done\n" >> $log_file
