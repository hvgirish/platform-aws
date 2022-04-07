This is an opinionated platform development repo loosely based on work from the [aws-samples](https://github.com/aws-samples/eks-gitops-crossplane-argocd) repo and my understanding of the best way to build and operate a self-service platform on AWS

The high level summary of the approach is to create the platform services in the following order

1. A `foundation` module based on terraform/cdk that consists of
   * AWS Orgs/SSO/PermissionSets
   * VPCs, subnets, (NAT/Transit)gateways, route tables and label them appropriately for use in crossplane composition
2. Management EKS Cluster with ArgoCD in `mgmt-cluster` based on eksctl/terraform/cdk/shell -- pick your poison
3. Crossplane configuration for all infrastructure buildout like EKS, EC2, RDS, S3, SQS in `crossplane-configuration` folder 
4. The workload EKS Clusters and VMs managed as crossplane compositions in `environments/<>/region/<resource-name>` modules