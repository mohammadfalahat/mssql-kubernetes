# mssql-kubernetes

![image](https://github.com/falahatme/mssql-kubernetes/assets/7458874/87e1257e-0063-40fb-9eb9-46f969077146)

# Advantages

✔️ Seperated Data Files with syncronous mirroring

✔️ affinity for deploying automatically on different nodes

✔️ Automatic Failover and Failback handler (Quorum)

✔️ Failover handler Based On [DH2I Dxe Enterprise ](https://dh2i.com/dxenterprise-high-availability/)

# Requirements

### Kubernetes
A kubernetes cluster with at least 3 worker nodes.
### Storage
A default storage class based on a storage manager for example [ceph](https://github.com/mohammadfalahat/rook) or [rancher local-path-provisioner](https://github.com/rancher/local-path-provisioner)

# Installation

### Log in to Master Node

deploy PVC, Services and deployments with applying manifest:

```
https://raw.githubusercontent.com/mohammadfalahat/mssql-kubernetes/main/deployment.yml
```

Check  pvc and deployments

```
kubectl get pvc
kubectl get po -o wide
```

if mssql pods are in running state and pvc's are in Bound state then run installer:

```
wget https://raw.githubusercontent.com/mohammadfalahat/mssql-kubernetes/main/installer.sh && chmod +x installer.sh && vim installer.sh
```

get a dh2i free trial license: https://clients.dh2i.com/Default.aspx

replace your license with DH2I_LICENSE variable inside installer.sh

you can also change AG_NAME, DB_PASSWORD and CLUSTER_PASSWORD

then run installer.sh:

```
./installer.sh
```

### Done!


# How does it work
soon ...
