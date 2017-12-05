#!/bin/bash
set -euox pipefail
IFS=$'\n\t'

az group deployment create \
--template-file 02.azuredeploy.json \
--parameters @02.azuredeploy.parameters.json