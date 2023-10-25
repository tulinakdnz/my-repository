# Hands-on Kubernetes-21 : Admission Controllers

The purpose of this hands-on training is to give students knowledge of Admission Controllers.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- explain Admission Controllers.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Admission Controllers

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 22.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](./cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node is up and running, the worker node automatically joins the cluster.*

>*Note: If you have a problem with the Kubernetes cluster, you can use this link for the lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## part 2 - Admission Controllers

- An admission controller is a piece of code that intercepts requests to the Kubernetes API server before the persistence of the object, but after the request is authenticated and authorized.

- Admission controllers may be validating, mutating, or both. Mutating controllers may modify related objects to the requests they admit; validating controllers may not.

- Admission controllers limit requests to create, delete, and modify objects. Admission controllers can also block custom verbs, such as a request connected to a Pod via an API server proxy. Admission controllers do not (and cannot) block requests to read (get, watch, or list) objects.

     
### Admission control phases

- The admission control process proceeds in two phases. In the first phase, mutating admission controllers are run. In the second phase, validating admission controllers are run. Note again that some of the controllers are both.

- If any of the controllers in either phase reject the request, the entire request is rejected immediately and an error is returned to the end-user.


### Which plugins are enabled by default?

- To see which admission plugins are enabled:

```bash
sudo snap install kube-apiserver
kube-apiserver -h | grep enable-admission-plugins
```

- We get an output like this.

>--enable-admission-plugins strings admission plugins that should be enabled in addition to `default enabled ones (NamespaceLifecycle, LimitRanger, ServiceAccount, TaintNodesByCondition, PodSecurity, Priority, DefaultTolerationSeconds, DefaultStorageClass, StorageObjectInUseProtection, PersistentVolumeClaimResize, RuntimeClass, CertificateApproval, CertificateSigning, ClusterTrustBundleAttest, CertificateSubjectRestriction, DefaultIngressClass, MutatingAdmissionWebhook, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook, ResourceQuota)`. Comma-delimited list of admission plugins: AlwaysAdmit, AlwaysDeny, AlwaysPullImages, CertificateApproval, CertificateSigning, CertificateSubjectRestriction, ClusterTrustBundleAttest, DefaultIngressClass, DefaultStorageClass, DefaultTolerationSeconds, DenyServiceExternalIPs, EventRateLimit, ExtendedResourceToleration, ImagePolicyWebhook, LimitPodHardAntiAffinityTopology, LimitRanger, MutatingAdmissionWebhook, NamespaceAutoProvision, NamespaceExists, NamespaceLifecycle, NodeRestriction, OwnerReferencesPermissionEnforcement, PersistentVolumeClaimResize, PersistentVolumeLabel, PodNodeSelector, PodSecurity, PodTolerationRestriction, Priority, ResourceQuota, RuntimeClass, SecurityContextDeny, ServiceAccount, StorageObjectInUseProtection, TaintNodesByCondition, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook. The order of plugins in this flag does not matter.

### How do I turn on an admission controller?

- We will focus on `NamespaceAutoProvision`.

>This admission controller examines all incoming requests on namespaced resources and checks if the referenced namespace does exist. It creates a namespace if it cannot be found. This admission controller is useful in deployments that do not want to restrict the creation of a namespace before its usage.

- Let's check it. Create a pod on the `clarusway` namespace.

```bash
kubectl run nginx-pod --image nginx -n clarus
Error from server (NotFound): namespaces "clarus" not found
```

- As we see the pod wasn't created. So it is required to enable `NamespaceAutoProvision`. To enable it, we modify the `- --enable-admission-plugins=NodeRestriction` line at the  `/etc/kubernetes/manifests/kube-apiserver.yaml` file as below. 

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=172.31.72.131
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision  # Just add NamespaceAutoProvision to this line
    - --enable-bootstrap-token-auth=true
```

- Wait for restarting of the kube-apiserver. Firstly check the namespaces and notice that there isn't the `clarus` namespace, and try to create the pod again.

```bash
kubectl get ns
kubectl run nginx-pod --image nginx -n clarus
```

- This time the pod was created. And check the namespaces and see that there is the `clarus` namespace.

### How do I turn off an admission controller?

- This time we will focus on `ServiceAccount`.

> This admission controller implements automation for serviceAccounts. The Kubernetes project strongly recommends enabling this admission controller. You should enable this admission controller if you intend to make any use of Kubernetes ServiceAccount objects.

- `ServiceAccount` is a default admission controller. So we will disable it.

- Let's check the nginx-pod.

```bash
kubectl -n clarus get pod nginx-pod -o yaml | grep -i serviceaccount
  serviceAccount: default
  serviceAccountName: default
```

- As we see, when we create a pod, the default serviceaccount is assigned to the pod automatically. Now we will disable it. To disable it, we add the `- --disable-admission-plugins=ServiceAccount` line to the `/etc/kubernetes/manifests/kube-apiserver.yaml` file.  

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=172.31.72.131
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --disable-admission-plugins=ServiceAccount   # We add this line
    - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
    - --enable-bootstrap-token-auth=true
```

- Wait for restarting of the kube-apiserver.

- Create a pod. And see that there is no serviceaccount attached to this pod.

```bash
kubectl run apache-pod --image=httpd
kubectl get pod apache-pod -o yaml | grep -i serviceaccount
```

Resources:
- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/