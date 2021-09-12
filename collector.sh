#!/usr/bin/env bash

#Variables
REPORT_PATH=$1/$(date +%d-%b-%H-%M)
echo "The reports will be saved in: $REPORT_PATH"
#Cleaning-up
if test -f "$REPORT_PATH"; then
    cat /dev/null > $REPORT_PATH
fi
kubectl delete pod/collector


for node in $(kubectl get nodes -o jsonpath="{.items[*].metadata.name}")

do

cat << EOF > collector-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: collector
  labels:
    app: collector
spec:
  hostNetwork: true
  nodeName: $node
  serviceAccountName: alvaro-test
  containers:
  - image: liubowei/netstat
    command:
      - "sleep"
      - "infinity"
    imagePullPolicy: IfNotPresent
    name: collector
  restartPolicy: Always
EOF

echo "Ports opened in Node: $node" >> $REPORT_PATH

kubectl apply -f collector-pod.yaml
sleep 5
kubectl exec collector -- bash -c "netstat -putan|grep LISTEN|grep 0.0.0.0.0"|awk '{print $4}' | awk -F ':' '{print $2}' >> $REPORT_PATH
kubectl delete pod collector

done
