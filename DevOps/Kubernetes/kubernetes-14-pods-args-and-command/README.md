# Hands-on Kubernetes-14 : args & command fields of a pod

Purpose of this hands-on training is to give students the knowledge of args & command fields of a pod.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- Learn args & command fields of a pod.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Difference between `CMD` and `ENTRYPOINT` fields of a Docker image

- Part 3 - args & command fields of a pod

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](../kubernetes-02-basic-operations/cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node up and running, worker node automatically joins the cluster.*

>*Note: If you have problem with kubernetes cluster, you can use this link for lesson.*
>https://www.katacoda.com/courses/kubernetes/playground

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## part 2 - Difference between `CMD` and `ENTRYPOINT` fields of a Docker image

- Create a folder and name it pod-args-command.

```bash
mkdir pod-args-command && cd pod-args-command
```

- Firstly, we remember difference between `CMD` and `ENTRYPOINT` fields of a Dockerfile. Create a Dockerfile and input following statements.

```Dockerfile
FROM ubuntu
CMD [ "echo", "hello" ]
```

- Build an image from this Dockerfile and tag it as "cmd".

```bash
docker build -t cmd .
```

- Run `cmd` image.

```bash
docker run cmd
```

The output:

```bash
hello
```

- Now, run `cmd` image with ls command.

```bash
docker run cmd ls
```

- This time it displays the list of roout folder.

- Change the CMD line to ENTRYPOINT line in Dockerfile as below.

```Dockerfile
FROM ubuntu
ENTRYPOINT [ "echo", "hello" ]
# CMD [ "echo", "hello" ]
```

- Build an image from this Dockerfile and tag it as "entrypoint".

```bash
docker build -t entrypoint .
```

- Run `entrypoint` image.

```bash
docker run entrypoint Alex
```

The output:
```bash
hello Alex
```

- Run `entrypoint` image with ls command.

```bash
docker run entrypoint ls
```

The output:
```bash
hello ls
```

- Notice that we couldn't execute ls command. Because, unlike `CMD`, we can't override `ENTRYPOINT`.

> We can change entrypoint with --entrypoint tag.
>```bash
>docker run --entrypoint sleep entrypoint 3
>```


### Use `CMD` instruction as a parameter of `ENTRYPOINT` instruction

- Change Dockerfile as below.

```Dockerfile
FROM ubuntu
ENTRYPOINT [ "sleep" ]
CMD [ "3" ]
```

- Build an image from this Dockerfile and tag it as "entrypoint-cmd".

```bash
docker build -t entrypoint-cmd .
```

- Run the `entrypoint-cmd` image.

```bash
docker run entrypoint-cmd
```

- Now, run the `entrypoint-cmd` image as Below.

```bash
docker run entrypoint-cmd 7
```

- Notice that we can override `CMD` instruction but we can not override `ENTRYPOINT` instruction.

## Part 3 - args & command fields of a pod

- We will create a pod and use args and command fields.

- Create a yaml file and name it `pod-args-commands.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: args-commands
  labels:
    app: args-commands
spec:
  containers:
  - name: args-commands
    image: clarusway/entrypoint-cmd
    command: ["sleep"]  # This overwrites ENTRYPOINT in Dockerfile. 
    args: ["10"]  # This overwrites CMD in Dockerfile
    env:
    - name: firstkey
      value: "firstvalue"
    - name: secondkey
      value: "secondvalue"
```

> Note: `command` field in a pod object overwrites `ENTRYPOINT` in Dockerfile, and `args` field overwrites CMD in Dockerfile.

> Note: We don't change sleep command to make it easy to understand. So, in our case `command` field is `ineffective`. But, if we want to change `ENTRYPOINT field in Dockerfile`, we can change it with `command field of a pod`. 

- Execute the pod.

```bash
kubectl apply -f pod-args-commands.yaml
```

- After execute this command, pod will run for 10 seconds instead of 3 seconds.