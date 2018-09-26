Heapster installation (InfluxDB + Grafana based on K8s v1.11.2)
===
1. Download YAML files from: [official document](https://github.com/kubernetes/heapster/blob/master/docs/influxdb.md);
   
2. Make modification on YAML files;   

* Create resource based on [YAML file](https://github.com/xiaojias/k8s/blob/master/v1.11.2/deployment/heapster/deploy/kube-config/rbac/heapster-clusterrole.yaml)   
 to grant "Write" access rights to resources;   

* Modify [grafana.yaml](https://github.com/xiaojias/k8s/blob/master/v1.11.2/deployment/heapster/deploy/kube-config/influxdb/grafana.yaml)   
 to expose port as following:
 ```
  type: NodePort
  ports:
   - port: 80
     targetPort: 3000
     nodePort: 31080
 ```
* Modify [heapster.yaml]()   
 to communicate to APIServer with Authenticate and Serviceaccount authority, and use hostPath type PV as well:   
~~~
        - --source=kubernetes:https://kubernetes.default?&insecure=false
        - --tls-ca-file=/etc/kubernetes/pki/for-heapster/ca.pem
        - --tls-cert-file=/etc/kubernetes/pki/for-heapster/apiserver.pem
...
        volumeMounts:
        - mountPath: /etc/kubernetes/pki/for-heapster
          name: certdir
...
      volumes:
      - name: certdir
        hostPath:
          path: /etc/kubernetes/pki/for-heapster
~~~   
3. Create resources based on above YAML files;
~~~
# kubectl create -f deploy/kube-config/influxdb/    
   
# kubectl create -f deploy/kube-config/rbac/   

~~~

4. Verification;
* Checking the pods' status
~~~
# kubectl get pod  -n kube-system
NAME                                    READY     STATUS    RESTARTS   AGE
...
heapster-676fc4b686-95zn6               1/1       Running   0          58m
monitoring-grafana-555545f477-wv2dc     1/1       Running   1          1d
monitoring-influxdb-848b9b66f6-4ld6t    1/1       Running   1          1d

~~~

* Checking heapster pod's log on if there is any error message generated
~~~
# kubectl -n kube-system logs heapster-676fc4b686-95zn6
I0926 05:50:25.373439       1 heapster.go:78] /heapster --source=kubernetes:https://kubernetes.default?&insecure=false --tls-ca-file=/etc/kubernetes/pki/for-heapster/ca.pem --tls-cert-file=/etc/kubernetes/pki/for-heapster/apiserver.pem --sink=influxdb:http://monitoring-influxdb.kube-system.svc:8086
I0926 05:50:25.373484       1 heapster.go:79] Heapster version v1.5.4
I0926 05:50:25.373671       1 configs.go:61] Using Kubernetes client with master "https://kubernetes.default" and version v1
I0926 05:50:25.373680       1 configs.go:62] Using kubelet port 10255
I0926 05:50:25.394842       1 influxdb.go:312] created influxdb sink with options: host:monitoring-influxdb.kube-system.svc:8086 user:root db:k8s
I0926 05:50:25.394867       1 heapster.go:202] Starting with InfluxDB Sink
I0926 05:50:25.394872       1 heapster.go:202] Starting with Metric Sink
I0926 05:50:25.412467       1 heapster.go:112] Starting heapster on port 8082
I0926 05:51:05.026346       1 influxdb.go:274] Created database "k8s" on influxDB server at "monitoring-influxdb.kube-system.svc:8086"

~~~

* Checking if there is any data collected
~~~
# kubectl top nodes
NAME      CPU(cores)   CPU%      MEMORY(bytes)   MEMORY%   
test02    136m         6%        2107Mi          57%       
   
# kubectl top pod -n kube-system
NAME                                    CPU(cores)   MEMORY(bytes)   
coredns-78fcdf6894-f5566                1m           7Mi             
coredns-78fcdf6894-s4nzb                1m           7Mi             
etcd-test02                             13m          113Mi           
heapster-676fc4b686-95zn6               0m           22Mi            
kube-apiserver-test02                   21m          256Mi           
kube-controller-manager-test02          24m          49Mi            
kube-flannel-ds-hs9fs                   2m           8Mi             
kube-proxy-ns5p2                        2m           11Mi            
kube-scheduler-test02                   7m           12Mi            
kubernetes-dashboard-84fff45879-6llm6   0m           15Mi            
monitoring-grafana-555545f477-wv2dc     0m           14Mi            
monitoring-influxdb-848b9b66f6-4ld6t    0m           94Mi            

~~~
* Checking the output on K8s dashboard   
it looks like: ![K8s Dashboard with Heapster installed](https://github.com/xiaojias/k8s/blob/master/v1.11.2/deployment/heapster/k8s-heapster.png)   

