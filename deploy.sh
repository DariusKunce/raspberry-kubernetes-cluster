#!/bin/bash 

# 1. Builds ASP.NET Core app
# 2. Builds and pushed Docker image to a private image repo.
# 3. Creates Deployment and Service resources on Kubernetes kluster.

# Build ASP.NET Core app
dotnet publish -c Release -o published

# Build and publish Docker image
docker build -t 192.168.1.251:5000/aspnet-api:1.0.0 .
docker push 192.168.1.251:5000/aspnet-api:1.0.0

# Create Kubernetes resources
kubectl apply -f ./kubernetes_deployment.yaml
kubectl expose deployment aspnet-api-deployment --type=LoadBalancer --name=asp-net-api-service