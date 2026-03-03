.PHONY: help \
	create-cluster \
	check-cluster \
	delete-cluster \
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
	@echo "  clean                  Alias for delete"

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
# Delete / clean
# --------------------
delete-cluster:
	@bash scripts/delete_cluster.sh $(CLUSTER_NAME)

clean: delete-cluster
