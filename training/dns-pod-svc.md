# DNS for pod and service (test with deployment involved)
- Create pods from deployment;
- Test for both general service and Headless service;
- Test for both pod and service;
- Refers to [Kubernetes doc](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).


## Environment:
~~~
[root@test01 dns-svc-pod]# kubectl version
Client Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.1", GitCommit:"4ed3216f3ec431b140b1d899130a69fc671678f4", GitTreeState:"clean", BuildDate:"2018-10-05T16:46:06Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.1", GitCommit:"4ed3216f3ec431b140b1d899130a69fc671678f4", GitTreeState:"clean", BuildDate:"2018-10-05T16:36:14Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
~~~
- Set pod.spec.subdomain as same as the service name; 
- Set service.ports.name;

## Miscellaneous
### For General Service
The Pods are created, and with hostname and subdomain set. ( The subdomain must equal to service name, otherwise, the pods'ip can not be resolved for my-hostname.my-subdomain.my-namespace.svc.cluster.local). refers to YAML file file of [nginx-dns-svc-with-deploy.yaml](https://github.com/xiaojias/k8s/tree/master/training/yamls/nginx-dns-svc-with-deploy.yaml).

Output of YAML file creation:
~~~
[root@test01 dns-svc-pod]# kubectl get svc,ep,pods -o wide -l app=dns-testing
NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/nginx-svc   ClusterIP   10.100.188.115   <none>        80/TCP    60s   run=nginx-svc

NAME                  ENDPOINTS                         AGE
endpoints/nginx-svc   10.244.0.110:80,10.244.0.111:80   60s

NAME                            READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE
pod/nginx-svc-d974969dc-88tf5   1/1     Running   0          4s    10.244.0.111   test01   <none>
pod/nginx-svc-d974969dc-zp82p   1/1     Running   0          60s   10.244.0.110   test01   <none>
~~~

Results of nslookup:
1. Pods FQDN name: my-hostname.my-subdomain.my-namespace.svc.cluster.local is resolved to the set of Pod IPs as below:
~~~
/ # nslookup nginx.nginx-svc.default.svc.cluster.local
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx.nginx-svc.default.svc.cluster.local
Address 1: 10.244.0.110 nginx.nginx-svc.default.svc.cluster.local
Address 2: 10.244.0.111 nginx.nginx-svc.default.svc.cluster.local
~~~

2. Service A & SRV records work clearly as official document as below:
~~~
/ # nslookup nginx-svc
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx-svc
Address 1: 10.100.188.115 nginx-svc.default.svc.cluster.local
/ # nslookup _http._tcp.nginx-svc
Server:    10.96.0.10
~~~

3. Pod's A Record works as below:
~~~
/ # nslookup 10-224-0-110.default.pod
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10-224-0-110.default.pod
Address 1: 10.224.0.110
/ # nslookup 10-224-0-110.default.pod.cluster.local
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10-224-0-110.default.pod.cluster.local
Address 1: 10.224.0.110
~~~

works for another pod as well.

## For Headless Service
Repeat above testings for Headless Service with YAML file of [nginx-dns-svc-headless-with-deploy.yaml](https://github.com/xiaojias/k8s/tree/master/training/yamls/nginx-dns-svc-headless-with-deploy.yaml).

Output of YAML file creation:
~~~
[root@test01 dns-svc-pod]# kubectl get svc,ep,pods -o wide -l app=dns-testing
NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/nginx-svc   ClusterIP   None         <none>        80/TCP    70s   run=nginx-svc

NAME                  ENDPOINTS                         AGE
endpoints/nginx-svc   10.244.0.112:80,10.244.0.113:80   70s

NAME                            READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE
pod/nginx-svc-d974969dc-dcwln   1/1     Running   0          70s   10.244.0.112   test01   <none>
pod/nginx-svc-d974969dc-sz24h   1/1     Running   0          70s   10.244.0.113   test01   <none>
~~~

Results of nslookup:
1. Pods FQDN name: my-hostname.my-subdomain.my-namespace.svc.cluster.local is in the same as above;

2. Service A & SRV records are very similar to above. The only difference is that it is resolved to the set of Pods IP address;

3. Pod's A record returns the pod's IP address and with a FQDN as below:
~~~
/ # nslookup 10-244-0-112.default.pod
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10-244-0-112.default.pod
Address 1: 10.244.0.112 nginx.nginx-svc.default.svc.cluster.local
/ # nslookup 10-244-0-113.default.pod
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      10-244-0-113.default.pod
Address 1: 10.244.0.113 nginx.nginx-svc.default.svc.cluster.local
~~~
## Tips:
- Pod has NOT SRV record in deployment, if your application has a logical connection ( need to commnect to a specific Pod name), then you need to come up to [StatefulSet](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/#creating-a-statefulset)

End of Doc
---