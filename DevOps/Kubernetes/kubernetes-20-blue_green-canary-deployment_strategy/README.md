# Hands-on Kubernetes-20: Blue Green and Canary Deployment Strategy

The purpose of this hands-on training is to give students knowledge of Deployment Strategies.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- use Blue Green and Canary Deployment Strategies.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Blue Green and Canary Deployment Strategies

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](../kubernetes-02-basic-operations/cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node is up and running, the worker node automatically joins the cluster.*

>*Note: If you have a problem with the Kubernetes cluster, you can use this link for the lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## Part 2 - Blue Green and Canary Deployment Strategies

- A `blue/green` deployment is a deployment strategy in which you create two similar production environments (blue and green) to release software updates. At any given time, only one server is handling requests. The blue environment is running the current application version and the green environment is running the new application version. Using this method of deployment offers the ability to quickly roll back to a previous state if anything goes wrong. Once testing has been completed on the green environment, live application traffic is directed to the green environment, and the blue environment is deprecated.

- A `canary deployment` is a deployment strategy that releases an application or service incrementally to a subset of users. All infrastructure in a target environment is updated in small phases (e.g.: 2%, 25%, 75%, 100%).

- Create `yaml` file named `clarusshop-v1.yaml`.

```yaml
apiVersion: apps/v1 
kind: Deployment 
metadata:
  name: clarusshop-v1
spec:
  replicas: 4 
  selector:  
    matchLabels:
      app: clarusshop
      version: v1
  template: 
    metadata:
      labels:
        app: clarusshop
        version: v1
    spec:
      containers:
      - name: clarusshop
        image: clarusway/clarusshop:v1
        ports:
        - containerPort: 80
```

- Create the `clarusshop-v1` Deployment.
  
```bash
kubectl apply -f clarusshop-v1.yaml
```

- Check the deployment.

```bash
kubectl get deploy
```

- We create a service. Create a `clarusshop-svc.	yaml` file with the following content.

```yaml
apiVersion: v1
kind: Service   
metadata:
  name: clarusshop-svc
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30001
  selector:
    app: clarusshop
```
  
```bash
kubectl apply -f clarusshop-svc.yaml
```

- List the services.

```bash
kubectl get svc -o wide
```

- We can visit `http://<public-node-ip>:<node-port>` and access the application.

- Let's assume that we update our application and we want to deploy a new application, but we will configure the deployment in such a way that the new version will be routed 20% of traffic.

- Create `yaml` file named `clarusshop-v2.yaml`.

```yaml
apiVersion: apps/v1 
kind: Deployment 
metadata:
  name: clarusshop-v2
spec:
  replicas: 1 
  selector:  
    matchLabels:
      app: clarusshop
      version: v2
  template: 
    metadata:
      labels:
        app: clarusshop
        version: v2
    spec:
      containers:
      - name: clarusshop
        image: clarusway/clarusshop:v2
        ports:
        - containerPort: 80
```

- Create the `clarusshop-v2` Deployment.
  
```bash
kubectl apply -f clarusshop-v2.yaml
```

- Check the deployment.

```bash
kubectl get deploy
```

- Visit `http://<public-node-ip>:<node-port>` and see that the service will be routed to the new version at a portion of approximately %20.

- İncrease the replicas of `clarusshop-v2` deployment to 4. So the traffic balance will be 50-50.

- At this level, we decide that the new version of the application is ready. And, we relay full traffic to the new version.

- Change the `clarusshop-svc.yaml` as below.

```yaml
apiVersion: v1
kind: Service   
metadata:
  name: clarusshop-svc
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30001
  selector:
    version: v2 # Just this part is changed.
```

- Update the service object.

```bash
kubectl apply -f clarusshop-svc.yaml
```

- Visit `http://<public-node-ip>:<node-port>` and see that the service will be routed to the new version.

- Delete the `clarusshop-v1` deployment.

```bash
kubectl delete -f clarusshop-v1.yaml
```

> Note: These strategies are best implemented with `Service Mesh` like Istio.