#!/usr/bin/env bash
### This image is manufactured using python generate_custom_image.py ###

# sets up anaconda and jupyter
echo "************************************* SETUP ANACONDA AND JUPYTER *************************************"
rm -f /usr/local/share/google/dataproc/bdutil/components/activate/jupyter.sh
cp /opt/jupyter-custom.sh /usr/local/share/google/dataproc/bdutil/components/activate/jupyter.sh
cat >>/etc/google-dataproc/dataproc.properties <<EOF
dataproc.components.activate=anaconda
EOF
bash /usr/local/share/google/dataproc/bdutil/components/activate/anaconda.sh

# Get correct python path
echo "*************************************  SETUP PYTHON PATH *************************************"
source /etc/profile.d/effective-python.sh
source /etc/profile.d/conda.sh

# Setup conda environment with qgis
echo "*************************************  SETUP CONDA ENVIRONMENT *************************************"
conda create --name moove-dataproc conda python==3.6.10
touch /root/.bashrc
echo ". /opt/conda/anaconda/etc/profile.d/conda.sh" >> /root/.bashrc
source /etc/profile.d/conda.sh
conda activate moove-dataproc
conda install jupyterlab
conda install -c anaconda libnetcdf
conda install -c conda-forge qgis
conda install -c conda-forge pandana
ln -s /opt/conda/anaconda/envs/moove-dataproc/lib/libnetcdf.so.18 /opt/conda/anaconda/envs/moove-dataproc/lib/libnetcdf.so.15

# Install pip packages from datascience repo
echo "*************************************  INSTALLS PIP PACKAGES FROM GIT *************************************"
git clone https://GITHUB_OAUTH_TOKEN@github.com/moove-ai/moove-data-exploration.git
cd moove-data-exploration
pip install -r ./requirements.txt --ignore-installed

# Setup moove-dataproc environment for Jupyter in systemd
echo "*************************************  SETUP JUPYTER IN SYSTEMD *************************************"
env > /etc/default/jupyter
cat >> /etc/default/jupyter <<EOF
#PYSPARK_PYTHON=/opt/conda/moove-dataproc/bin/python
#SPARK_HOME=/usr/lib/spark
EOF

## Setup spark jars
echo "*************************************  SETUP SPARK JARS *************************************"
mkdir -p /usr/lib/spark/jars
gsutil cp gs://spark-lib/bigquery/spark-bigquery-latest.jar /usr/lib/spark/jars/

NODE_EXPORTER_VERSION="0.18.1"

## Setup monitoring
echo "*************************************  SETUP MONITORING *************************************"
useradd -r node_exporter
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xvfz "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/sbin/node_exporter

cat >> /etc/default/node_exporter <<EOF
OPTIONS=""
EOF

cat >> /usr/lib/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
EnvironmentFile=/etc/default/node_exporter
ExecStart=/usr/sbin/node_exporter \$OPTIONS

[Install]
WantedBy=multi-user.target
EOF

cat >> /usr/lib/systemd/system/jupyter-fix.service <<EOF
[Unit]
Description=Fixes jupyter notebook service on boot
After=network.target jupyter.service

[Service]
Type=oneshot
ExecStart=/bin/bash /opt/fixJupyter.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter.service
systemctl enable jupyter-fix.service
