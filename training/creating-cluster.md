# Creating a single master cluster from kubeadm

## Environment

The host should be able to pull images from gcr.io. If you have any issues on blocking to pull them, you can:   
 1. Get the required images list
~~~
# kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.12.1
k8s.gcr.io/kube-controller-manager:v1.12.1
k8s.gcr.io/kube-scheduler:v1.12.1
k8s.gcr.io/kube-proxy:v1.12.1
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.2.24
k8s.gcr.io/coredns:1.2.2
~~~
 2. Pull them from richardx repository and change the tag, e.g:
~~~
# docker pull richardx/kube-controller-manager:v1.12.1
   
# docker docker.io/richardx/kube-controller-manager:v1.12.1 k8s.gcr.io/kube-controller-manager:v1.12.1
# docker rmi docker.io/richardx/kube-controller-manager:v1.12.1
~~~
For details, you can refer scripts:[*-images.sh](https://github.com/xiaojias/k8s/tree/master/v1.11.2)

## Environment preparing

1. Disable swap for kubelet by modifying the file's content
~~~
# cat /etc/sysctl.conf |grep swap
vm.swappiness = 0
~~~
2.  Removing unnecessary network interface/s, especially the node has ever installed Kubernetes and/or docker. etc
~~~
# ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 00:16:3e:01:39:14 brd ff:ff:ff:ff:ff:ff
~~~
Using command "ip link delete <name>" to remove unnecesary interface, e.g docker0, flannel.1 etc.

## Installing kubeadm
1. Updating system with root user
~~~
# yum update && yum upgrade -y
~~~
2. Installing Container Runtime Interface ( is Docker here)

~~~
# yum install docker-ce
   
# yum install yum-utils device-mapper-persistent-data lvm2
   
# yum-config-manager  --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   
# yum update && yum install docker-ce-18.06.1.ce
   
~~~
Configuring docker daemon
~~~
# cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
   
# mkdir -p /etc/systemd/system/docker.service.d
   
# systemctl daemon-reload && systemctl restart docker
~~~
Verifying its installation
~~~
# docker version
Client:
 Version:           18.06.1-ce
 API version:       1.38
 Go version:        go1.10.3
 Git commit:        e68fc7a
 Built:             Tue Aug 21 17:23:03 2018
 OS/Arch:           linux/amd64
 Experimental:      false

Server:
 Engine:
  Version:          18.06.1-ce
  API version:      1.38 (minimum version 1.12)
  Go version:       go1.10.3
  Git commit:       e68fc7a
  Built:            Tue Aug 21 17:25:29 2018
  OS/Arch:          linux/amd64
  Experimental:     false
~~~

3. Installing kubeadm, kubelet and kubectl   
Setting yum source
~~~
# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
~~~
Installing
~~~
# setenforce 0
# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
   
# yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
# systemctl enable kubelet && systemctl start kubelet
   
# cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
# sysctl --system
~~~
Verifying the installed packages
~~~
# rpm -qa |grep kube
kubeadm-1.12.1-0.x86_64
kubelet-1.12.1-0.x86_64
kubernetes-cni-0.6.0-0.x86_64
kubectl-1.12.1-0.x86_64
~~~
   
## Initializing the master
~~~
# kubeadm init --pod-network-cidr=10.244.0.0/16
[init] using Kubernetes version: v1.12.1
[preflight] running pre-flight checks
	[WARNING Service-Docker]: docker service is not enabled, please run 'systemctl enable docker.service'
[preflight/images] Pulling images required for setting up a Kubernetes cluster
[preflight/images] This might take a minute or two, depending on the speed of your internet connection
[preflight/images] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[preflight] Activating the kubelet service
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [test01 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.31.65.91]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated etcd/ca certificate and key.
[certificates] Generated etcd/server certificate and key.
[certificates] etcd/server serving cert is signed for DNS names [test01 localhost] and IPs [127.0.0.1 ::1]
[certificates] Generated etcd/healthcheck-client certificate and key.
[certificates] Generated etcd/peer certificate and key.
[certificates] etcd/peer serving cert is signed for DNS names [test01 localhost] and IPs [172.31.65.91 127.0.0.1 ::1]
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/kubernetes/pki"
[certificates] Generated sa key and public key.
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[controlplane] wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests" 
[init] this might take a minute or longer if the control plane images have to be pulled
[apiclient] All control plane components are healthy after 21.002417 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.12" in namespace kube-system with the configuration for the kubelets in the cluster
[markmaster] Marking the node test01 as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node test01 as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "test01" as an annotation
[bootstraptoken] using token: vzbq3f.xw2cxr3hgdapqt4s
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join <be-hidden>:6443 --token <be-hidden> --discovery-token-ca-cert-hash sha256:<be-hidden>
~~~
Creating config for kubelet by following the stpes in above output
~~~
# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
~~~

Verifying the initialization
~~~
$ kubectl get nodes
NAME     STATUS     ROLES    AGE    VERSION
test01   NotReady   master   7m4s   v1.12.1
~~~

Installing pod network add-on ( flannel is here)
~~~
# sysctl net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-iptables = 1
   
# wget https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
   
# cat kube-flannel.yml
...
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
...
   
# kubectl apply -f kube-flannel.yml 
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.extensions/kube-flannel-ds-amd64 created
daemonset.extensions/kube-flannel-ds-arm64 created
daemonset.extensions/kube-flannel-ds-arm created
daemonset.extensions/kube-flannel-ds-ppc64le created
daemonset.extensions/kube-flannel-ds-s390x created

~~~

## Verifying the installation
~~~
# kubectl -n kube-system get pods
NAME                             READY   STATUS    RESTARTS   AGE
coredns-576cbf47c7-hmjr8         1/1     Running   0          57m
coredns-576cbf47c7-sg7sg         1/1     Running   0          57m
etcd-test01                      1/1     Running   0          57m
kube-apiserver-test01            1/1     Running   0          56m
kube-controller-manager-test01   1/1     Running   0          56m
kube-flannel-ds-amd64-6kcph      1/1     Running   0          51m
kube-proxy-tlhp7                 1/1     Running   0          57m
kube-scheduler-test01            1/1     Running   0          56m

~~~
## Post actions
### Removing taints
~~~
# kubectl describe node test01 | grep -i taint
Taints:             node-role.kubernetes.io/master:NoSchedule
# kubectl taint node test01 node-role.kubernetes.io/master:NoSchedule-
node/test01 untainted
   
# kubectl describe node test01 | grep -i taint
Taints:             <none>
~~~
