# Hands-on Kubernetes-17 : Kubernetes DaemonSets, Jobs and Cronjobs

Purpose of this hands-on training is to give students the knowledge of Daemonsets, Jobs and Cronjobs.

## Learning Outcomes

At the end of the this hands-on training, students will be able to;

- explain and  DaemonSets, Jobs and CronJobs.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - DaemonSets

- Part 3 - Jobs

- Part 4 - CronJobs

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](../kubernetes-02-basic-operations/cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node up and running, worker node automatically joins the cluster.*

>*Note: If you have problem with kubernetes cluster, you can use this link for lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## Part 2 - DaemonSets

- A DaemonSet ensures that all (or some, due to taints) Nodes run a copy of a Pod. As nodes are added to the cluster, Pods are added to them. As nodes are removed from the cluster, those Pods are garbage collected. Deleting a DaemonSet will clean up the Pods it created.

- Some typical uses of a DaemonSet are:

  - running a cluster storage daemon on every node
  - running a logs collection daemon on every node
  - running a node monitoring daemon on every node

### Create a DaemonSet

- We can describe a DaemonSet in a YAML file. It is similar to ReplicaSet. We just change type of object.

- Create a yaml file and name it daemonset.yaml.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      # this toleration is to have the daemonset runnable on master nodes
      # remove it if your masters can't run pods
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

- Create the DaemonSet.

```bash
kubectl apply -f daemonset.yaml
```

- View the DaemonSets.

```bash
kubectl get DaemonSet -n kube-system
```

- Output shows that, we create pods for each node. And, we see that, kube-proxy and calico-node are also a DaemonSet.

```bash
NAME                    DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-node             2         2         2       2            2           kubernetes.io/os=linux   4m31s
fluentd-elasticsearch   2         2         2       2            2           <none>                   2m26s
kube-proxy              2         2         2       2            2           kubernetes.io/os=linux   4m34s
```

## Part 3 - Jobs

- Jobs are useful for large computation and batch-oriented tasks. Jobs can be used to support parallel execution of Pods. We can use a Job to run independent but related work items in parallel: sending emails, rendering frames, transcoding files, scanning database keys, etc. However, Jobs are not designed for closely-communicating parallel processes such as continuous streams of background processes.

- A Job creates one or more Pods and will continue to retry execution of the Pods until a specified number of them successfully terminate. As pods successfully complete, the Job tracks the successful completions. When a specified number of successful completions is reached, the task (ie, Job) is complete. Deleting a Job will clean up the Pods it created. Suspending a Job will delete its active Pods until the Job is resumed again.

- A simple case is to create one Job object in order to reliably run one Pod to completion. The Job object will start a new Pod if the first Pod fails or is deleted (for example due to a node hardware failure or a node reboot).

- Let's create a job. Create a file and name it job.yaml.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

- Run the job.

```bash
kubectl apply -f job.yaml
```

- Check on the status of the Job.

```bash
kubectl describe jobs/pi
```

- The output is similar to this:

```yaml
Name:           pi
Namespace:      default
Selector:       controller-uid=b40c1ff8-82ba-456c-8f9c-b6795a55c733
Labels:         controller-uid=b40c1ff8-82ba-456c-8f9c-b6795a55c733
                job-name=pi
Annotations:    <none>
Parallelism:    1
Completions:    1
Start Time:     Wed, 28 Apr 2021 08:26:18 +0000
Completed At:   Wed, 28 Apr 2021 08:26:48 +0000
Duration:       30s
Pods Statuses:  0 Running / 1 Succeeded / 0 Failed
Pod Template:
  Labels:  controller-uid=b40c1ff8-82ba-456c-8f9c-b6795a55c733
           job-name=pi
  Containers:
   pi:
    Image:      perl
    Port:       <none>
    Host Port:  <none>
    Command:
      perl
      -Mbignum=bpi
      -wle
      print bpi(2000)
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From            Message
  ----    ------            ----  ----            -------
  Normal  SuccessfulCreate  52s   job-controller  Created pod: pi-gqbfv
  Normal  Completed         22s   job-controller  Job completed  
```

- To view completed Pods of a Job, use kubectl get pods.

```bash
kubectl get pods
```

- View the standard output of one of the pods.

```bash
kubectl logs <pod-name>
```

- The output is similar to this.

```bash
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275901
```

- List the job.

```bash
kubectl get job
```

- Delete the job.

```bash
kubectl delete -f job.yaml
```

## Part 4 - CronJobs

- A CronJob creates Jobs on a repeating schedule.

- One CronJob object is like one line of a crontab (cron table) file. It runs a job periodically on a given schedule, written in Cron format.

> Caution:
> All CronJob schedule: times are based on the timezone of the kube-controller-manager.

- CronJobs are useful for creating periodic and recurring tasks, like running backups or sending emails. CronJobs can also schedule individual tasks for a specific time, such as scheduling a Job for when your cluster is likely to be idle.

- Let's see this. Create a yaml file and name it cronjob.yaml.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

- Create the CronJob.

```bash
kubectl apply -f cronjob.yaml
```

- List the CronJob.

```bash
kubectl get cronjob hello
```

- The output is similar to this.

```bash
NAME    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   False     0        <none>          3s
```

- As we can see from the results of the command, the cron job has not scheduled or run any jobs yet. Watch for the job to be created in around one minute.

```bash
kubectl get jobs --watch
```

- The output is similar to this.

```bash
NAME             COMPLETIONS   DURATION   AGE
hello-26993348   0/1                      0s
hello-26993348   0/1           0s         0s
hello-26993348   1/1           2s         2s
```

- Now we've seen one running job scheduled by the "hello" cron job. We can stop watching the job and view the cron job again to see that it scheduled the job.

```bash
kubectl get cronjob hello
```

- The output is similar to this.

```bash
NAME    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   False     0        30s             73s
```

- We should see that the cron job hello successfully scheduled a job at the time specified in LAST SCHEDULE. There are currently 0 active jobs, meaning that the job has completed or failed.

- Now, find the pods that the last scheduled job created and view the standard output of one of the pods.

```bash
kubectl get pod
```

Show pod log.

```bash
kubectl logs <pod-name>
```

- The output is similar to this.

```bash
Wed Apr 28 09:08:01 UTC 2021
Hello from the Kubernetes cluster
```

Delete the CronJob.

```bash
kubectl delete -f cronjob.yaml
```