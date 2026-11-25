#!/bin/bash
# Plik wymiany 8 GB - zalecany na maszynach z <= 8 GB RAM (bench build / yarn zużywają dużo pamięci).
set -euo pipefail
SIZE="${1:-8G}"
if swapon --show | grep -q /swapfile; then echo "Swap /swapfile już istnieje"; swapon --show; exit 0; fi
sudo fallocate -l "$SIZE" /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
swapon --show
free -h
