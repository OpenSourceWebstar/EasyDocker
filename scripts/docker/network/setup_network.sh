#!/bin/bash

installDockerNetwork()
{
    # Check if the network already exists
    if ! dockerCommandRun "docker network inspect $CFG_NETWORK_NAME &> /dev/null"; then
        echo ""
        echo "################################################"
        echo "######      Create a Docker Network    #########"
        echo "################################################"
        echo ""

        isNotice "Network $CFG_NETWORK_NAME not found, creating now"
        # If the network does not exist, create it with the specified subnet
network_create=$(cat <<EOF
docker network create \
  --driver=bridge \
  --subnet=$CFG_NETWORK_SUBNET \
  --ip-range=$CFG_NETWORK_SUBNET \
  --gateway=${CFG_NETWORK_SUBNET%.*}.1 \
  --opt com.docker.network.bridge.name=$CFG_NETWORK_NAME \
  $CFG_NETWORK_NAME
EOF
)
        local result=$(dockerCommandRun "$network_create")
        checkSuccess "Creating docker network"
    fi
}