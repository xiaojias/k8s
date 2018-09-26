K8s APIServer
===
In my case, APIserver started with secure MODE:
~~~
--authorization-mode=Node,RBAC
--insecure-port=0
--secure-port=6443
~~~

Verify with firefox browser
---
1. Create p12 certificate file
* Capture data of client-certificate-data
~~~
# grep "client-certificate-data" ~/.kube/config | head -n 1 | awk '{ print $2 }' | base64 -d >> kubecfg.crt
~~~

* Capture data of client-key
~~~
# grep "client-key-data" ~/.kube/config | head -n 1 | awk '{ print $2 }' | base64 -d >> kubecfg.key
~~~

* Generate p12 file
~~~
# openssl pkcs12 -export -clcerts -inkey kubecfg.key -in kubecfg.crt -out kubecfg.p12 -name "kubernetes-client for cluster of $(hostname)"
Enter Export Password: 
Verifying - Enter Export Password: 
~~~

2. Import p12 firefox and restart firefox as well

3. Open https://<api server>:6443/api/v1 with browser, and select the certificate while prompting

Verify with curl command
---
1. curl command with insecure mode should work
~~~
# curl  -k https://<api server>:6443/api/v1/
~~~

2. checking curl command with secure mode
* Creating PEM file
~~~
# pwd
/etc/kubernetes/pki/for-heapster
   
# cp ../ca.crt ca.pem
~~~

* Checking /api/v1 with secure mode (will get resources returned)
~~~
# curl  --cacert /etc/kubernetes/pki/for-heapster/ca.pem https://<api server>:6443/api/v1
~~~

* Checking others (e.g /api/v1/nodes), will get "forbidden" return
~~~
# curl  --cacert /etc/kubernetes/pki/for-heapster/ca.pem https://<api server>:6443/api/v1/nodes
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "nodes is forbidden: User \"system:anonymous\" cannot list nodes at the cluster scope",
  "reason": "Forbidden",
  "details": {
    "kind": "nodes"
  },
  "code": 403
}
~~~
(NOT sure so far, maybe it is as expected, due to missing authority on serviceaccount or something)
