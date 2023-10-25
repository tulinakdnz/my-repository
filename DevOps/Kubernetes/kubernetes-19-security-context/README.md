# Hands-on Kubernetes-19 : Kubernetes Security Context

Purpose of this hands-on training is to give students the knowledge of security context.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- Learn security context.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Docker Security

- Part 3 - Configure a Security Context for a Pod or Container

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](../kubernetes-02-basic-operations/cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node up and running, worker node automatically joins the cluster.*

>*Note: If you have problem with kubernetes cluster, you can use this link for lesson.*
>https://www.katacoda.com/courses/kubernetes/playground

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## part 2 - Docker Security

- The containers and the docker Host instance use same kernel. When you start a container with docker run, behind the scenes Docker creates a set of namespaces for the container. Namespaces provide the first and most straightforward form of isolation: processes running within a container cannot see, and even less affect, processes running in another container, or in the host system. Thanks to this, Docker isolates containers within a system.
When you list the processes within the Docker container, you see a Process id. For the Docker host, you will see the same process but with different process id. Because docker host, see all processes of its own namespace and in the child namespaces are.

- Let's see this. Execute the following command.

```bash
docker run -d --name firstcon alpine sleep 600
docker exec firstcon ps
```

- We will get an output like this.

```bash
PID   USER     TIME  COMMAND
    1 root      0:00 sleep 600
    7 root      0:00 ps
```

- As we see, the PID of sleep command is `1`.

- Execute the following command.

```bash
ps -aux
```

- We will get an output like this.

```bash
root       39015  0.0  0.0   1608     4 ?        Ss   13:24   0:00 sleep 600
```

- As we see, the PID of sleep command is different from inside the container. And, we also notice that `user` of sleep command is `root`.

- By default, a Docker Container runs as a Root user. This poses a great security threat. We can switch to a different user using `--user` option. Let's see.

```bash
docker run  alpine whoami
root
docker run  --user=405 alpine whoami
guest
docker run  --user=guest alpine whoami
guest
```

- But, the best practice is to change the user in a Dockerfile using the `USER` Instruction. For this, we need to create a user and a group inside the Container and thhen use `USER` instruction.

- Create a `Dockerfile`

```Dockerfile
FROM ubuntu:latest
RUN apt-get -y update
RUN groupadd -r clarus && useradd -r -g clarus clarus
USER clarus
```

- Build the docker image.

```bash
docker build -t user-image .
```

- Run the following command.

```bash
docker run user-image whoami && id
clarus
uid=1000(james) gid=1000(james) groups=1000(james),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),108(kvm),120(lpadmin),131(lxd),132(sambashare),997(docker) Linux kernel capabilities
```

### Linux kernel capabilities

- By default, Docker starts containers with a restricted set of capabilities.

- Typical servers run several processes as root, including the SSH daemon, cron daemon, logging daemons, kernel modules, network configuration tools, and more. To see full list exucute the following command.

```bash
sudo cat /usr/include/linux/capability.h
```

- A container is different, because almost all of those tasks are handled by the infrastructure around the container.

- This means that in most cases, containers do not need “real” root privileges at all. And therefore, containers can run with a reduced capability set; meaning that “root” within a container has much less privileges than the real “root”.

- This means that even if an intruder manages to escalate to root within a container, it is much harder to do serious damage, or to escalate to the host.

- First, see what happens when we run a docker container.

```bash
docker run -it ubuntu bash
```

- In your shell, list the running processes:

```bash
ps aux
```

- The output shows the process IDs (PIDs) for the Container:

```bash
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.1  0.0   4624  3500 pts/0    Ss   20:41   0:00 bash
root           9  0.0  0.0   7060  1552 pts/0    R+   20:41   0:00 ps aux
```

- In your shell, view the status for process 1:

```bash
cd /proc/1
cat status
```

- The output shows the capabilities bitmap for the process:

```bash
...
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
...
```

- Make a note of the capabilities bitmap, and then exit your shell:

```bash
exit
```

- Next, run a Container that is the same as the preceding container, except that it has additional capabilities set.

```bash
docker run --cap-add "NET_ADMIN" --cap-add "SYS_TIME" -it ubuntu bash
```

- In your shell, view the capabilities for process 1:

```bash
cd /proc/1
cat status
```

- The output shows capabilities bitmap for the process:

```bash
...
CapPrm:	00000000aa0435fb
CapEff:	00000000aa0435fb
...
```

- Compare the capabilities of the two Containers:

```bash
00000000a80425fb
00000000aa0435fb
```

- In the capability bitmap of the first container, bits 12 and 25 are clear. In the second container, bits 12 and 25 are set. Bit 12 is `CAP_NET_ADMIN`, and bit 25 is `CAP_SYS_TIME`. See [capability.h](https://github.com/torvalds/linux/blob/master/include/uapi/linux/capability.h) for definitions of the capability constants.


## Part 3 - Configure a Security Context for a Pod or Container

- A security context defines privilege and access control settings for a Pod or Container.

- To specify security settings for a Pod, include the securityContext field in the Pod specification. The securityContext field is a PodSecurityContext object. The security settings that you specify for a Pod apply to all Containers in the Pod. Here is a configuration file for a Pod that has a securityContext and an emptyDir volume. Crate a file named `security-context.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox:1.28
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      allowPrivilegeEscalation: false
```

- In the configuration file, the runAsUser field specifies that for any Containers in the Pod, all processes run with user ID 1000. The runAsGroup field specifies the primary group ID of 3000 for all processes within any containers of the Pod. If this field is omitted, the primary group ID of the containers will be root(0). Any files created will also be owned by user 1000 and group 3000 when runAsGroup is specified. Since fsGroup field is specified, all processes of the container are also part of the supplementary group ID 2000. The owner for volume /data/demo and any files created in that volume will be Group ID 2000.

Create the Pod:

```bash
kubectl apply -f security-context.yaml
```

- Verify that the Pod's Container is running:

```bash
kubectl get pod security-context-demo
```

- Get a shell to the running Container:

```bash
kubectl exec -it security-context-demo -- sh
#In your shell, list the running processes:
ps
```

- The output shows that the processes are running as user 1000, which is the value of runAsUser:

```bash
PID   USER     TIME  COMMAND
    1 1000      0:00 sleep 1h
    6 1000      0:00 sh
...
```

- In your shell, navigate to `/data`, and list the one directory:

```bash
cd /data
ls -l
```

- The output shows that the `/data/demo` directory has group ID 2000, which is the value of fsGroup.

```bash
drwxrwsrwx 2 root 2000 4096 Jun  6 20:08 demo
```

- In your shell, navigate to `/data/demo`, and create a file:

```bash
cd demo
echo hello > testfile
```

- List the file in the `/data/demo` directory:

```bash
ls -l
```

- The output shows that testfile has group ID 2000, which is the value of fsGroup.

```bash
-rw-r--r-- 1 1000 2000 6 Jun  6 20:08 testfile
```

- Run the following command:

```bash
id
```

- The output is similar to this:

```bash
uid=1000 gid=3000 groups=2000
```

- From the output, you can see that gid is 3000 which is same as the runAsGroup field. If the runAsGroup was omitted, the gid would remain as 0 (root) and the process will be able to interact with files that are owned by the root(0) group and groups that have the required group permissions for the root (0) group.

Exit your shell:

```bash
exit
```

### Set the security context for a Container

- To specify security settings for a Container, include the securityContext field in the Container manifest. The securityContext field is a SecurityContext object. Security settings that you specify for a Container apply only to the individual Container, and they override settings made at the Pod level when there is overlap. Container settings do not affect the Pod's Volumes.

- Here is the configuration file for a Pod that has one Container. Both the Pod and the Container have a securityContext field.  Create a file named `security-context-2.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-2
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: sec-ctx-demo-2
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
```

- Create the Pod:

```bash
kubectl apply -f security-context-2.yaml
```

- Verify that the Pod's Container is running:

```bash
kubectl get pod security-context-demo-2
```

- Get a shell into the running Container:

```bash
kubectl exec -it security-context-demo-2 -- sh
```

- In your shell, list the running processes:

```bash
ps aux
```

- The output shows that the processes are running as user 2000. This is the value of runAsUser specified for the Container. It overrides the value 1000 that is specified for the Pod.

```bash
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
2000         1  0.0  0.0   4336   764 ?        Ss   20:36   0:00 /bin/sh -c node server.js
2000         8  0.1  0.5 772124 22604 ?        Sl   20:36   0:00 node server.js
...
```

- Exit your shell:

```bash
exit
```

### Set capabilities for a Container

- With Linux capabilities, you can grant certain privileges to a process without granting all the privileges of the root user. To add or remove Linux capabilities for a Container, include the capabilities field in the securityContext section of the Container manifest.

- First, see what happens when you don't include a capabilities field. Here is configuration file that does not add or remove any Container capabilities.  Create a file named `security-context-3.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-3
spec:
  containers:
  - name: sec-ctx-3
    image: gcr.io/google-samples/node-hello:1.0
```

- Create the Pod.

```bash
kubectl apply -f security-context-3.yaml
```

- Verify that the Pod's Container is running:

```bash
kubectl get pod security-context-demo-3
```

- Get a shell into the running Container:

```bash
kubectl exec -it security-context-demo-3 -- sh
```

- In your shell, list the running processes:

```bash
ps aux
```

- The output shows the process IDs (PIDs) for the Container:

```bash
USER  PID %CPU %MEM    VSZ   RSS TTY   STAT START   TIME COMMAND
root    1  0.0  0.0   4336   796 ?     Ss   18:17   0:00 /bin/sh -c node server.js
root    5  0.1  0.5 772124 22700 ?     Sl   18:17   0:00 node server.js
```

- In your shell, view the status for process 1:

```bash
cd /proc/1
cat status
```

- The output shows the capabilities bitmap for the process:

```bash
...
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
...
```

- Make a note of the capabilities bitmap, and then exit your shell:

```bash
exit
```

- Next, run a Container that is the same as the preceding container, except that it has additional capabilities set.

Here is the configuration file for a Pod that runs one Container. The configuration adds the `CAP_NET_ADMIN` and `CAP_SYS_TIME` capabilities. Create a file named `security-context-4.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-4
spec:
  containers:
  - name: sec-ctx-4
    image: gcr.io/google-samples/node-hello:1.0
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
```

- Create the Pod:

```bash
kubectl apply -f https://k8s.io/examples/pods/security/security-context-4.yaml
```

- Get a shell into the running Container:

```bash
kubectl exec -it security-context-demo-4 -- sh
```

- In your shell, view the capabilities for process 1:

```bash
cd /proc/1
cat status
```

- The output shows capabilities bitmap for the process:

```bash
...
CapPrm:	00000000aa0435fb
CapEff:	00000000aa0435fb
...
```

- Compare the capabilities of the two Containers:

```bash
00000000a80425fb
00000000aa0435fb
```

- In the capability bitmap of the first container, bits 12 and 25 are clear. In the second container, bits 12 and 25 are set. Bit 12 is `CAP_NET_ADMIN`, and bit 25 is `CAP_SYS_TIME`. See [capability.h](https://github.com/torvalds/linux/blob/master/include/uapi/linux/capability.h) for definitions of the capability constants.

> Note: Linux capability constants have the form CAP_XXX. But when you list capabilities in your container manifest, you must omit the CAP_ portion of the constant. For example, to add CAP_SYS_TIME, include SYS_TIME in your list of capabilities.


References:

https://kubernetes.io/docs/tasks/configure-pod-container/security-context/