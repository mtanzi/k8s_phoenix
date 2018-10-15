# K8sPhoenix

K8sPhoenix is a minimal phoenix application with no _brunch_ and _Ecto_ dependencies. I wanted to keep the application simplicity at the very minimum to focus on deploy an Erlang cluster application using [Kubernetes](https://kubernetes.io/) deployment.

K8sPhoenix is configured to use (libcluster)[https://github.com/bitwalker/libcluster] which is a fantastic library that help to discover the _Kubernetes_ nodes and connect them to the Erlang cluster.

Using _Kubernetes_ we can deploy this application both on a local machine or in the cloud. In the following steps you can find the instruction to set and perform the deploy locally.

To deploy the same application in Google cloud there are few more steps to create the cloud account and to install the `gcloud` command line tool. Although the deployment commands, as they are described below, will be exactly the same.

## Local Environment

To test the _Kubernetes_ deployment we can use [Minikube](https://kubernetes.io/docs/setup/minikube/) which will start a single node inside a Virtual Machine.

#### Requirements

- [Virtual Machine](https://www.virtualbox.org/)
- [Docker](https://www.docker.com/)
- [Minikube](https://kubernetes.io/docs/setup/minikube/)

Once all the requirements are installed we can proceed to build the docker image.

Using Minikube we can build the image on the local machine, and that will work fine. Although since later we want to deploy our application in Google Cloud, we should  push the image inside a Docker Registry (either public or private). When deploying using Google Cloud the deployment procedure needs the image to be available de pull it and continue the task.
You to create a free account in [DockerHub](https://hub.docker.com/)  or alternatively you could used [Google Container Registry](https://cloud.google.com/container-registry/).


```bash
» docker build -t mtanzi/k8s-phoenix:v1 .
```

This command will build an image of the application called `mtanzi/k8s-phoenix` and tagged `v1`.

Now we can now push the image to the registry

```bash
» docker login
…
» docker push
```

To test the application we can run the container using the following command

```bash
» docker run -it --rm -p 8080:8080 -e "HOST=example.com" -e "SECRET_KEY=very-secret-key" -e "MY_BASENAME=k8s-phoenix" -e "MY_POD_IP=127.0.0.1" -e "ERLANG_COOKIE=erl-token" mtanzi/k8s-phoenix:v2
```

You can now call the health API you can see the following response.

```bash
http http://localhost:8080/api/health
HTTP/1.1 200 OK
cache-control: max-age=0, private, must-revalidate
content-length: 129
content-type: application/json; charset=utf-8
date: Mon, 15 Oct 2018 21:47:56 GMT
server: Cowboy
x-request-id: 2leucvgg23vm882gn0000011

{
    "connected_to": [],
    "hostname": "6b70fdf67b87",
    "node": "k8s-phoenix@127.0.0.1",
    "ok": "2018-10-15 21:47:56.740710Z",
    "version": "0.0.2"
}
```

The application is up and running, although the `connected_to` filed is empty. This is to be expected, in fact we started only one node, while the `connected_to` field should shows the nodes connected to the Erlang cluster.

let's start the cluster!

#### Minikube

First we need to start our _Minukube_ instance.

```bash
» minikube start
Starting local Kubernetes v1.10.0 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
```

Now we can use from console the `kubectl` commands which will help use to perform the deploy.

I have create a `Makefile` to wrap in a helper the `kubectl` instructions.

```bash
# set the `docker-env` to use the docker image inside minikube.
# eval $(minikube docker-env)
# kubectl config set-context minikube
» make prepare-minikube

# to create the production namespace where our Kubernetes  configurations will be deployed.
# kubectl -n production create -f k8s/namespace-production.yaml
» make create

# Run all the needed configurations to start the cluster.
# kubectl -n production create -f k8s/cluster_roles.yaml
# kubectl -n production create -f k8s/deployment.yaml
# kubectl -n production create -f k8s/service.yaml
# kubectl -n production create -f k8s/secrets.yaml
# kubectl -n production create configmap vm-config \
#  --from-literal=name=${MY_BASENAME}@${MY_POD_IP} \
#  --from-literal=setcookie=${ERLANG_COOKIE} \
#  --from-literal=smp=auto
» make start
```

To see if the cluster is up you can look is the service is running:

```bash
» kubectl -n production get services
NAME                  TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
k8s-phoenix-service   LoadBalancer   10.98.127.10   <pending>     80:31856/TCP   7s
```

As you can see the `EXTERNAL-IP` is on `<pending>`. in fact Minikube will not create any entrypoint. To access the cluster we can call the minikube ip `192.168.99.100` on the port defined in the service `31856`

```bash
http http://192.168.99.100:31856/api/health
HTTP/1.1 200 OK
cache-control: max-age=0, private, must-revalidate
content-length: 181
content-type: application/json; charset=utf-8
date: Mon, 15 Oct 2018 22:16:52 GMT
server: Cowboy
x-request-id: 2leug4gthscp5f38to000072

{
    "connected_to": [
        "k8s-phoenix@172.17.0.7"
    ],
    "hostname": "k8s-phoenix-deployment-68cb84f69c-2bg64",
    "node": "k8s-phoenix@172.17.0.8",
    "ok": "2018-10-15 22:16:52.133856Z",
    "version": "0.0.2"
}
```

Voilá! Our _Kubernetes_ cluster is up, running our Erlang cluster application.
You can see the ip of the node called by the request in the `node` fields and the nodes connected to the Erlang cluster in the field `connected_to` (at the moment we have only 2 nodes in the cluster).

#### Increase the Cluster size.

If we want to increase the nodes of our cluster we can change the `k8s/deployment.yaml` configuration, and set the number of `replicas` to the wanted number of nodes. Let scale up to 4

```yaml
…
spec:
  replicas: 4
…
```

The changes can will be applied running the following command.

```bash
kubectl apply -f k8s/deployment.yaml
```

If we call the API we can see that the current node is now connected to 3 more nodes.

```bash
» http http://192.168.99.100:31856/api/health
HTTP/1.1 200 OK
cache-control: max-age=0, private, must-revalidate
content-length: 232
content-type: application/json; charset=utf-8
date: Mon, 15 Oct 2018 22:34:52 GMT
server: Cowboy
x-request-id: 2leui3dnbk4ud69mr0000012

{
    "connected_to": [
        "k8s-phoenix@172.17.0.7",
        "k8s-phoenix@172.17.0.8",
        "k8s-phoenix@172.17.0.10"
    ],
    "hostname": "k8s-phoenix-deployment-68cb84f69c-rkbf7",
    "node": "k8s-phoenix@172.17.0.9",
    "ok": "2018-10-15 22:34:52.751020Z",
    "version": "0.0.2"
}
```

When you want to stop the cluster, you can use the following make command.

```bash
# kubectl -n production delete -f k8s/cluster_roles.yaml
# kubectl -n production delete -f k8s/deployment.yaml
# kubectl -n production delete -f k8s/service.yaml
# kubectl -n production delete -f k8s/secrets.yaml
# kubectl -n production delete configmap vm-config
» make stop
```
