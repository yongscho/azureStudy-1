#!/bin/bash
set -eoux pipefail

while [ $# -gt 0 ]
do
  key="$1"
  case $key in
    -l|--location)
      LOCATION="$2"
      shift
      ;;
    -r|--resourcegroup)
      RESOURCE_GROUP_NAME="$2"
      ;;
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

#UTF-8 BOM 오류 때문에 URI를 모두 PATH로 바꿔서 파일형식을 UTF-8 BOM에서 UTF-8로 바꿈
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
BUILDINGBLOCKS_ROOT_PATH=${SCRIPT_DIR}/../../../../template-building-blocks-1.0.0/
BUILDINGBLOCKS_ROOT_URI="https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"


echo
echo "Using ${BUILDINGBLOCKS_ROOT_PATH} to locate templates"
echo "scripts=${SCRIPT_DIR}"
echo

VIRTUAL_NETWORK_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_PATH}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
MULTI_VMS_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_PATH}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
VPN_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_PATH}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"

ONPREM_VPN_TEMPLATE_FILE="${SCRIPT_DIR}/onprem.gateway.azuredeploy.json"

ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.virtualNetwork.parameters.json"
ONPREM_VM_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.vm.parameters.json"
ONPREM_VPN_GW_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.gateway.parameters.json"

# Create the resource group for the simulated on-prem environment, saving the output for later.
# --subscription --json is not valid option (by minsoo.jo)
#ONPREM_NETWORK_RESOURCE_GROUP_OUTPUT=$(az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1
ONPREM_NETWORK_RESOURCE_GROUP_OUTPUT=$(az group create --name $RESOURCE_GROUP_NAME --location $LOCATION) || exit 1

# Create the simulated on-prem virtual network
echo "Deploying on-prem simulated virtual network..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vnet-deployment" \
--template-file $VIRTUAL_NETWORK_TEMPLATE_URI --parameters @$ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE 

# Create the simulated on-prem Ubuntu VM
echo "Deploying on-prem Ubuntu VM..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vm-deployment" \
--template-file $MULTI_VMS_TEMPLATE_URI --parameters @$ONPREM_VM_PARAMETERS_FILE

# Install VPN gateway
echo "Deploying VPN gateway..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME --name "ra-onprem-vpn-gw-deployment" \
--template-file $ONPREM_VPN_TEMPLATE_FILE --parameters @$ONPREM_VPN_GW_PARAMETERS_FILE
