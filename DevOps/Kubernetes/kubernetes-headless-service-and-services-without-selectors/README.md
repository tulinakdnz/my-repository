# Hands-on Kubernetes-18 : ExternalService type of kubernetes services

Purpose of the this hands-on training is to give students the knowledge of Headless service of kubernetes.

## Learning Outcomes

At the end of the this hands-on training, students will be able to;

- Understand the Headless service of kubernetes.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Outline of the multi-container docker applications

- Part 3 - Deployments and Services

- Part 4 - Secrets and ConfigMaps

- Part 5 - Volumes

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](../kubernetes-02-basic-operations/cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node up and running, worker node automatically joins the cluster.*

>*Note: If you have problem with kubernetes cluster, you can use this link for lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## Part 2 - Outline of the multi-container docker applications

- Examine the `to-do-api.py`, `Dockerfile` and `docker-compose.yaml` files in `docker-compose` folder. Notice that there are two microservices: `database` is created from mysql:5.7 image and `myapp` is builded with `Dockerfile.` 

```yaml
version: "3.8"

services:
    database:
        image: mysql:5.7
        environment:
            MYSQL_ROOT_PASSWORD: R1234r
            MYSQL_DATABASE: todo_db
            MYSQL_USER: clarusway
            MYSQL_PASSWORD: Clarusway_1
        networks:
            - clarusnet
    myapp:
        build: .
        depends_on:
            - database
        restart: always
        ports:
            - "80:80"
        networks:
            - clarusnet

networks:
    clarusnet:
        driver: bridge
```

## Part 3 - Deployments and Services

- We need two images and we have just one that is mysql:5.7. So we build the other one. Firstly we change to-do-api.py file to get `MYSQL variables` from environment variables instead of py file.

- We just change the below statement ...

```py
# Import Flask modules
from flask import Flask, jsonify, abort, request, make_response
from flaskext.mysql import MySQL

# Create an object named app
app = Flask(__name__)

# Configure mysql database
app.config['MYSQL_DATABASE_HOST'] = 'database'
app.config['MYSQL_DATABASE_USER'] = 'clarusway'
app.config['MYSQL_DATABASE_PASSWORD'] = 'Clarusway_1'
app.config['MYSQL_DATABASE_DB'] = 'todo_db'
```

- ... with this one below. Owing to `os` module we can get `MYSQL variables` from environment variable. Thanks to this, we do not need to change image even if `MYSQL variables` changes.

```py
# Import Flask modules
from flask import Flask, jsonify, abort, request, make_response
from flaskext.mysql import MySQL
import os

# Create an object named app
app = Flask(__name__)

# Configure mysql database
app.config['MYSQL_DATABASE_HOST'] = os.getenv('MYSQL_DATABASE_HOST')
app.config['MYSQL_DATABASE_USER'] = os.getenv('MYSQL_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = os.getenv('MYSQL_PASSWORD')
app.config['MYSQL_DATABASE_DB'] = os.getenv('MYSQL_DATABASE')
```

- Build the image and push it to dockerhub.

```bash
docker build -t clarusways/todoapi-pod .
docker push clarusways/todoapi-pod
```


- Create a file and name it todoapi-kubernetes.

```bash
mkdir todoapi-kubernetes && cd todoapi-kubernetes
```

- Create a deployment for database microservice and name it `db-clarus-deploy.yaml` 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: clarus-db-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: clarus-db
  template:
    metadata:
      labels:
        app: clarus-db
    spec:
      containers:
      - name: clarus-db
        image: mysql:5.7
        ports:
        - containerPort: 3306
        env:
          - name: MYSQL_ROOT_PASSWORD
            value: R1234r
          - name: MYSQL_DATABASE
            value: todo_db
          - name: MYSQL_USER
            value: clarusway
          - name: MYSQL_PASSWORD
            value: Clarusway_1
```

- Run the `clarus-db-deploy` and list it.

```bash
kubectl apply -f db-clarus-deploy.yaml
kubectl get po -o wide
```

> Note the Ip adress for endpoint of db-service.

### Headless Services

- Sometimes you don't need load-balancing and a single Service IP. In this case, you can create what are termed "headless" Services, by explicitly specifying "None" for the cluster IP (.spec.clusterIP).

- You can use a headless Service to interface with other service discovery mechanisms, without being tied to Kubernetes' implementation.

- For headless Services, a cluster IP is not allocated, kube-proxy does not handle these Services, and there is no load balancing or proxying done by the platform for them. How DNS is automatically configured depends on whether the Service has selectors defined

- Create a headless service for database and name it `db-clarus-service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: clarus-db-service
  labels:
    name: clarus-db-service
spec:
  clusterIP: None
```

- Run the `clarus-db-service` and list it.

```bash
kubectl apply -f db-clarus-service.yaml
kubectl get svc
```

- It is required to create endpoint for clarus-db-service. Because it is headless. Create an endpoint for clarus-db-service and name it `db-clarus-service-endpoint.yaml`.

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: clarus-db-service
subsets:
  - addresses:
      - ip: 172.18.0.4 # This is ip adress of database pod.
    ports:
      - port: 3306
```

- Run the `clarus-db-service-endpoint.yaml` and list it.

```bash
kubectl apply -f db-clarus-service.yaml
kubectl get endpoints
```

- Create a deployment for todoapi-pod microservice and name it `todoapi-deploy.yaml`. Pay attention to environment variables. We pass this variables to our to-do-api.py.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-api-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: todo-api
  template:
    metadata:
      labels:
        app: todo-api
    spec:
      containers:
      - name: todo-api
        image: clarusways/todoapi-pod
        ports:
        - containerPort: 80
        env:
          - name: MYSQL_DATABASE_HOST
            value: clarus-db-service
          - name: MYSQL_DATABASE
            value: todo_db
          - name: MYSQL_USER
            value: clarusway
          - name: MYSQL_PASSWORD
            value: Clarusway_1
```

- Run the `todo-api-deploy` and list it.

```bash
kubectl apply -f todoapi-deploy.yaml
kubectl get po
```

- Create a service for todoapi-pod microservice and name it `todoapi-service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: todoapi-service
  labels:
    name: todo-api
spec:
  type: NodePort
  selector:
    app: todo-api
  ports:
  - port: 8080
    targetPort: 80
    nodePort: 30001
```

- Run the `todoapi-service` and list it.

```bash
kubectl apply -f todoapi-service.yaml
kubectl get svc
```

- List the pods and services.

```bash
kubectl get po,svc
```

- Do not forget to open port 30001. Then in a browser check your work:
`http://<your ec2 instances public IP>30001`

- Delete all pods and services.

```bash
kubectl delete -f .
```