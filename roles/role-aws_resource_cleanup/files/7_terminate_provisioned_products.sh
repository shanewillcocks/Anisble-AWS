##!/bin/bash
age=$1
epoch_ts=$(date +'%s')
log_file=/tmp/aws_resource_cleanup.log

echo "Step 7. Terminate AMI Transporter products older than $((${age}/60/60/24)) days" >> $log_file
ami_transporter_id=$(./aws servicecatalog search-products --query "ProductViewSummaries[?Name=='AMI Transporter'].[ProductId]" --output text)
delete_count=0
provisioned_products=$(./aws servicecatalog scan-provisioned-products | /usr/bin/jq '.ProvisionedProducts')
product_count=$(echo ${provisioned_products} | /usr/bin/jq length)
echo "Checking ${product_count} provisioned products" >> $log_file
for ((count=0; count < ${product_count}; ++count)); do
  product_id=$(echo ${provisioned_products} | /usr/bin/jq -r ".[$count].ProductId")
  if [ "${product_id}" == "${ami_transporter_id}" ]; then
    creation_time=$(echo ${provisioned_products} | /usr/bin/jq ".[$count].CreatedTime" | /usr/bin/sed 's/\"//g')
    prov_product_name=$(echo ${provisioned_products} | /use/bin/jq ".[$count].Name")
    prov_product_id=$(echo ${provisioned_products} | /usr/bin/jq ".[$count].Id")
    product_ts=$(date -d "${creation_time}" +%s)
    delta=$((${epoch_ts} - ${product_ts}))
    if [ ${delta} -gt ${age} ]; then
      echo "Terminating Provisioned Product: ${prov_product_name} created ${creation_time}" >> $log_file
      ./aws servicecatalog terminate-provisioned-product --provisioned-product-name ${product_name} >/dev/null 2>&1
      if [ ${rc} -eq 0 ]; then
        echo "Termination initiated" >> $log_file
        delete_count=$(($delete_count+1))
      else
        echo "Error initiating termination: ${rc}"
      fi
    else
      echo "Ignoring provisioned AMI Transporter ${prov_product_name} created ${creation_time}" >> $log_file
    fi
    sleep 1
  fi
done
if [ ${delete_count} -gt 0 ]; then
  echo "Started termination for ${delete_count} provisioned products" >> $log_file
else
  echo "No provisioned products found for termination" >> $log_file
fi
echo -e "Done\n" >> $log_file
