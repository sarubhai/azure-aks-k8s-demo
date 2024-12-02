#!/bin/bash
# Name: test_automation.sh
# Owner: Saurav Mitra
# Description: Test AKS Core Infrastructure Resources

# Pre-requisite
# az, kubectl, envsubst, jq

# Create Testing Namespace
export TESTING_NAMESPACE='testing'
kubectl create namespace ${TESTING_NAMESPACE}
# Set Context
kubectl config set-context --current --namespace=${TESTING_NAMESPACE}

export SUBSCRIPTION_ID='XXXX'
export RESOURCE_GROUP_NAME='azure-aks-k8s-demo-rg'
export RESOURCE_GROUP_LOCATION='germanywestcentral'


# 1. Azure Disk Validation:
echo "Azure Disk Testing:"
export AZURE_DISK_NAME='testAzurediskAksStaticPv'
export ZONE='1'
az disk create --resource-group ${RESOURCE_GROUP_NAME} --name ${AZURE_DISK_NAME} --size-gb 5 --sku Standard_LRS --zone ${ZONE} --query id --output tsv
envsubst < 1_test_aks_azure_disk.yaml | kubectl apply -f -

echo "Azure Disk Static Provisioning Validation:"
while [[ $(kubectl get pods test-azuredisk-pod-static -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 2
done
kubectl exec -it test-azuredisk-pod-static -- /bin/bash -c "cat /data/out.txt"
kubectl exec -it test-azuredisk-pod-static -- /bin/bash -c "wc -l /data/out.txt"
kubectl exec -it test-azuredisk-pod-static -- /bin/bash -c "if [ -s '/data/out.txt' ]; then echo 'Success'; else echo 'Failed'; fi"

echo "Azure Disk Dynamic Provisioning Validation:"
while [[ $(kubectl get pods test-azuredisk-pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 2
done
kubectl exec -it test-azuredisk-pod -- /bin/bash -c "cat /data/out.txt"
kubectl exec -it test-azuredisk-pod -- /bin/bash -c "wc -l /data/out.txt"
kubectl exec -it test-azuredisk-pod -- /bin/bash -c "if [ -s '/data/out.txt' ]; then echo 'Success'; else echo 'Failed'; fi"



# 2. Azure File Validation:
echo "Azure File Testing:"
export AZURE_STORAGE_ACCOUNT='testazfilesa'
export FILE_SHARE_NAME='testazfileshare'
az storage account create --resource-group ${RESOURCE_GROUP_NAME} --name ${AZURE_STORAGE_ACCOUNT} --sku Standard_LRS --location ${RESOURCE_GROUP_LOCATION} --query id --output tsv
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --resource-group ${RESOURCE_GROUP_NAME} --name ${AZURE_STORAGE_ACCOUNT} --output tsv)
az storage share create --name ${FILE_SHARE_NAME} --connection-string ${AZURE_STORAGE_CONNECTION_STRING}
STORAGE_KEY=$(az storage account keys list --resource-group ${RESOURCE_GROUP_NAME} --account-name ${AZURE_STORAGE_ACCOUNT} --query "[0].value" --output tsv)
export SECRET_NAME='azure-secret'
kubectl create secret generic ${SECRET_NAME} --from-literal=azurestorageaccountname=${AZURE_STORAGE_ACCOUNT} --from-literal=azurestorageaccountkey=${STORAGE_KEY}
envsubst < 2_test_aks_azure_file.yaml | kubectl apply -f -

echo "Azure File Static Provisioning Validation:"
while [[ $(kubectl get pods test-azurefile-pod-static -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 2
done
kubectl exec -it test-azurefile-pod-static -- /bin/bash -c "cat /data/out.txt"
kubectl exec -it test-azurefile-pod-static -- /bin/bash -c "wc -l /data/out.txt"
kubectl exec -it test-azurefile-pod-static -- /bin/bash -c "if [ -s '/data/out.txt' ]; then echo 'Success'; else echo 'Failed'; fi"

echo "Azure File Dynamic Provisioning Validation:"
while [[ $(kubectl get pods test-azurefile-pod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 2
done
kubectl exec -it test-azurefile-pod -- /bin/bash -c "cat /data/out.txt"
kubectl exec -it test-azurefile-pod -- /bin/bash -c "wc -l /data/out.txt"
kubectl exec -it test-azurefile-pod -- /bin/bash -c "if [ -s '/data/out.txt' ]; then echo 'Success'; else echo 'Failed'; fi"


# 3. Vertical Pod Autoscaler Validation:
echo "Vertical Pod Autoscaler Testing:"
kubectl apply -f 3_test_aks_vpa.yaml

echo "Vertical Pod Autoscaler Validation:"
pod_name=`kubectl get pod -l app=test-vpa --output=json | jq -r '.items[0].metadata.name'`
kubectl get pod ${pod_name} -o jsonpath='{.spec.containers[*].resources.requests}'
# {"cpu":"100m","memory":"50Mi"}
sleep 60
pod_name=`kubectl get pod -l app=test-vpa --output=json | jq -r '.items[0].metadata.name'`
kubectl get pod ${pod_name} -o jsonpath='{.spec.containers[*].resources.requests}'
# {"cpu":"587m","memory":"50Mi"}

kubectl get vpa test-vpa -o jsonpath='{.status.recommendation}' | jq


# 4. Horizontal Pod Autoscaler Validation:
echo "Horizontal Pod Autoscaler Testing:"
kubectl apply -f 4_test_aks_hpa.yaml

echo "Horizontal Pod Autoscaler Validation:"

# Function to check deployment status
check_deployment_ready() {
  local available_replicas=$(kubectl get deployment test-hpa-deploy -o jsonpath='{.status.availableReplicas}')
  local ready_replicas=$(kubectl get deployment test-hpa-deploy -o jsonpath='{.status.readyReplicas}')
  local desired_replicas=$(kubectl get deployment test-hpa-deploy -o jsonpath='{.spec.replicas}')

  if [[ "$available_replicas" -eq "$desired_replicas" && "$ready_replicas" -eq "$desired_replicas" ]]; then
    return 0
  else
    return 1
  fi
}

# Wait for the deployment to be ready
while ! check_deployment_ready; do
  sleep 2
done

kubectl get pods --selector=app=test-hpa
echo "Before:"
kubectl get hpa
# NAME       REFERENCE                    TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
# test-hpa   Deployment/test-hpa-deploy   cpu: <unknown>/50%   1         5         0          4s


kubectl run -i load-generator --rm --image=busybox -- /bin/sh -c "while sleep 0.001; do wget -q -O- http://test-hpa-svc.${TESTING_NAMESPACE}.svc.cluster.local; done" & PID=$!
sleep 40
kill -HUP $PID
kubectl delete pod load-generator

kubectl get pods --selector=app=test-hpa
echo "After:"
kubectl get hpa
# NAME       REFERENCE                    TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
# test-hpa   Deployment/test-hpa-deploy   cpu: 1%/50%   1         5         5          3m17s

