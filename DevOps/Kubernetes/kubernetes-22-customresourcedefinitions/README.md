# Hands-on Kubernetes-22 : Extend the Kubernetes API with CustomResourceDefinitions

Purpose of the this hands-on training is to give students the knowledge of CustomResourceDefinitions in Kubernetes cluster.

## Learning Outcomes

At the end of the this hands-on training, students will be able to;

- explain custom resources

- how to install a custom resource into the Kubernetes API by creating a CustomResourceDefinition

## Outline

- Part 1 - Setting up the Kubernetes Cluster

- Part 2 - Extend the Kubernetes API with CustomResourceDefinitions

## Part 1 - Setting up the Kubernetes Cluster

- Launch a Kubernetes Cluster of Ubuntu 20.04 with two nodes (one master, one worker) using the [Cloudformation Template to Create Kubernetes Cluster](./cfn-template-to-create-k8s-cluster.yml). *Note: Once the master node up and running, worker node automatically joins the cluster.*

>*Note: If you have problem with kubernetes cluster, you can use this link for lesson.*
>https://killercoda.com/playgrounds

- Check if Kubernetes is running and nodes are ready.

```bash
kubectl cluster-info
kubectl get node
```

## Part 2 - Extend the Kubernetes API with CustomResourceDefinitions

### Custom resources

- A resource is an endpoint in the Kubernetes API that stores a collection of API objects of a certain kind; for example, the built-in pods resource contains a collection of Pod objects.

- A custom resource is an extension of the Kubernetes API that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.

- Custom resources can appear and disappear in a running cluster through dynamic registration, and cluster admins can update custom resources independently of the cluster itself. Once a custom resource is installed, users can create and access its objects using kubectl, just as they do for built-in resources like Pods.

### Custom controllers

- On their own, custom resources let you store and retrieve structured data. When you combine a custom resource with a custom controller, custom resources provide a true declarative API.

- The Kubernetes declarative API enforces a separation of responsibilities. You declare the desired state of your resource. The Kubernetes controller keeps the current state of Kubernetes objects in sync with your declared desired state. This is in contrast to an imperative API, where you instruct a server what to do.

- You can deploy and update a custom controller on a running cluster, independently of the cluster's lifecycle. Custom controllers can work with any kind of resource, but they are especially effective when combined with custom resources. The Operator pattern combines custom resources and custom controllers. You can use custom controllers to encode domain knowledge for specific applications into an extension of the Kubernetes API.

### CustomResourceDefinitions

-  The CustomResourceDefinition API resource allows you to define custom resources. Defining a CRD object creates a new custom resource with a name and schema that you specify. The Kubernetes API serves and handles the storage of your custom resource. The name of a CRD object must be a valid DNS subdomain name.

- Let's say that we have an tourism company. We have an application to book reservations. And, we want to use this application with the kubernetes cluster. We want to create an object as below. Create a file named myreservation.yaml.

```yaml
apiVersion: "clarusway.com/v1"
kind: BookReservation
metadata:
  name: hotel-reservation
spec:
  hotel: "hotelclarus"
  date: "01.07.2023-31.07.2023"
  count: 40
```

- The object name is BookReservation and the API version is clarusway.com/v1. We will name it hotel-reservation. There are three fields. The hotel name, the date, and the client count. When we create this object, we want to have a BookReservation resource created, and when we list all BookReservation,  we want all BookReservations to be listed, and when we delete a BookReservation, BookReservation resource to be deleted. How are we going to do this? When we create this resource, it is going to create or delete the BookReservation object in the etcd data store, but it's not going to book a reservation. We want this to go out and book a reservation for real. For instance, there is an API available bookreservation.com/api that we can call to book a reservation. So, how do we call this API whenever we create a BookReservation object to book a flight ticket? So, for that, we're going to need a controller. So, we will create a  Book Reservation custom controller. When we create a BookReservation resource, it will contact the book reservation API to book hotel reservations. How are we going to this? Let's try to create a BookReservation resource.

```bash
kubectl apply -f myreservation.yaml
```

- We get an output like this.

```bash
error: unable to recognize "myreservation.yaml": no matches for kind "BookReservation" in version "clarusway.com/v1"
```

- There are no matches for the kind BookReservation in version clarusway.com/v1. This is because we can't simply create any resource that we want without configuring it in the Kubernetes API. We have to create custom resource definition, or CRD. 

- When we create a new CustomResourceDefinition (CRD), the Kubernetes API Server creates a new RESTful resource path for each version we specify. The custom resource created from a CRD object can be either namespaced or cluster-scoped, as specified in the CRD's spec.scope field. Create a file named myresourcedefinition.yaml.

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: bookreservations.clarusway.com
spec:
  # group name to use for REST API: /apis/<group>/<version>
  group: clarusway.com
  # list of versions supported by this CustomResourceDefinition
  versions:
    - name: v1
      # Each version can be enabled/disabled by Served flag.
      served: true
      # One and only one version must be marked as the storage version.
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                hotel:
                  type: string
                date:
                  type: string
                count:
                  type: integer
  # either Namespaced or Cluster
  scope: Namespaced
  names:
    # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    plural: bookreservations
    # singular name to be used as an alias on the CLI and for display
    singular: bookreservation
    # kind is normally the CamelCased singular type. Your resource manifests use this.
    kind: BookReservation
    # shortNames allow shorter string to match your resource on the CLI
    shortNames:
    - br
```

- and create it:

```bash
kubectl apply -f resourcedefinition.yaml
```

- Then a new namespaced RESTful API endpoint is created at:

```bash
/apis/clarusway.com/v1/namespaces/*/bookreservations/...
```

- To test execute the following commands.

```bash
kubectl proxy localhost --port=8080
# open a new terminal
curl localhost:808/apis/clarusway.com/v1/namespaces/*/bookreservationss
```

- This endpoint URL can then be used to create and manage custom objects. The kind of these objects will be BookReservation from the spec of the CustomResourceDefinition object we created above.

- After the CustomResourceDefinition object has been created, we can create custom objects.

```bash
kubectl apply -f myreservation.yaml
```

- We can then manage your CronTab objects using kubectl. For example:

```bash
kubectl get bookreservation
```

Should print a list like this:

```bash
NAME                AGE
hotel-reservation   9m57s
```

- We can also view the raw YAML data:

``bash
kubectl get br -o yaml
```

- We should see that it contains the custom hotel, date, and count fields from the YAML we used to create it:

```yaml
apiVersion: v1
items:
- apiVersion: clarusway.com/v1
  kind: BookReservation
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"clarusway.com/v1","kind":"BookReservation","metadata":{"annotations":{},"name":"hotel-reservation","namespace":"default"},"spec":{"count":40,"date":"01.07.2023-31.07.2023","hotel":"hotelclarus"}}
    creationTimestamp: "2023-06-30T16:35:02Z"
    generation: 1
    name: hotel-reservation
    namespace: default
    resourceVersion: "86553"
    uid: eb81d3a3-75b7-4779-b289-f16f80c89ab1
  spec:
    count: 40
    date: 01.07.2023-31.07.2023
    hotel: hotelclarus
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

- When we delete a CustomResourceDefinition, the server will uninstall the RESTful API endpoint and delete all custom objects stored in it.

```bash
kubectl delete -f myresourcedefinition.yaml
kubectl get bookreservation
```

- We get an output like below.


```bash
Error from server (NotFound): Unable to list "clarusway.com/v1, Resource=bookreservations": the server could not find the requested resource (get bookreservations.clarusway.com)
```

- If we later recreate the same CustomResourceDefinition, it will start out empty.