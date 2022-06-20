#!/bin/bash

# this runs before flux-setup.sh

echo "$(date +'%Y-%m-%d %H:%M:%S')  akdc-pre-flux start" >> "$HOME/status"

# change to this directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# create the tls secret
# this has to be installed before flux
if [ -f "$HOME/.ssh/certs.pem" ]
then
    kubectl create secret generic ssl-cert -n istio-system --from-file="key=$HOME/.ssh/certs.key" --from-file="cert=$HOME/.ssh/certs.pem"
fi

# create admin service account
kubectl create serviceaccount admin-user
kubectl create clusterrolebinding admin-user-binding --clusterrole cluster-admin --serviceaccount default:admin-user

if [ -f /home/akdc/.ssh/fluent-bit.key ]
then
    kubectl create ns fluent-bit
    kubectl create secret generic fluent-bit-secrets -n fluent-bit --from-file "$HOME/.ssh/fluent-bit.key"
fi

if [ -f /home/akdc/.ssh/prometheus.key ]
then
    kubectl create ns prometheus
    kubectl create secret -n prometheus generic prom-secrets --from-file "$HOME/.ssh/prometheus.key"
fi

# add the iot extension
az extension add -n azure-iot

# azure iot secrets
echo "IOTHUB_CONNECTION_STRING=$(az iot hub connection-string show --hub-name voe-iot-hub -o tsv)" > "$HOME/.ssh/iot.env"
echo "IOTEDGE_DEVICE_CONNECTION_STRING=$(az iot hub device-identity connection-string show --hub-name voe-iot-hub --device-id "$(hostname)" -o tsv)" >> "$HOME/.ssh/iot.env"

# azure cognitive services secrets
echo "ENDPOINT=$(az cognitiveservices account show -n voe -g voe-iot --query properties.endpoint -o tsv)" > "$HOME/.ssh/acs.env"
echo "TRAINING_KEY=$(az cognitiveservices account keys list -n voe -g voe-iot --query key1 -o tsv)" >> "$HOME/.ssh/acs.env"


if [ -n "$(find ./bootstrap/* -iregex '.*\.\(yaml\|yml\|json\)' 2>/dev/null)" ]
then
    kubectl apply -f ./bootstrap
    kubectl apply -R -f ./bootstrap
fi

echo "$(date +'%Y-%m-%d %H:%M:%S')  akdc-pre-flux complete" >> "$HOME/status"
