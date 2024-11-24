# Azure AKS Cluster Configuration Demo

Terraform Codebase to Deploy Azure AKS Cluster and Configuration of Kubernetes Cluster resources.

## Usage
- Clone this repository
- Generate & setup [Azure Service Principal credentials](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- Generate a Azure VM Key Pair in the location where you want to deploy stack
- Go to azure-aks directory
- Add the below variable values as Terraform Variables under workspace

### terraform.tfvars
```
ssh_public_key = "ssh-rsa .... /TU= generated-by-azure"

vpn_admin_password = "asdflkjhgqwerty1234"
```

- Add the below variable values as Environment Variables under workspace

### export
```
ARM_SUBSCRIPTION_ID="your_arm_subscription_id"

ARM_TENANT_ID="your_arm_tenant_id"

ARM_CLIENT_ID="your_client_id"

ARM_CLIENT_SECRET="your_client_secret"
```

- Add Azure Storage account as [Terraform State backend](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)
```
RESOURCE_GROUP_NAME=tf-backend-rg
STORAGE_ACCOUNT_NAME=yourstorageaccountname
CONTAINER_NAME=tf-state

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location germanywestcentral

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

# Set storage account Access Key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
export ARM_ACCESS_KEY=$ACCOUNT_KEY
```
- Modify backends.tf with your Resource group and Storage account name
- Change other variables in variables.tf file if needed

```
terraform init

terraform plan

terraform apply -auto-approve -refresh=false
```

- Login to openvpn_access_server_ip with user as openvpn & vpn_admin_password
- Download the VPN connection profile
- Download & use OpenVPN client to connect to Azure Virtual Network.
- Update your kubeconfig to connect to AKS cluster using kubectl or k9s

```
MY_RESOURCE_GROUP_NAME='azure-aks-k8s-demo-rg'

MY_AKS_CLUSTER_NAME='azure-aks-k8s-demo-aks-cluster'

az aks get-credentials --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_AKS_CLUSTER_NAME
```

### TO-DO
- Deploying Kubernetes Core Infrastructure Resources using Terraform Kubernetes Provider
- Testing the Kubenetes Resources to verify cluster stability