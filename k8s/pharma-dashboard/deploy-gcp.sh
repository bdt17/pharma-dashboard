#!/bin/bash
set -e

# Authenticate
gcloud auth login
gcloud container clusters get-credentials pharma-cluster --zone us-west1-b --project your-gcp-project-id

# Create secrets
kubectl create secret generic pharma-secrets \
  --namespace=pharma-transport \
  --from-literal=postgres-password=securepass123 \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy everything
kubectl apply -f gke-cluster.yaml
kubectl apply -f ingress-hpa.yaml  
kubectl apply -f services-db.yaml

echo "✅ Pharma Transport deployed to GKE!"
echo "🌐 Live at: pharmatransport.org"
