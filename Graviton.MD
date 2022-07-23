1.Create the graviton node group (10mins).
```bash
. ~/environment/eksworkshopguide/eks-graviton2-create-nodegroup.sh
```
* Please use the following code to check the node arch.
```bash
kubectl get nodes --label-columns=kubernetes.io/arch
```

2.Deploy the sample application on arm64 and x86
```bash
. ~/environment/eksworkshopguide/eks-graviton2-deploy.sh
```
* deploy the application on both x86 and arm64(Graviton)
* use the following command to see the service status, and get the EXTERNAL-IP to access the service.
```bash
kubectl get svc
```
