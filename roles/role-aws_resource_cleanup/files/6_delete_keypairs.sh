##!/bin/bash

log_file=/tmp/aws_resource_cleanup.log

echo "Step 6. Delete temporary keypairs" >> $log_file
packer_keypairs=$(aws ec2 describe-key-pairs --filters "Name=key-name,Values=builder*" --query 'KeyPairs[*].KeyName' --output text)
if [ "${builder_keypairs}" == "" ]; then
  echo "No Builder keypairs found, skipping step" >> $log_file
else
  delete_count=0
  for keypair in $builder_keypairs
  do
    echo "Deleting keypair ${keypair}" >> $log_file
    ./aws ec2 delete-key-pair --key-name ${keypair} >/dev/null 2>&1
    rc=$?
    if [ ${rc} -eq 0 ]; then
      echo "Delete successful" >> $log_file
      delete_count=$(($delete_count+1))
    else
      echo "Delete failed: ${rc}" >> $log_file
    fi
    sleep 1
  done
  echo "Deleted ${delete_count} Builder keypairs" >> $log_file
fi
echo -e "Done\n" >> $log_file
