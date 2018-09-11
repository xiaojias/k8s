Steps to deploy Kubernetes v1.11.2 via [kubeadmin](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/) method
===

Environment
---

Two or more ECSs (2CPU, 4 Core per ECS ) from Aliyun

CentOS 7

Preparation
---
1. Update /etc/hosts for every node  
2. Set YUM source for Kubernetes
```# cat /etc/yum.repos.d/kubernetes.repo```   
```[kubernetes]```   
```name=Kubernetes```   
```baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64```   
```enabled=1```   
```gpgcheck=0```   
3. Completely remove NIC of cni0, flannel.1, docker0, if the environment is reset from ```kubeadm reset```   
4. Make sure ```bridge-nf-call-iptables``` is enable, can check from ```docker info``` command   

Kubernetes Cluster Installation
---
1. Installing kubeadm and tools on every nodes   
 ```# yum install docker kubelet kubeadm kubectl kubernetes-cni```   

2. Enableing and starting docker service on every nodes

3. Pulling images down, if there is any blocking on image pulling from ```k8s.gcr.io```, there are 2 options:   
> 1.a Changeing ```imageRepository: k8s.gcr.io``` to ```imageRepository: richardx``` in following file of ```kube-config.01``` in following step, so that the custom image repository can be used.;   
> 1.b Using [push* scripts](https://github.com/xiaojias/k8s/tree/master/v1.11.2) to pull down the images from ```richardx``` image repository instead.
 
4. On Master node, building Kubernetes cluster with `Kubeadm init` command with a custom [configuration file](https://github.com/xiaojias/k8s/blob/master/v1.11.2/multi-nodes-deployment/kubeadm-config.yaml).   
```# kubeadm init --config kube-config.01```

5. On Master node, Configuring kubelet to use cluster with root, by performing command:   
```cp -i /etc/kubernetes/admin.conf $HOME/.kube/config```   
6. On Master node, Deploying flannel to the cluster   
Creating configuration files like following:   
```# mkdir -p /etc/cni/net.d/```   
```# cat /etc/cni/net.d/10-flannel.conf ```   
```{```   
```“name”: “cbr0”,```   
```“type”: “flannel”,```   
```“delegate”: {```   
```“isDefaultGateway”: true```   
```}```   
```}```   
```# mkdir /run/flannel```   
```# cat /run/flannel/subnet.env ```   
```FLANNEL_NETWORK=10.244.0.0/16```   
```FLANNEL_SUBNET=10.244.1.0/24```   
```FLANNEL_MTU=1450```   
```FLANNEL_IPMASQ=true```   
   
   Deploying flannel as pod-hosted   
```# wget https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml```   
```# kubectl apply -f kube-flannel.yml```   

7. Reperforming step 5 on other worker nodes   
8. Perfoming ```kubeadm join``` command in output of step 4 on every worker node/s   

Verfication
---
Checking the nodes and pods status   
```# kubectl get nodes```   
```# kubectl  -n kube-system get pods```   

Make sure every statu is Ready or Running   

Dashboard installation
---
Installing with [file](https://github.com/xiaojias/k8s/blob/master/v1.11.2/multi-nodes-deployment/dashboard.yaml)   
```# kubectl apply -f dashboard.yaml ```

Certificate configuration
---
For APIServer client (tested for Firefox browser)   
1. Generate certificate file   
```# grep "client-key-data" ~/.kube/config | head -n 1 | awk '{ print $2 }' | base64 -d >> kubecfg-$(hostname).key```   
```# grep "client-certificate-data" ~/.kube/config | head -n 1 | awk '{ print $2 }' | base64 -d >> kubecfg-$(hostname).crt```   
```# openssl pkcs12 -export -clcerts -inkey kubecfg-$(hostname).key -in kubecfg-$(hostname).crt -out kubecfg-$(hostname).p12 -name "kubernetes-client for cluster of $(hostname)"```   
2. Import .p12 file into Firfox browser
3. Login https://aliyun-test01:6443, select the imported certificate while prompting
4. The output should like as ![APIServer](https://github.com/xiaojias/k8s/blob/master/v1.11.2/apiserver-01.png)

For Dashboard   
1. Get token from secret   
```# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') | grep "^token" | sed 's/^.* //g'```
2. Login https://aliyun-test01:30000 with captured token value as ![Dashboard UI](https://github.com/xiaojias/k8s/blob/master/v1.11.2/dashboard-01.png)   

Prometheus installation
---
1. Create namespace   
```# kubectl create namespace monitoring```   
2. Remove tain for master node   
```# kubectl taint node test01 node-role.kubernetes.io/master:NoSchedule-```   
3. Install Prometheus operator from [YAMLs](https://github.com/xiaojias/k8s/tree/master/v1.11.2/multi-nodes-deployment/prometheus-operator)   
4. Install Prometheus from [YAMs](https://github.com/xiaojias/k8s/tree/master/v1.11.2/multi-nodes-deployment/prometheus)
5. Open link of https://aliyun-test01:30900 likes as ![Prometheus](https://github.com/xiaojias/k8s/blob/master/v1.11.2/prometheus-01.png)   

