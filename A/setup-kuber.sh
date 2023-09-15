#!/bin/bash

set -x

main () {
    pre_setup
    setup_kubernetes
    move_config_file
}

pre_setup () {
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update
    sudo apt-get install git -y
    sudo apt-get install python3-venv -y
    sudo apt-get install python3 -y
    pip install virtualenv
    python3 -m virtualenv envsp

}

setup_kubernetes () {
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    source venv/bin/activate || source envsp/bin/activate
    pip install -r requirements.txt
    declare -r CLUSTER_FOLDER='my-cluster'
    cp -rfp inventory/local inventory/$CLUSTER_FOLDER
    USERNAME=$(whoami)
    ansible-playbook -i inventory/$CLUSTER_FOLDER/hosts.ini --connection=local -b -v cluster.yml
}

move_config_file () {
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

main