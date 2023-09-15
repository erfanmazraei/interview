#!/bin/bash

set -x

main () {
    add_helm_chart_repo_and_update_repo
    install_or_upgrade_wordpress_by_helm_chart
}

add_helm_chart_repo_and_update_repo () {
    helm repo add erfanmazraei https://erfanmazraei.github.io/helm-charts/
    helm repo update
}

install_or_upgrade_wordpress_by_helm_chart () {
    helm upgrade --install wordpress erfanmazraei/wordpress
}

main