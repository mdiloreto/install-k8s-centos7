# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh

# Add the NGINX Ingress Controller Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install the NGINX Ingress Controller
helm install my-nginx ingress-nginx/ingress-nginx --set controller.publishService.enabled=true

# Verify the installation
kubectl get pods -n default  # Check if the NGINX pods are running
kubectl get svc -n default   # You should see a service for the NGINX Ingress

# Additional command to see more details about the running Ingress Controller
kubectl get all -n default   # This will list all resources created under the default namespace

