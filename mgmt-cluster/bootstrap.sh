
## ArgoCD

eksctl create cluster --name platform \
	--region=eu-west-1 \
	--zones=eu-west-1a,eu-west-1b,eu-west-1c \
	--without-nodegroup --with-oidc \
	--vpc-cidr 10.20.0.0/16 \
	--tags "creator=girish"

eksctl create nodegroup --cluster platform \
	--name ng-platform \
	--node-private-networking \
	--ssh-access --ssh-public-key=/Users/gvenkatappa/.ssh/id_rsa.pub \
	--nodes 3

eksctl utils set-public-access-cidrs --cluster=<cluster> $(curl -s v4.ident.me)/32

# kubectx/kubens into the new cluster/namespace

# security groups for pods
# kubectl set env daemonset aws-node -n kube-system ENABLE_POD_ENI=true

# Full ArgoCD for demo
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose via LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# set argocd admin password
# kubectl -n argocd get secret argocd-initial-admin-secret --template={{.data.password}} | base64 -D; echo
# argocd login ARGOCD_LOAD_BALANCER_DNS_NAME
# argocd account update-password
# kubectl -n argocd delete secret argocd-initial-admin-secret

# github known-hosts
kubectl apply -f argocd-setup-ssh-known-hosts-configmap.yaml

# helm repos for crossplane stuff
kubectl apply -f argocd-setup-helm-repositories.yaml 

# Install crossplane within a project
kubectl apply -f crossplane-project.yaml

# Use App of Apps instead
# argocd app create --file crossplane-application.yaml

# Install crossplane

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane --create-namespace --namespace crossplane-system crossplane-stable/crossplane

kubectl apply -f ../crossplane-complete/templates/4-aws-provider.yaml
kubectl apply -f ../crossplane-complete/templates/5-aws-providerconfig.yaml

# After crossplane-aws-provider is installed, grab the unique serviceaccount and create IAM Role for it
# Create EKSFullAccess and IAMLimitedAccess as per https://eksctl.io/usage/minimum-iam-policies/
eksctl create iamserviceaccount \
    --cluster "platform" \
    --region "eu-west-1" \
    --name="crossplane-provider-aws-bec8ce984e49" \
    --namespace="crossplane-system" \
    --role-name="platform-crossplane-provider-aws" \
    --role-only \
    --attach-policy-arn="arn:aws:iam::<account-id>:policy/EKSFullAccess" \
    --override-existing-serviceaccounts \
    --approve

eksctl update iamserviceaccount \
    --cluster "platform" \
    --region "eu-west-1" \
    --name="crossplane-provider-aws-bec8ce984e49" \
    --namespace="crossplane-system" \
    --attach-policy-arn="arn:aws:iam::<account-id>:policy/EKSFullAccess" \
    --attach-policy-arn="arn:aws:iam::<account-id>:policy/IAMLimitedAccess" \
    --attach-policy-arn="arn:aws:iam::aws:policy/AmazonEC2FullAccess" \
    --approve
