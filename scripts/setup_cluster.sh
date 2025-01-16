#!/bin/bash
source .env

# SETUP LOCAL INGRESS
mkdir $MOUNT_SRC
mkdir $MOUNT_SRC/code
mkdir $MOUNT_SRC/data
mkdir $MOUNT_SRC/docker-registry
echo "Hello from the image" >> $MOUNT_SRC/data/text.txt

minikube start

# VOLUMES
minikube mount $MOUNT_SRC:/mnt &
kubectl apply -f volumes/ci-cd-volumes.yaml

# SETUP TEKTON ON CLUSTER
# Install pipelines
kubectl apply --filename \
https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# Install triggers and interceptors
kubectl apply --filename \
https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename \
https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml

# disable affinity assistant to allow multiple pvcs in one task
kubectl patch configmap feature-flags \
  -n tekton-pipelines \
  --type merge \
  -p '{"data":{"disable-affinity-assistant":"true"}}'