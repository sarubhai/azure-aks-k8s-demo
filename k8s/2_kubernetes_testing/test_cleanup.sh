#!/bin/bash
# Name: test_cleanup.sh
# Owner: Saurav Mitra
# Description: Test AKS Core Infrastructure Resources Cleanup

# Pre-requisite
# az, kubectl, envsubst, jq

# Set Context
export TESTING_NAMESPACE='testing'
kubectl config set-context --current --namespace=${TESTING_NAMESPACE}

export SUBSCRIPTION_ID='XXXX'
export RESOURCE_GROUP_NAME='azure-aks-k8s-demo-rg'
export RESOURCE_GROUP_LOCATION='germanywestcentral'


# 1. Azure Disk Validation Cleanup:
export AZURE_DISK_NAME='testAzurediskAksStaticPv'
export ZONE='1'
envsubst < 1_test_aks_azure_disk.yaml | kubectl delete -f -
az disk delete --resource-group ${RESOURCE_GROUP_NAME} --name ${AZURE_DISK_NAME} --yes


# 2. Azure File Validation Cleanup:
export AZURE_STORAGE_ACCOUNT='testazfilesa'
export FILE_SHARE_NAME='testazfileshare'
envsubst < 2_test_aks_azure_file.yaml | kubectl delete -f -
kubectl delete secret azure-secret
az storage share delete --name ${FILE_SHARE_NAME}
az storage account delete --name ${AZURE_STORAGE_ACCOUNT} --yes


# 3. Vertical Pod Autoscaler Validation Cleanup:
kubectl delete -f 3_test_aks_vpa.yaml


# 4. Horizontal Pod Autoscaler Validation Cleanup:
kubectl delete pod load-generator
kubectl delete -f 4_test_aks_hpa.yaml


# Delete Testing Namespace
kubectl delete namespace testing
