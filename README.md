# mssql-kubernetes

![image](https://github.com/falahatme/mssql-kubernetes/assets/7458874/87e1257e-0063-40fb-9eb9-46f969077146)

# Advantages

✔️ Separated Data Files with Synchronous Mirroring

✔️ Affinity for Automatic Deployment on Different Nodes

✔️ Automatic Failover and Failback Handler (Quorum)

✔️ Failover Handler Based On [DH2I Dxe Enterprise](https://dh2i.com/dxenterprise-high-availability/)

# Requirements

**Kubernetes** : A Kubernetes cluster with at least 3 worker nodes.

**Storage** : A default storage class based on a storage manager for example, [Ceph](https://github.com/mohammadfalahat/rook) or [Rancher Local-Path-Provisioner](https://github.com/rancher/local-path-provisioner)

**DH2I License** : Get a DH2I free trial license: [DH2I Free Trial License](https://clients.dh2i.com/Default.aspx)

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
wget https://raw.githubusercontent.com/mohammadfalahat/mssql-kubernetes/main/installer.sh \
 && chmod +x installer.sh && vim installer.sh
```

replace your license with DH2I_LICENSE variable inside `installer.sh`

you can also modify `AG_NAME`, `DB_PASSWORD` and `CLUSTER_PASSWORD`

After making these changes, run `installer.sh`:

```
./installer.sh
```

When the installation is finished, it will provide you with a SQL query code. Log in to the primary node with the following port and credentials: Worker1_IP, 31111; user=SA; Password=DB_PASSWORD. Run that query just once.

Now, you can connect directly to the Kubernetes load balancer service using port 30433, which connects you to one of the MSSQL instances randomly.

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

### Stress test

You can test failover handling and performance with a stress test program. Here is an example in Golang. While it's running, you can power off the primary worker node and check the failover performance.

```
package main

import (
	"database/sql"
	"fmt"
	"log"
	"math/rand"
	"time"
	_ "github.com/denisenkom/go-mssqldb"
)

func GenerateRandomName() string {
	adjectives := []string{"Happy", "Clever", "Brave", "Eager", "Friendly", "Gentle", "Kind", "Lively", "Polite", "Witty"}
	nouns := []string{"Panda", "Tiger", "Dolphin", "Penguin", "Elephant", "Kangaroo", "Koala", "Giraffe", "Lion", "Zebra"}

	rand.Seed(time.Now().UnixNano())
	randomAdjective := adjectives[rand.Intn(len(adjectives))]
	randomNoun := nouns[rand.Intn(len(nouns))]

	return randomAdjective + " " + randomNoun
}

func main() {
	connString := "server={{EXTERNAL_LB_IP_OR_WORKER_IP, 1433_FOR_EXTERNAL_LB_30443_FOR_WORKER_IP}};user id=SA;password={{DB_PASSWORD}};database=db1"

	db, err := sql.Open("sqlserver", connString)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	for {
		randomName := GenerateRandomName()
		insertQuery := fmt.Sprintf("INSERT INTO Customers (name) VALUES ('%s')", randomName)
		_, err := db.Exec(insertQuery)
		if err != nil {
			log.Println("Error executing INSERT query:", err)
		}
		fmt.Printf("Inserted: %s\n", randomName)
		time.Sleep(200 * time.Millisecond)
	}
}
```

# How does it work
soon ...
