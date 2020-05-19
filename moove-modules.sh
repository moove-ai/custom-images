#!/usr/bin/env bash

source /etc/profile.d/conda.sh
conda activate moove-dataproc

GITHUB_OAUTH_TOKEN=$(gcloud --project moove-platform-staging beta secrets versions access latest --secret github_oauth_token)

git clone https://$GITHUB_OAUTH_TOKEN@github.com/moove-ai/moove-modules.git
cd moove-modules
cp modules/* /opt/conda/anaconda/envs/moove-dataproc/lib/python3.6/site-packages/moovemodules
pip install -r ./requirements.txt --ignore-installed
