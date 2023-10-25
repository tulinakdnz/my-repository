# Hands-on Kubernetes-18: Kubernetes Multiple Container Pods and Init Containers

Purpose of the this hands-on training is to give students knowledge of Multiple Container Pods.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- Learn Multiple Container Pods and Init Containers

- Learn communication between containers in a pod

- Learn to share volumes in  containers in a pod

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Multiple Container Pods

- Part 3 - Init Containers

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](./cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node is up and running, the worker node automatically joins the cluster.*

>*Note: If you have a problem with the Kubernetes cluster, you can use this link for the lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get node
```

## Part 2 - Multiple Container Pods

- A Pod can encapsulate an application composed of multiple co-located containers that are tightly coupled and need to share resources. These co-located containers form a single cohesive unit of service—for example, one container serves data stored in a shared volume to the public, while a separate sidecar container refreshes or updates those files. The Pod wraps these containers, storage resources, and an ephemeral network identity together as a single unit.

- Create a yaml file named `multi-container-pod.yaml`.  This Pod runs two Containers. The two containers share a Volume that they can use to communicate.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
  labels:
    app: two-container
spec:
  restartPolicy: Never
  volumes:
  - name: shared-data
    emptyDir: {}
  containers:
  - name: nginx-container
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: debian-container
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/sh"]
    args: ["-c", "echo Hello from the debian container > /pod-data/index.html && sleep 60 d" ]
---
apiVersion: v1
kind: Service   
metadata:
  name: two-containers-svc
spec:
  type: NodePort 
  ports:
  - port: 80 
    targetPort: 80
    nodePort: 30001
  selector:
    app: two-container
```

- In the configuration file, you can see that the Pod has a Volume named shared-data.

- The first container listed in the configuration file runs an nginx server. The mount path for the shared Volume is /usr/share/nginx/html. The second container is based on the debian image, and has a mount path of /pod-data. The second container runs the following command and then terminates.

```bash
echo Hello from the debian container > /pod-data/index.html
```

- Notice that the second container writes the index.html file in the root directory of the nginx server.

- Create the Pod and the two Containers:

```bash
kubectl apply -f multi-container-pod.yaml
```

- View information about the Pod and the Containers:

```bash
kubectl get pod two-containers --output=yaml
```

- We can visit `http://<public-node-ip>:<node-port>` and access the application. The output shows that nginx serves a web page written by the Debian container.

```
Hello from the debian container
```

- The primary reason that Pods can have multiple containers is to support helper applications that assist a primary application. Typical examples of helper applications are data pullers, data pushers, and proxies. Helper and primary applications often need to communicate with each other. Typically this is done through a shared filesystem, as shown in this exercise, or through the loopback network interface, localhost. An example of this pattern is a web server along with a helper program that polls a Git repository for new updates.

- The Volume in this exercise provides a way for Containers to communicate during the life of the Pod. If the Pod is deleted and recreated, any data stored in the shared Volume is lost.


### Python Flask and Redis example

- This time we create a Python flask app and Redis container in a pod and they communicate with each other via localhost.

- Check the `clarusway-flask-redis_image` folder and see the `app.py` file. Notice that the Flask app communicates the Redis app via localhost.

```py
app = Flask(__name__)
cache = redis.Redis(host='localhost', port=6379)
```

- Create a file named `flask-redis-pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: flask-redis
  labels:
    app: flask
spec:
  containers:
  - name: app
    image: clarusway/flask-redis
    ports:
    - containerPort: 5000
  - name: redis
    image: redis:alpine
    ports:
    - containerPort: 6379
---
apiVersion: v1
kind: Service   
metadata:
  name: flask-redis-svc
spec:
  type: NodePort 
  ports:
  - port: 5000 
    targetPort: 5000
    nodePort: 30002
  selector:
    app: flask
```

- Create the Pod and the two Containers:

```bash
kubectl apply -f flask-redis-pod.yaml
```

- View information about the Pod and the Containers:

```bash
kubectl get pod two-containers --output=yaml
```

- We can visit `http://<public-node-ip>:<node-port>` and access the application. The output shows that the flask container and Redis container can communicate with each other via localhost.

```
Hello World! I have been seen 1 times.
```

## Part 3 - Init Containers

- A Pod can have multiple containers running apps within it, but it can also have one or more init containers, which are run before the app containers are started.

- Init containers are exactly like regular containers, except:

  - Init containers always run to completion.
  - Each init container must complete successfully before the next one starts.

- If a Pod's init container fails, the kubelet repeatedly restarts that init container until it succeeds. However, if the Pod has a restartPolicy of Never, and an init container fails during the startup of that Pod, Kubernetes treats the overall Pod as failed.

- To specify an init container for a Pod, add the initContainers field into the Pod specification, as an array of container items (similar to the app containers field and its contents).

- Create a file named `init-containers.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
  labels: 
    app: init
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  # These containers are run during pod initialization
  initContainers:
  - name: install
    image: busybox:1.28
    command:
    - wget
    - "-O"
    - "/work-dir/index.html"
    - http://info.cern.ch
    volumeMounts:
    - name: workdir
      mountPath: "/work-dir"
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}
---
apiVersion: v1
kind: Service   
metadata:
  name: init-demo-svc
spec:
  type: NodePort 
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30003
  selector:
    app: init
```
- In the configuration file, you can see that the Pod has a Volume that the init container and the application container share.

- The init container mounts the shared Volume at /work-dir, and the application container mounts the shared Volume at /usr/share/nginx/html. The init container runs the following command and then terminates:

```bash
wget -O /work-dir/index.html http://info.cern.ch
```

- Notice that the init container writes the index.html file in the root directory of the nginx server.

- Create the Pod:

```bash
kubectl apply -f init-containers.yaml
```

- Verify that the nginx container is running.

```bash
kubectl get pod init-demo
```

- We can visit `http://<public-node-ip>:<node-port>` and access the application. The output is the same as the `http://info.cern.ch` page.


# References: 
https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/

https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-initialization/#create-a-pod-that-has-an-init-container