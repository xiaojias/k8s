# API Server access - 01
- how to create keys based on config file
- how to access API server with the keys

## Create keys based on config file
Assume the user can access cluster via 'kubectl' command

### View the config file, there will be the following keys in it:
    server, certificate-authority-data, client-certificate-data and client-key-data: 
    
### Capture the data from config file
Create key' files with commands:
~~~
$ grep "client-certificate-data:" ~/.kube/config | sed 's/client-certificate-data://g' | sed 's/ //g' | base64 -d - > ./client.pem
   
$ grep "client-key-data:" ~/.kube/config | sed 's/client-key-data://g' | sed 's/ //g' | base64 -d - > ./client-key.pem
   
$ grep "certificate-authority-data:" ~/.kube/config | sed 's/certificate-authority-data://g' | sed 's/ //g' | base64 -d - > ./ca.pem
~~~   
Get API server as variable:
~~~
$ APIServer=$(grep "server:" ~/.kube/config | sed 's/server://g' | sed 's/ //g')
~~~

### Verify API GET call by getting pods
~~~
$ curl --cert ./client.pem --key ./client-key.pem --cacert ./ca.pem $APIServer/api/v1/pods
~~~

Go forward if above command works successfully.

### Create a new pod via API call
Create a new JSON file
~~~
$ cat curlpod.json
{
	"kind": "Pod",
	"apiVersion": "v1",
	"metadata": {
		"name": "curlpod",
		"namespace": "default",
		"labels": {
			"name": "examplepod"
		}
	},
	"spec": {
		"containers": [{
			"name": "nginx",
			"image": "nginx",
			"ports": [{
				"containerPort": 80
			}]
		}]
	}
}
~~~
Create pod in 'default' namespace from the JSON file
~~~
$ curl --cert ./client.pem --key ./client-key.pem --cacert ./ca.pem $APIServer/api/v1/namespaces/default/pods  -XPOST -H'Content-Type: application/json' -d@curlpod.json
~~~
Verify if the pod is created via 'kubectl' command, the output should looks like:
~~~
$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
curlpod   1/1     Running   0          12s
~~~