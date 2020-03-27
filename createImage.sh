#!/usr/bin/env bash
sed -i '.bak' 's/GITHUB_OAUTH_TOKEN/9912a49487b845d3755fe2f92df8a5f05fe0639c/g' boot_new.sh

python generate_custom_image.py \
--image-name dataproc-custom-1-4-5-anaconda-$(date +%Y%m%d%H%M) \
--dataproc-version 1.4.25-debian9 \
--customization-script $(pwd)/boot_new.sh \
--zone us-central1-b \
--gcs-bucket gs://moove-dataproc-custom \
--disk-size 100  \
--machine-type n1-standard-8

git checkout -- boot_new.sh