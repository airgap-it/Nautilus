#!/bin/bash

build_tezos () {

    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    DEPLOYMENT_ENV="$1"
    WORKING_DIR="$2"
    PATH_TO_CONFIG="$3"

    #volumes creation for persistent storage
    [[ -d $HOME/volumes ]] || mkdir $HOME/volumes
    [[ -d $HOME/volumes/tznode_data-"$DEPLOYMENT_ENV" ]] || mkdir $HOME/volumes/tznode_data-"$DEPLOYMENT_ENV"
    [[ -d $HOME/volumes/tzclient_data-"$DEPLOYMENT_ENV" ]] || mkdir $HOME/volumes/tzclient_data-"$DEPLOYMENT_ENV"
    #stop and remove current container
    docker container stop tezos-node-"$DEPLOYMENT_ENV"
	docker container rm tezos-node-"$DEPLOYMENT_ENV"

    #createdocker volumes
    docker volume create --driver local --opt type=none --opt o=bind --opt device=$HOME/volumes/tznode_data-"$DEPLOYMENT_ENV" tznode_data-"$DEPLOYMENT_ENV"
    docker volume create --driver local --opt type=none --opt o=bind --opt device=$HOME/volumes/tzclient_data-"$DEPLOYMENT_ENV" tzclient_data-"$DEPLOYMENT_ENV"

	#make tezos subdirectory
    TEZOS_WORK_DIR="$WORKING_DIR"/tezos_"$build_time"/tezos-node-"$DEPLOYMENT_ENV"
    mkdir "$TEZOS_WORK_DIR"

    #copy dockerfile from nautilus
    cp "$DIR"/dockerfile "$TEZOS_WORK_DIR"/dockerfile
    {
    read line1
    } < "$PATH_TO_CONFIG"/tezos/tezos_network.txt

    tezosnetwork="$line1"
    #replace tezos network in dockerfile
    tz_dockerfile="$TEZOS_WORK_DIR"/dockerfile
    sed -i "s/protocol/$tezosnetwork/g" "$tz_dockerfile"
    cd "$TEZOS_WORK_DIR"

    #build and run docker container
    docker build -f "$DIR"/dockerfile -t tezos-node-"$DEPLOYMENT_ENV" .
    docker run --name=tezos-node-"$DEPLOYMENT_ENV" --network=nautilus -v tznode_data:/var/run/tezos/node-"$DEPLOYMENT_ENV" -v tzclient_data:/var/run/tezos/client-"$DEPLOYMENT_ENV" -d -p 8732:8732 -p 9732:9732 tezos-node-"$DEPLOYMENT_ENV"
}