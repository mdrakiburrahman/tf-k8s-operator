# Create a TF namespace for Kubernetes operator
kubectl create namespace tfops

# Update the credentials.example file and rename credentials then create a K8s secret
kubectl create -n tfops secret generic terraformrc --from-file=credentials=tfops/credentials

# Create the follow env-variables in shell prior to running this script
export client_id='<your-client-id>'
export client_secret='<your-client-key>'
export tenant_id='<your-tenant>'
export subscription_id='<your-sub-id>'

# Create an env-variables configmap for non-secret values
cat > env-variables.yaml <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: azure-configuration
data:
  arm_tenant_id: $tenant_id
  arm_subscription_id: $subscription_id
  arm_client_id: $client_id
EOF

# Deployment Secrets
kubectl create secret -n tfops generic workspacesecrets --from-literal=ARM_CLIENT_SECRET=$client_secret \
--from-literal=sqlmi_administrator_login=$sqlmi_administrator_login \
--from-literal=sqlmi_administrator_password=$sqlmi_administrator_password

# Create the config map
kubectl apply -f env-variables.yaml -n tfops

# Install the terraform operator
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/terraform --devel
helm install --devel --namespace tfops hashicorp/terraform --generate-name

# Apply sqlmi.yaml to create the workspace and resources
kubectl apply -f tfops/sqlmi.yaml -n tfops

# Validate the process
kubectl describe workspace -n tfops sqlmi

# Delete the workspace
kubectl delete -f tfops/sqlmi.yaml -n tfops
