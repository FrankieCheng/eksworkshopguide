1.Create the graviton node group (10mins).
```bash
. ~/environment/eks-workshop-create-cluster/eks-graviton2-create-nodegroup.sh
```
* Please use the following code to check the node arch.
```bash
kubectl get nodes --label-columns=kubernetes.io/arch
```

2.Deploy the sample application on arm64 and x86
```bash
. ~/environment/eks-workshop-create-cluster/eks-graviton2-deploy.sh
```
* deploy the application on both x86 and arm64(Graviton)