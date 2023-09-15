#!/bin/bash

#set -e
set -x
export HOME_DIR="/home/ubuntu"
export PROJECT_DIR="$HOME_DIR/project"
export IP=""

main () {
    pre_setup
    download_and_install_helm
    get_and_apply_bare_metal_nginx_ingress_controller
    get_and_apply_cert-manager
    get_and_apply_cluster-issuer
    setup_haproxy
    get_ingress_nginx_http_and_https_port
    config_and_restart_haproxy
}

pre_setup () {
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update
    sudo apt-get install git -y
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
}

download_and_install_helm () {
    wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz
    tar -xvzf helm-v3.6.3-linux-amd64.tar.gz
    chmod +x linux-amd64/helm
    sudo mv linux-amd64/helm /usr/bin/
}

get_and_apply_bare_metal_nginx_ingress_controller () {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml
}

get_and_apply_cert-manager () {
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.yaml
}

get_and_apply_cluster-issuer () {
    git clone https://github.com/erfanmazraei/useful-k8s-manifest.git
    kubectl apply -f  useful-k8s-manifest/cluster-issuer.yml
}

setup_haproxy () {
    sudo apt-get install haproxy -y
}

get_ingress_nginx_http_and_https_port () {
    HTTP_PORT_NUMBER=`kubectl -n ingress-nginx get svc ingress-nginx-controller | tail -n +2 | grep -o '80:[0-9]\+/TCP' | cut -d':' -f2 | cut -d'/' -f1`
    HTTPS_PORT_NUMBER=`kubectl -n ingress-nginx get svc ingress-nginx-controller | tail -n +2 | grep -o '443:[0-9]\+/TCP' | cut -d':' -f2 | cut -d'/' -f1`
}

config_and_restart_haproxy () {
    echo "frontend site-http" > $PROJECT_DIR/tmp.txt
    echo -e "\tmode tcp" >> $PROJECT_DIR/tmp.txt
    echo -e "\tbind :80" >> $PROJECT_DIR/tmp.txt
    echo -e "\tdefault_backend http_api_backend" >> $PROJECT_DIR/tmp.txt
    echo "frontend site-https" >> $PROJECT_DIR/tmp.txt
    echo -e "\tmode tcp" >> $PROJECT_DIR/tmp.txt
    echo -e "\tbind :443" >> $PROJECT_DIR/tmp.txt
    echo -e "\tdefault_backend https_api_backend" >> $PROJECT_DIR/tmp.txt
    echo "backend http_api_backend" >> $PROJECT_DIR/tmp.txt
    echo -e "\tmode tcp" >> $PROJECT_DIR/tmp.txt
    echo -e "\toption tcp-check" >> $PROJECT_DIR/tmp.txt
    echo -e "\tserver node1 $IP:$HTTP_PORT_NUMBER check" >> $PROJECT_DIR/tmp.txt
    echo "backend https_api_backend" >> $PROJECT_DIR/tmp.txt
    echo -e "\tmode tcp" >> $PROJECT_DIR/tmp.txt
    echo -e "\toption tcp-check" >> $PROJECT_DIR/tmp.txt
    echo -e "\tserver node1 $IP:$HTTPS_PORT_NUMBER check" >> $PROJECT_DIR/tmp.txt

    sudo cat $PROJECT_DIR/tmp.txt >> /etc/haproxy/haproxy.cfg

    sudo service haproxy restart

    cd $HOME_DIR
}



main