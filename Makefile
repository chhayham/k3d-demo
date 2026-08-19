.PHONY: help prereqs create-cluster check-cluster deploy-argocd-apps install clean delete-cluster reset

# --------------------
# Configuration
# --------------------
CLUSTER_NAME ?= demo
NODES ?= 3

# --------------------
# Helpers
# --------------------
help:
	@echo "Usage: make <target> [CLUSTER_NAME=mycluster NODES=3]"
	@echo ""
	@echo "Targets:"
	@echo "  prereqs             Verify required tools (k3d, kubectl, helm)"
	@echo "  create-cluster      Create the k3d cluster"
	@echo "  check-cluster       Verify cluster health"
	@echo "  deploy-argocd-apps  Deploy ArgoCD applications"
	@echo "  install             Run prereqs, create, check, and deploy"
	@echo "  reset               Delete and recreate the cluster"
	@echo "  delete-cluster      Delete the k3d cluster"
	@echo "  clean               Alias for delete-cluster"

# --------------------
# Prerequisites
# --------------------
prereqs:
	@which k3d >/dev/null || { echo "Error: k3d not found. Please install k3d."; exit 1; }
	@which kubectl >/dev/null || { echo "Error: kubectl not found. Please install kubectl."; exit 1; }
	@which helm >/dev/null || { echo "Error: helm not found. Please install helm."; exit 1; }

# --------------------
# Create cluster
# --------------------
create-cluster: prereqs
	@echo ">>> Creating cluster $(CLUSTER_NAME) with $(NODES) nodes..."
	@bash scripts/create_cluster.sh $(CLUSTER_NAME) $(NODES)

# --------------------
# Cluster checks
# --------------------
check-cluster:
	@echo ">>> Checking cluster health for $(CLUSTER_NAME)..."
	@bash scripts/check_cluster.sh $(CLUSTER_NAME) 120

# --------------------
# Deploy ArgoCD applications
# --------------------
deploy-argocd-apps: check-cluster
	@echo ">>> Deploying ArgoCD applications for $(CLUSTER_NAME)..."
	@bash scripts/deploy_argocd_apps.sh $(CLUSTER_NAME)

# --------------------
# Install (All in one)
# --------------------
install: create-cluster deploy-argocd-apps
	@echo ">>> Installation complete!"

# --------------------
# Reset
# --------------------
reset: delete-cluster create-cluster
	@echo ">>> Cluster reset complete."

# --------------------
# Delete / clean
# --------------------
delete-cluster:
	@echo ">>> Deleting cluster $(CLUSTER_NAME)..."
	@bash scripts/delete_cluster.sh $(CLUSTER_NAME)

clean: delete-cluster.PHONY: help \
	create-cluster \
	check-cluster \
	delete-cluster \
	deploy-argocd-apps \
	clean
