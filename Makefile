.PHONY: help all port ip prepare create destroy start stop

.DEFAULT: help
ifndef VERBOSE
.SILENT:
endif

NO_COLOR=\033[0m
GREEN=\033[32;01m
YELLOW=\033[33;01m
RED=\033[31;01m

SHELL=bash
CWD:=$(shell pwd -P)
VERSION?=0.1.0

help:: ## Show this help
	echo -e "\nVersion \033[32m$(VERSION)\033[0m"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(YELLOW)%-20s$(NO_COLOR) %s\n", $$1, $$2}'

prepare-minikube: ## Prepare Hex env
	eval $(minikube docker-env)
	kubectl config set-context minikube

port: ## Find the port used by the production service
	kubectl -n production get services | grep /TCP | awk -F'80:' '{print $$2}' | awk -F'/TCP' '{print $$1}'

service: ## Find the external IP used by the production service`
	kubectl -n production get services

create:
	kubectl -n production create -f k8s/namespace-production.yaml

destroy:
	kubectl -n production delete -f k8s/namespace-production.yaml

start:
	kubectl -n production create -f k8s/cluster_roles.yaml
	kubectl -n production create -f k8s/deployment.yaml
	kubectl -n production create -f k8s/service.yaml
	kubectl -n production create -f k8s/secrets.yaml
	kubectl -n production create configmap vm-config \
	  --from-literal=name=${MY_BASENAME}@${MY_POD_IP} \
	  --from-literal=setcookie=${ERLANG_COOKIE} \
	  --from-literal=smp=auto
	# kubectl -n production create -f k8s/ingress.yaml

stop:
	kubectl -n production delete -f k8s/cluster_roles.yaml
	kubectl -n production delete -f k8s/deployment.yaml
	kubectl -n production delete -f k8s/service.yaml
	kubectl -n production delete -f k8s/secrets.yaml
	kubectl -n production delete configmap vm-config
	# kubectl -n production delete -f k8s/ingress.yaml
