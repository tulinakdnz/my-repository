# Hands-on Kubernetes-16 : Serviceaccounts and RBAC Authorization

Purpose of this hands-on training is to give students the knowledge of serviceaccounts objects and RBAC authorization.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- explain RBAC authorization.

- use  serviceaccounts objects and RBAC objects.

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - serviceaccounts

- Part 3 - RBAC Authorization

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 22.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](./cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node up and running, worker node automatically joins the cluster.*

>*Note: If you have problem with kubernetes cluster, you can use this link for lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get no
```

## part 2 - serviceaccounts

- Kubernetes offers two distinct ways for clients that run within your cluster, or that otherwise have a relationship to your cluster's control plane to authenticate to the API server.

- A `service account` provides an identity for `processes` that run in a Pod, and maps to a `ServiceAccount` object. 

- When you authenticate to the API server, you identify yourself as a particular user. Kubernetes recognises the concept of a user, however, Kubernetes itself does not have a User API.

- When Pods contact the API server, Pods authenticate as a particular ServiceAccount (for example, default). There is always at least one ServiceAccount in each namespace.

- Every Kubernetes namespace contains at least one ServiceAccount: the default ServiceAccount for that namespace, named default. If you do not specify a ServiceAccount when you create a Pod, Kubernetes automatically assigns the ServiceAccount named default in that namespace.

- List the serviceaccounts.

```bash
kubectl get serviceaccount
kubectl get sa -A
```

- Run a pod and notice that it has a service account.

```bash
kubectl run myng --image=nginx
kubectl get pods/myng -o yaml
```

- In the output, you see a field `spec.serviceAccountName`. Kubernetes automatically sets that value if you don't specify it when you create a Pod.

- You can create additional ServiceAccount objects like this:

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mysa
EOF

- Check the serviceaccounts.

```bash
kubectl get sa
kubectl get serviceaccounts/mysa -o yaml
```

## Part 3 - RBAC Authorization

### Using RBAC Authorization

- Create a folder and name it RBAC.

```bash
mkdir RBAC && cd RBAC
```

- Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within your organization.

- RBAC authorization uses the rbac.authorization.k8s.io API group to drive authorization decisions, allowing you to dynamically configure policies through the Kubernetes API.

### API objects

- The RBAC API declares four kinds of Kubernetes object: Role, ClusterRole, RoleBinding and ClusterRoleBinding

### Role and ClusterRole

- An RBAC Role or ClusterRole contains rules that represent a set of permissions. Permissions are purely additive (there are no "deny" rules).

- A Role always sets permissions within a particular namespace; when you create a Role, you have to specify the namespace it belongs in.

- ClusterRole, by contrast, is a non-namespaced resource. The resources have different names (Role and ClusterRole) because a Kubernetes object always has to be either namespaced or not namespaced; it can't be both.

- ClusterRoles have several uses. You can use a ClusterRole to:

  - define permissions on namespaced resources and be granted access within individual namespace(s)
  - define permissions on namespaced resources and be granted access across all namespaces
  - define permissions on cluster-scoped resources

- If you want to define a role within a namespace, use a Role; if you want to define a role cluster-wide, use a ClusterRole.

### Role example

- Here's an example Role in the "default" namespace that can be used to grant read access to pods. Create a yaml file and name it as `myrole.yaml`.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

- Create the role.

```bash
kubectl apply -f myrole.yaml
kubectl get role
```

### ClusterRole example

- A ClusterRole can be used to grant the same permissions as a Role. Because ClusterRoles are cluster-scoped, you can also use them to grant access to:

  - cluster-scoped resources (like nodes)
  - non-resource endpoints (like /healthz)
  - namespaced resources (like Pods), across all namespaces

- For example: you can use a ClusterRole to allow a particular user to run kubectl get pods --all-namespaces

- Here is an example of a ClusterRole that can be used to grant read access to secrets in any particular namespace, or across all namespaces (depending on how it is bound). Create a yaml file and name it as `myclusterrole.yaml`.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: secret-reader
rules:
- apiGroups: [""]
  #
  # at the HTTP level, the name of the resource for accessing Secret
  # objects is "secrets"
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

- Create the clusterrole.

```bash
kubectl apply -f myclusterrole.yaml
kubectl get clusterrole
```

### RoleBinding and ClusterRoleBinding

- A role binding grants the permissions defined in a role to a user or set of users. It holds a list of subjects (users, groups, or service accounts), and a reference to the role being granted. A RoleBinding grants permissions within a specific namespace whereas a ClusterRoleBinding grants that access cluster-wide.

- A RoleBinding may reference any Role in the same namespace. Alternatively, a RoleBinding can reference a ClusterRole and bind that ClusterRole to the namespace of the RoleBinding. If you want to bind a ClusterRole to all the namespaces in your cluster, you use a ClusterRoleBinding.

### RoleBinding examples

- Here is an example of a RoleBinding that grants the "pod-reader" Role to the serviceaccount "default" within the "default" namespace. This allows "default serviceaccount" to read pods in the "default" namespace. Create a yaml file and name it as `myrolebinding.yaml`.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "jane" to read pods in the "default" namespace.
# You need to already have a Role named "pod-reader" in that namespace.
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
# You can specify more than one "subject"
- kind: ServiceAccount
  name: default # "name" is case sensitive
  namespace: default
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

- Before the create the `rolebinding`, create a pod and see that it doesn't have any authority to reach kubernetes cluster.

```bash
kubectl run mypod --image=clarusway/kubectl
kubectl exec -it mypod -- sh
/ # kubectl get po
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
/ # exit
```

- Create the rolebinding.

```bash
kubectl apply -f myrolebinding.yaml
kubectl get rolebinding
```

- Check the pod and see that the pod just get the pods on default namespace, but it couldn't do anything.

```bash
kubectl exec -it mypod -- sh
/ # kubectl get po
kubectl get po
NAME    READY   STATUS    RESTARTS   AGE
myng    1/1     Running   0          45m
mypod   1/1     Running   0          26m
/ # kubectl get deploy
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:default:default" cannot list resource "deployments" in API group "apps" in the namespace "default"
/ # kubectl run testpod --image=nginx
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot create resource "pods" in API group "" in the namespace "default"
/ # kubectl get po -A
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" at the cluster scope
/ # exit
```

### ClusterRoleBinding example

- To grant permissions across a whole cluster, you can use a ClusterRoleBinding. The following ClusterRoleBinding allows any user in the group "manager" to read secrets in any namespace. Create a yaml file and name it as `myclusterrolebinding.yaml`.

```bash
apiVersion: rbac.authorization.k8s.io/v1
# This cluster role binding allows anyone in the "manager" group to read secrets in any namespace.
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: ServiceAccount
  name: mysa # Name is case sensitive
  namespace: default
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

- Before the create the `clusterrolebinding`, create a different pod to check clusterrolebinding. Create a file and name it as `kubepod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubepod
spec:
  containers:
  - image: clarusway/kubectl
    name:  kubepod
  serviceAccountName: mysa
```

- Create the pod and see that it doesn't have any authority to reach kubernetes cluster.

```bash
kubectl apply -f kubepod.yaml
kubectl exec -it kubepod -- sh
/ # kubectl get po
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
/ # exit
```

- Create the clusterrolebinding.

```bash
kubectl apply -f myclusterrolebinding.yaml
kubectl get clusterrolebinding
```

- Check the pod and see that the pod get the secrets on all namespaces.

```bash
kubectl exec -it kubepod -- sh
/ # kubectl get secrets -A
/ # exit
```

> Note: In case you need a token for your service account, you can use `kubectl create token <serviceaccount>` command.

Resources:
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/