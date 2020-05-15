#!/usr/bin/env bash

conda activate moove-dataproc
env > /etc/default/jupyter
systemctl restart jupyter
