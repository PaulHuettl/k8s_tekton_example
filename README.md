# Exemplary local kubernetes CI/CD workflow with tekton

In this repo we are creating a classical CI/CD workflow from scratch, that can be reproduced entirely locally. 

We will employ [minikube](https://kubernetes.io/de/docs/tasks/tools/install-minikube/)
to set up a basic [kubernetes](https://kubernetes.io) cluster that is able to execute [tekton](https://tekton.dev) pipelines and employ EventListeners with Interceptors.
Subsequently we build a tekton pipeline performing the following tasks:
- cloning a public GitHub repository containing a docker file
- building a deployable docker image and storing its .tar file in a local registry (no need to push to docker hub)
- create a pod on our local kubernetes cluster that runs the container as a k8s job

This pipeline runs fully automated and is triggered by a Tekton EventListener
listening to a Webhook of the GitHub repository. The Webhook will trigger the EventListener
with every push of code to the repository.

For nice introductions and more info on the used concepts see (in this order):
1. [Setting up local cluster and running a basic Tekton Task](https://tekton.dev/docs/getting-started/tasks/)
2. [Chain two tasks via a Tekton Pipeline](https://tekton.dev/docs/getting-started/pipelines/)
3. [Setting up an EventListener](https://tekton.dev/docs/getting-started/triggers/)
4. [Cloning a git repository with Tekton](https://tekton.dev/docs/how-to-guides/clone-repository/)
5. [Building a docker image with Tekton](https://tekton.dev/docs/how-to-guides/kaniko-build-push/)

## Setup Cluster

First of all fill out the template_env.env file and rename it to .env, this will set the local path to be mounted for the following tasks.

Make sure to have [minikube](https://kubernetes.io/de/docs/tasks/tools/install-minikube/)
installed and the docker daemon running on your local machine.

Now we set up our k8s cluster
```shell
bash scripts/setup_cluster.sh
```
This script sets up the local storage structure, starts minikube, mounts the volumes and configures Tekton to employ pipelines, EventListeners and Interceptors.

After execution check if all the pods are running before going to the next step via
```bash
kubectl get pods -A
```

## Setup Pipeline

Now that our cluster is successfully configured, we set up the actual CI/CD pipeline.
Therefore, execute
```bash
bash scripts/setup_ci-cd_pipeline.sh
```
This sets up the correct permissions within the cluster, defines a Service for the EventListener, registers all the Tasks present in our Pipline and composes the Pipeline.
It additionally sets up the triggering, by defining the Trigger and setting up an Eventlistener that will listen to the exposed `localhost:8080`.

## Setup Networking

So now our EventListener will be recognizing all traffic posted to `localhost:8080`.
However, the Trigger (especially `pipelines/ci-cd/trigger-binding.yaml`) requires the json body to contain certain fields emitted by a GitHub Webhook.
So in order to chain our pipeline to a Webhook we first need a way to send actual traffic to
`localhost:8080`, which is achieved via [ngrok](https://ngrok.com).

Invoking
```bash
ngrok http localhost:8080
```
will provide us with a link that can be passed to the GitHub Webhook.

## Setup Repository

Now the final step is to setup a GitHub repository.
Therefore, we provide a simple repository containing a simple python package which reads a file 
from an ingress folder. We also provide a dockerfile for deployment.

So simply create a public GitHub repo with the content of the read-file folder.
Now in the GitHub Webhook options of the repo paste the link provided by `ngrok` and make sure to set the
content type to `application/json`.

## Triggering the pipeline

Now that everything is setup we can see our CI/CD pipeline in action.
Modify the README.md of the read-file repo locally and push it.

Now monitor your kubernetes cluster via
```bash
kubectl get pods -A
```

You should see the pods appearing corresponding to the tasks contained in the pipeline, so e.g.
`ci-cd-vjnsn-fetch-source-pod`

If everything goes through, after a good minute you should see a pod `read-file-deployment-<id>`
Now log this pod via
```bash
kubectl logs read-file-deployment-<id>
```
and you will see the output `Hello from image` which is exactly the content from the mounted `.txt`.🙌

## Debugging

Useful commands for logging into your pods are
```bash
# display log
kubectl logs <your pod>
# get full info abount the pod
kubectl describe pod <your pod>
```
It can be also very beneficial to log the EventListener service `el-github-listener-<id>` in order to see
if the web traffic triggers the EventListener.

Furthermore you can look into your pipeline runs via tekton
```bash
# get an overview over pipelineruns
kubectl get pipelineruns
# get the log of a specific pipelinerun
tkn pipelinerun logs <pipelinerun>
```


