##!/bin/bash

age=$1
epoch_ts=$(date +'%s')
log_file=/tmp/aws_resource_cleanup.log
ami_prefixes=("RHEL8" "RHEL9" "RHEL10" "Win2022" "Win2025")

echo "Step 2. Delete BNZ Amazon Machine Images older than $((${age}/60/60/24)) days" >> $log_file
echo "Note: Images are only deleted if there are 2 or more old images found for a given prefix." >> $log_file
# Query AWS for owned images for each prefix
for prefix in "${ami_prefixes[@]}"; do
  # Array to store the image IDs to deregister
  deregister_images=()
  # Query AWS for owned images for each prefix reverse sorted by CreationDate
  images=$(./aws ec2 describe-images --owners self --filters "Name=name,Values=${prefix}*" --query 'reverse(sort_by(Images, &CreationDate))')
  image_count=$(echo $images | /usr/bin/jq length)
  if [ ${image_count} -gt 0 ]; then
    echo "Checking ${image_count} image(s) for ${prefix}" >> $log_file
    for ((count=0; count < ${image_count}; ++count)); do
      image_name=$(echo ${images} | /usr/bin/jq ".[$count].Name " | /usr/bin/sed 's/\"//g')
      image_id=$(echo ${images} | /usr/bin/jq ".[$count].ImageId" | /usr/bin/sed 's/\"//g')
      creation_date=$(echo ${images} | /usr/bin/jq ".[$count].CreationDate" | /usr/bin/sed 's/\"//g')
      # Convert the creation date to a timestamp
      image_ts=$(date -d "${creation_date}" +%s)
      delta=$((${epoch_ts} - ${image_ts}))
      if [ ${delta} -gt ${age} ]; then
        echo "Image ${image_name}:${image_id} created ${creation_date} is older than $((${age}/60/60/24)) days" >> $log_file
        deregister_images+=("${image_id}")
      else
        echo "Image ${image_name}:${image_id} creation date: ${creation_date} can be retained" >> $log_file
      fi
    done
    deregister_count="${#deregister_images[@]}"
    # Deregister the images if there are 2 or more images with the same prefix, leaving the newest image
    if [ ${deregister_count} -ge 2 ]; then
      for image_id in "${deregister_images[@]:1}"; do
        echo "Deregistering image ${image_id}" >> $log_file
        ./aws ec2 deregister-image --image-id ${image_id} >/dev/null 2>&1
        rc=$?
        if [ ${rc} -eq 0 ]; then
          echo "Deregistration successful" >> $log_file
        else
          echo "Deregistration failed: ${rc}" >> $log_file
        fi
      done
    else
      echo "No images to be deleted this pass for ${prefix}" >> $log_file
    fi
    unset deregister_images
  else
    echo "No images found for prefix ${prefix}" >> $log_file
  fi
done
echo -e "Done\n" >> $log_file
