#!/bin/bash

# MINIKUBE SETUP FOR DOCKER
eval $(minikube docker-env)

# PERMISSIONS AND SERVICES
# ServicAccount with correct permissions
kubectl apply -f pipelines/ci-cd/rbac.yaml
# setup servive
kubectl apply -f pipelines/ci-cd/service.yaml

# REGISTER TASKS
# setup git-clone task
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.6/git-clone.yaml
# setup show README task
kubectl apply -f tasks/show-readme.yaml
# setup kaniko-build task
kubectl apply -f tasks/build-docker-image.yaml
# setup deploy task
kubectl apply -f tasks/deploy-docker-image.yaml

# REGISTER PIPELINE
kubectl apply -f pipelines/ci-cd/pipeline.yaml

# PIPELINE TRIGGERING
# setup trigger
kubectl apply -f pipelines/ci-cd/trigger-binding.yaml
kubectl apply -f pipelines/ci-cd/trigger-template.yaml

# setup EventListener
kubectl apply -f pipelines/ci-cd/event-listener.yaml &&
kubectl wait --for=condition=ready pod -l eventlistener=github-listener --timeout=100s

# expose EventListener
kubectl port-forward service/el-github-listener 8080 &


