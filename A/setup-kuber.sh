#!/bin/bash

main () {
    pre_setup
    setup_kubernetes
}

pre_setup () {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install git -y
    apt-get install python3-venv -y
}

setup_kubernetes () {
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    source venv/bin/activate
    pip install -r requirements.txt
    declare -r CLUSTER_FOLDER='my-cluster'
    cp -rfp inventory/local inventory/$CLUSTER_FOLDER
    USERNAME=$(whoami)
    ansible-playbook -i inventory/$CLUSTER_FOLDER/hosts.ini --connection=local -b -v cluster.yml
}

