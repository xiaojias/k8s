# API Server access - 02
- how to create certificate for RESTful
- how to access API server via Web browser and RESTClient

## Create p12 certificate
Assume the following 2 files are created according to [API Server access - 01](https://github.com/xiaojias/k8s/blob/master/training/apiAccess-01.md):
~~~
client.pem
client-key.pem
~~~
Create p12 certificate file
~~~
openssl pkcs12 -export -clcerts -in ./client.pem -inkey ./client-key.pem -out test01.p12 -name "Kubernetes-client for test01"
~~~

### Import p12 certificate to Web browser ( e.g Firefox)
Transfer the p12 file to local and import to firefox 
~~~
through "Preference" --> "Advanced" --> "Certificates" --> "View ..." --> "Import" )
~~~    

Select the imported certificates while prompting, the output looks like [RESTful01.png](https://github.com/xiaojias/k8s/blob/master/training/RESTful01.png)   
And RESTClient will work as well ( POST action is not working so far, to be verified.)