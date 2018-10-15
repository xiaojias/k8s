# API Server access - 02
Exploring API resources via verious methods.

## Using API proxy to bypass the certificate for curl command
1. Start API proxy on any node
~~~
$ kubectl proxy --api-prefix=/custom/ &
[2] 18328
[1]   Killed                  kubectl proxy --api-prefix=/custom/
$ Starting to serve on 127.0.0.1:8001

$ ps aux|grep "kubectl proxy" | grep -v grep
user01   18328  0.6  0.5  46888 21268 pts/1    Sl   15:06   0:00 kubectl proxy --api-prefix=/custom/

~~~

2. Access API server without certificate
~~~
$ curl http://127.0.0.1:8001/custom/apis/rbac.authorization.k8s.io/v1 | python -m json.tool | grep kind
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1306  100  1306    0     0  64900      0 --:--:-- --:--:-- --:--:-- 68736
    "kind": "APIResourceList",
            "kind": "ClusterRoleBinding",
            "kind": "ClusterRole",
            "kind": "RoleBinding",
            "kind": "Role",

~~~

## Exploring the resources
###Exploring available API resources via api calls
1. Get all the API groups
Get all the available groups in your api server
~~~
$ curl -s http://127.0.0.1:8001/custom/apis | python -m json.tool
...
            "name": "apps",
            "preferredVersion": {
                "groupVersion": "apps/v1",
                "version": "v1"
            },
            "versions": [
                {
                    "groupVersion": "apps/v1",
                    "version": "v1"
                },
                {
                    "groupVersion": "apps/v1beta2",
                    "version": "v1beta2"
                },
                {
                    "groupVersion": "apps/v1beta1",
                    "version": "v1beta1"
                }
            ]
...
~~~

2. Get the resources from the group
~~~
$ curl -s http://127.0.0.1:8001/custom/apis/apps/v1 | python -m json.tool
...
            "kind": "Deployment",
            "name": "deployments",
            "namespaced": true,
            "shortNames": [
                "deploy"
            ],
            "singularName": "",
            "verbs": [
                "create",
                "delete",
                "deletecollection",
                "get",
                "list",
                "patch",
                "update",
                "watch"
            ]
...
~~~

### Get current API resources from cached files
1. File of servergroups.json will be exising in following directories
~~~
$ ls ~/.kube/cache/discovery/172.31.65.91_6443/
admissionregistration.k8s.io  apps                   autoscaling          coordination.k8s.io  networking.k8s.io          scheduling.k8s.io  v1
apiextensions.k8s.io          authentication.k8s.io  batch                events.k8s.io        policy                     servergroups.json
apiregistration.k8s.io        authorization.k8s.io   certificates.k8s.io  extensions           rbac.authorization.k8s.io  storage.k8s.io

~~~
If not, try "kubectl get ep" command to retrive it

2. View the contents
~~~
$ pwd
/home/user01/.kube/cache/discovery/172.31.65.91_6443
$ cat ./v1/serverresources.json | python -m json.tool | less
...
            "kind": "ConfigMap",
            "name": "configmaps",
            "namespaced": true,
            "shortNames": [
                "cm"
            ],
            "singularName": "",
            "verbs": [
                "create",
                "delete",
                "deletecollection",
                "get",
                "list",
                "patch",
                "update",
                "watch"
            ]
...
~~~

3. Get all the objects in version 1 file
~~~
$ cat ./v1/serverresources.json | python -m json.tool | grep kind | sort -u
    "kind": "APIResourceList",
            "kind": "Binding",
            "kind": "ComponentStatus",
            "kind": "ConfigMap",
            "kind": "Endpoints",
            "kind": "Event",
            "kind": "Eviction",
            "kind": "LimitRange",
            "kind": "Namespace",
            "kind": "Node",
            "kind": "NodeProxyOptions",
            "kind": "PersistentVolume",
            "kind": "PersistentVolumeClaim",
            "kind": "Pod",
            "kind": "PodAttachOptions",
            "kind": "PodExecOptions",
            "kind": "PodPortForwardOptions",
            "kind": "PodProxyOptions",
            "kind": "PodTemplate",
            "kind": "ReplicationController",
            "kind": "ResourceQuota",
            "kind": "Scale",
            "kind": "Secret",
            "kind": "Service",
            "kind": "ServiceAccount",
            "kind": "ServiceProxyOptions",

~~~
You can view the details in file.