# mssql-kubernetes

![image](https://github.com/falahatme/mssql-kubernetes/assets/7458874/87e1257e-0063-40fb-9eb9-46f969077146)

# Advantages

✔️ Separated Data Files with Synchronous Mirroring

✔️ Affinity for Automatic Deployment on Different Nodes

✔️ Automatic Failover and Failback Handler (Quorum)

✔️ Failover Handler Based On [DH2I Dxe Enterprise](https://dh2i.com/dxenterprise-high-availability/)

# Requirements

### Kubernetes
A Kubernetes cluster with at least 3 worker nodes.
### Storage
A default storage class based on a storage manager for example, [Ceph](https://github.com/mohammadfalahat/rook) or [Rancher Local-Path-Provisioner](https://github.com/rancher/local-path-provisioner)
### DH2I License
Get a DH2I free trial license: [DH2I Free Trial License](https://clients.dh2i.com/Default.aspx)

# Installation

### Log in to the Master Node

Deploy PVC, Services, and Deployments:

```
kubectl apply -f https://raw.githubusercontent.com/mohammadfalahat/mssql-kubernetes/main/deployment.yml
```

Check PVC (Persistent Volume Claim):

```
kubectl get pvc
```

Check mssql Pods:

```
kubectl get pod -l lblabel=mssql-ha -o wide 
```

If the MSSQL pods are in a running state and the PVCs are in a bound state, then run the installer:

```
wget https://raw.githubusercontent.com/mohammadfalahat/mssql-kubernetes/main/installer.sh && chmod +x installer.sh && vim installer.sh
```

replace your license with DH2I_LICENSE variable inside `installer.sh`

you can also modify `AG_NAME`, `DB_PASSWORD` and `CLUSTER_PASSWORD`

After making these changes, run `installer.sh`:

```
./installer.sh
```

# Done!

### External Load Balancer

If you are using HAProxy as your external load balancer, you can add this configuration to keep nodes in the background and achieve higher availability in the event of a node failure.

```
frontend sql_frontend
    mode tcp
    bind *:1433
    default_backend sql_backend

backend sql_backend
    mode tcp
    balance roundrobin
    server sql-primary {{WORKER1_IP}}:30433 check inter 2s rise 1 fall 1
    server sql-secondary1 {{WORKER2_IP}}:30433 check inter 2s rise 1 fall 1
    server sql-secondary2 {{WORKER3_IP}}:30433 check inter 2s rise 1 fall 1
```

# How does it work
soon ...
