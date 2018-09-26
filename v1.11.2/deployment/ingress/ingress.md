K8s [official learning document](https://kubernetes.io/docs/concepts/services-networking/ingress/) learning
===   
doc   
---
```   
An API object that manages external access to the services in a cluster, typically HTTP.   
Ingress can provide load balancing, SSL termination and name-based virtual hosting.
```
```   
An Ingress is a collection of rules that allow inbound connections to reach the cluster services.
   internet
        |
   [ Ingress ]
------|-----|----------
   [ Services ]

An Ingress controller is responsible for fulfilling the Ingress, usually with a loadbalancer, though it may also configure your edge router or additional frontends to help handle the traffic in an HA manner.

Ingress Controller

NGINX Ingress Controller
```

Installation
---   

1. Mandatory:
```   
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
```

images:
quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.19.0
gcr.io/google_containers/defaultbackend:1.4

!!! attention The default configuration watches Ingress object from all the namespaces. To change this behavior use the flag --watch-namespace to limit the scope to a particular namespace.

!!! warning If multiple Ingresses define different paths for the same host, the ingress controller will merge the definitions.

2. Create ingress service (NodePort):
```
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml
```
Logs:   
```   
[root@test02 ingress]# kubectl apply -f mandatory.yaml 
namespace/ingress-nginx created
deployment.extensions/default-http-backend created
service/default-http-backend created
configmap/nginx-configuration created
configmap/tcp-services created
configmap/udp-services created
serviceaccount/nginx-ingress-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-role created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-role-nisa-binding created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-clusterrole-nisa-binding created
deployment.extensions/nginx-ingress-controller created
[root@test02 ingress]# vim mandatory.yaml 
```

3. Verify installation

```   
# nginx-ingress-controller version

# POD_NAMESPACE=ingress=nginx
# POD_NAME=$(kubectl -n $POD_NAMESPACE get pod -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
# kubectl -n $POD_NAMESPACE exec -it $POD_NAME -- /nginx-ingress-controller --version
-------------------------------------------------------------------------------
NGINX Ingress controller
  Release:    0.19.0
  Build:      git-05025d6
  Repository: https://github.com/kubernetes/ingress-nginx.git
-------------------------------------------------------------------------------
```
Testing
---
Refers to [YAML files in](https://github.com/xiaojias/k8s/tree/master/v1.11.2/deployment/ingress)

```   
# kubectl run web-nginx --image nginx --namespace=ingress-nginx
   
# kubectl expose deployment -n ingress-nginx web-nginx --port=80 --type=NodePort --name=web-nginx
service/web-nginx exposed
   
# kubectl -n ingress-nginx get service
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
...
web-nginx              NodePort    10.106.218.110   <none>        80:31800/TCP                 3m
   
# cat single-web.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-web-nginx
  namespace: ingress-nginx
spec:
  backend:
    serviceName: web-nginx
    servicePort: 80
   
# kubectl apply -f single-web.yaml
   
# kubectl -n ingress-nginx get ingress -o wide
NAME                HOSTS     ADDRESS   PORTS     AGE
ingress-web-nginx   *                   80        10m
   
There is not ADDRESS above (TBD)
   
# kubectl delete -f single-web.yaml 
ingress.extensions "ingress-web-nginx" deleted

---------------------------------------

Customize Nginx pod:

index.html is under:
/usr/share/nginx/html

[root@test02 ingress]# kubectl -n ingress-nginx get pod -o wide
NAME                                        READY     STATUS    RESTARTS   AGE       IP            NODE      NOMINATED NODE
default-http-backend-6586bc58b6-28pb2       1/1       Running   0          18h       10.244.0.23   test02    <none>
nginx-ingress-controller-6bd7c597cb-8999p   1/1       Running   0          18h       10.244.0.22   test02    <none>
web-nginx-57fd54f8f-fdknm                   1/1       Running   0          10m       10.244.0.49   test02    <none>
web-nginx-57fd54f8f-w9sxk                   1/1       Running   0          10m       10.244.0.48   test02    <none>


[root@test02 ingress]# cat /etc/hosts
# Public IP
...
10.244.0.22 foo.baz.com

[root@test02 ingress]# curl -v http://foo.baz.com/foo/index.html
* About to connect() to foo.baz.com port 80 (#0)
*   Trying 10.244.0.22...
* Connected to foo.baz.com (10.244.0.22) port 80 (#0)
> GET /foo/index.html HTTP/1.1
> User-Agent: curl/7.29.0
> Host: foo.baz.com
> Accept: */*
> 
< HTTP/1.1 200 OK
< Server: nginx/1.15.3
< Date: Wed, 19 Sep 2018 04:50:47 GMT
< Content-Type: text/html
< Content-Length: 46
< Connection: keep-alive
< Last-Modified: Wed, 19 Sep 2018 02:13:50 GMT
< ETag: "5ba1b0de-2e"
< Accept-Ranges: bytes
< 
/foo directory:
Hello from Kubernetes storage
• Connection #0 to host foo.baz.com left intact

[root@test02 ingress]# 

