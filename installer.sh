#!/bin/bash


### define variables to use them in one time master node after pods are ready.
export AG_NAME="ags1"
export DB_PASSWORD="SQL@2022AGPSSWORD"
export CLUSTER_PASSWORD="PASS3ORD4CIuster"
export DH2I_LICENSE="AK3D-Q3HY-ZHUW-MZGK"



### do not change these variables:
export PRIMARYNOD_NAME="mssql-primary"
export SECONDARY1_NAME="mssql-secondary1"
export SECONDARY2_NAME="mssql-secondary2"
export PRIMARYNOD_PODNAME=$(kubectl get pods -l app=$PRIMARYNOD_NAME -o custom-columns=:metadata.name)
export SECONDARY1_PODNAME=$(kubectl get pods -l app=$SECONDARY1_NAME -o custom-columns=:metadata.name)
export SECONDARY2_PODNAME=$(kubectl get pods -l app=$SECONDARY2_NAME -o custom-columns=:metadata.name)
export SA_PASSWORD=$(kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli encrypt-text $DB_PASSWORD)



run_loading_bar() {
    local total_duration="$1"
    local update_interval=1
    local num_steps=$((total_duration / update_interval))
    local progress=0

    for ((i = 0; i < num_steps; i++)); do
        local percent=$((100 * progress / num_steps))

        # Clear the line
        echo -ne "\r"

        # Print the loading bar
        echo -n "Progress: ["
        for ((j = 0; j < percent; j+=2)); do
            echo -n "="
        done
        for ((j = percent; j < 100; j+=2)); do
            echo -n " "
        done
        echo -n "] $percent        "

        # Update the progress
        progress=$((progress + 1))

        # Sleep for the update interval
        sleep $update_interval
    done

    # Complete the loading bar
    echo -e "\nLoading complete!"
}



### License pods
while :
do
echo    "trying license for pod $PRIMARYNOD_NAME"
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli activate-server $DH2I_LICENSE --accept-eula && break
done
while :
do
echo    "trying license for pod $SECONDARY1_NAME"
kubectl exec -c dxe $SECONDARY1_PODNAME -- dxcli activate-server $DH2I_LICENSE --accept-eula && break
done
while :
do
echo    "trying license for pod $SECONDARY2_NAME"
kubectl exec -c dxe $SECONDARY2_PODNAME -- dxcli activate-server $DH2I_LICENSE --accept-eula && break
done



### Configure the Primary Pod and Add the Availability Group
echo "CREATING CLUSTER IN PRIMARY NODE"
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli cluster-add-vhost vhost1 "" $PRIMARYNOD_NAME "autofailback"
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli add-ags vhost1 $AG_NAME "$PRIMARYNOD_NAME|mssqlserver|sa|$SA_PASSWORD|5022|synchronous_commit|0"
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli cluster-set-secret-ex $CLUSTER_PASSWORD
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli set-globalsetting membername.lookup true

run_loading_bar 4

echo "JOINING SECONDARIES"
kubectl exec -c dxe $SECONDARY1_PODNAME -- dxcli join-cluster-ex $PRIMARYNOD_NAME $CLUSTER_PASSWORD && run_loading_bar 4
kubectl exec -c dxe $SECONDARY2_PODNAME -- dxcli join-cluster-ex $PRIMARYNOD_NAME $CLUSTER_PASSWORD && run_loading_bar 4
kubectl exec -c dxe $SECONDARY1_PODNAME -- dxcli add-ags-node vhost1 $AG_NAME "$SECONDARY1_NAME|mssqlserver|sa|$SA_PASSWORD|5022|synchronous_commit|0"
kubectl exec -c dxe $SECONDARY2_PODNAME -- dxcli add-ags-node vhost1 $AG_NAME "$SECONDARY2_NAME|mssqlserver|sa|$SA_PASSWORD|5022|synchronous_commit|0"


### Add an Availability Group Database
echo "CREATING DATABASE"
kubectl exec -c $PRIMARYNOD_NAME $PRIMARYNOD_PODNAME -- /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $DB_PASSWORD -Q "create database db1"
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli add-ags-databases vhost1 $AG_NAME db1
kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli get-ags-detail vhost1 $AG_NAME # | kubectl exec -c dxe $PRIMARYNOD_PODNAME -- dxcli format-xml


### run this query in primary instance
echo "run this query in primary instance:"
cat <<EOF



--- RUN THIS CODE IN PRIMARY NODE TO CONFIGURE READ/WRITE CONNECTION REDIRECTION

USE [master];
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$PRIMARYNOD_NAME'
WITH (    ENDPOINT_URL = N'tcp://$PRIMARYNOD_NAME:5022'    );
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY1_NAME'
WITH (    ENDPOINT_URL = N'tcp://$SECONDARY1_NAME:5022'    );
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY2_NAME'
WITH (    ENDPOINT_URL = N'tcp://$SECONDARY2_NAME:5022'    );
GO


ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$PRIMARYNOD_NAME'
WITH (SECONDARY_ROLE (    ALLOW_CONNECTIONS = ALL    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY1_NAME'
WITH (SECONDARY_ROLE (    ALLOW_CONNECTIONS = ALL    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY2_NAME'
WITH (SECONDARY_ROLE (    ALLOW_CONNECTIONS = ALL    ));
GO


ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$PRIMARYNOD_NAME'
WITH (SECONDARY_ROLE (    READ_ONLY_ROUTING_URL = N'tcp://$PRIMARYNOD_NAME:1433'    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY1_NAME'
WITH (SECONDARY_ROLE (    READ_ONLY_ROUTING_URL = N'tcp://$SECONDARY1_NAME:1433'    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY2_NAME'
WITH (SECONDARY_ROLE (    READ_ONLY_ROUTING_URL = N'tcp://$SECONDARY2_NAME:1433'    ));
GO


ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$PRIMARYNOD_NAME'
WITH (PRIMARY_ROLE (    ALLOW_CONNECTIONS = READ_WRITE    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY1_NAME'
WITH (PRIMARY_ROLE (    ALLOW_CONNECTIONS = READ_WRITE    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY2_NAME'
WITH (PRIMARY_ROLE (    ALLOW_CONNECTIONS = READ_WRITE    ));
GO


ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$PRIMARYNOD_NAME'
WITH (PRIMARY_ROLE (    READ_ONLY_ROUTING_LIST = (N'$SECONDARY1_NAME', N'$SECONDARY2_NAME')    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY1_NAME'
WITH (PRIMARY_ROLE (    READ_ONLY_ROUTING_LIST = (N'$PRIMARYNOD_NAME', N'$SECONDARY2_NAME')    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY2_NAME'
WITH (PRIMARY_ROLE (    READ_ONLY_ROUTING_LIST = (N'$PRIMARYNOD_NAME', N'$SECONDARY1_NAME')    ));
GO


ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$PRIMARYNOD_NAME'
WITH (PRIMARY_ROLE (    READ_WRITE_ROUTING_URL = N'tcp://$PRIMARYNOD_NAME:1433'    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY1_NAME'
WITH (PRIMARY_ROLE (    READ_WRITE_ROUTING_URL = N'tcp://$SECONDARY1_NAME:1433'    ));
GO

ALTER AVAILABILITY
GROUP [$AG_NAME] MODIFY REPLICA
    ON N'$SECONDARY2_NAME'
WITH (PRIMARY_ROLE (    READ_WRITE_ROUTING_URL = N'tcp://$SECONDARY2_NAME:1433'    ));
GO



EOF


