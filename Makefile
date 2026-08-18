.PHONY: help \
	create-cluster \
	check-cluster \
	delete-cluster \
	deploy-argocd-apps \
	clean

# --------------------
# Configuration
# --------------------
CLUSTER_NAME ?= demo
NODES ?= 3

# --------------------
# Helpers
# --------------------
help:
	@echo "Usage: make <target> [VARIABLE=value]"
	@echo "Targets:"
	@echo "  create-cluster         Render k3d config, create cluster, install Calico"
	@echo "  check-cluster          Run cluster health checks"
	@echo "  delete-cluster         Delete the k3d cluster"
	@echo "  deploy-argocd-apps     Deploy ArgoCD applications (e.g. headlamp)"
	@echo "  clean                  Alias for delete-cluster"

# --------------------
# Create cluster
# --------------------
create-cluster:
	@bash scripts/create_cluster.sh $(CLUSTER_NAME) $(NODES)

# --------------------
# Cluster checks
# --------------------
check-cluster:
	@bash scripts/check_cluster.sh $(CLUSTER_NAME) 120

# --------------------
# Deploy ArgoCD applications
# --------------------
deploy-argocd-apps:
	@bash scripts/deploy_argocd_apps.sh	

# --------------------
# Delete / clean
# --------------------
delete-cluster:
	@bash scripts/delete_cluster.sh $(CLUSTER_NAME)

clean: delete-cluster
