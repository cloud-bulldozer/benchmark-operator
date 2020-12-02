# Set up sctp on your cluster

The required CR files to enable sctp can be found in the tools/sctp folder. To enable sctp, deploy the machineConfig:
```
oc create -f allow-sctp.yaml
```

In order to verify if sctp works, set up a new project:
```
oc new-project verify-sctp
```

Create a service account with cluster-admin privileges (required for SCTP sockets)
```
oc create sa sctp-sa
oc adm policy add-role-to-user cluster-admin -z sctp-sa
```

Create a pod that runs the sctp listener, a corresponding service and the sctp client:
```
oc create -f sctp_server.yaml
oc create -f sctp_service.yaml
oc create -f sctp_client.yaml
```

Obtain the IP address of the sctp service:
```
oc get services sctpservice -o go-template='{{.spec.clusterIP}}{{"\n"}}'
```

Now connect to the server pod and start the sctp listener
```
oc rsh sctpserver
nc -l 30102 --sctp
```

In parallel connect to the client pod and start the sctp client:
```
oc rsh sctpclient
nc <cluster_IP> 30102 --sctp
```