#!/bin/bash
# docker pull image from local registry
set -e
DockerHub="itjohn"
registry="192.168.3.150:5000"
gcr="gcr.io/google_containers"
IMAGES=(
    ${DockerHub}/pause-amd64:3.0 
    ${DockerHub}/kube-proxy-amd64:v1.8.5
)
for img in ${IMAGES[@]}; do
    docker pull $img
    gcr_name=`basename $img`
    docker tag $img $gcr/$gcr_name
    docker rmi $img
done
