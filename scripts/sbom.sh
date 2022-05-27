#!/bin/sh

echo "Updating SBOM..."
docker build -t ottosk8slab.azurecr.io/simplegoservice:latest .
trivy image --format cyclonedx --output sbom.json ottosk8slab.azurecr.io/simplegoservice:latest