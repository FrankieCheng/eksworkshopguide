1. EKSLabIDE Setup (10 mins)
    cloud9 already installed. so only need to upgrade 30g
    https://us-east-2.console.aws.amazon.com/cloud9/home?region=us-east-2
    
    install kubernates tools
    https://www.eksworkshop.com/020_prerequisites/k8stools/

    update iam setting for workspace
    https://www.eksworkshop.com/020_prerequisites/workspaceiam/

    clone the service
    https://www.eksworkshop.com/020_prerequisites/clone/

    install eksctl
    https://www.eksworkshop.com/030_eksctl/prerequisites/

    configure cluster
    aws eks --region us-east-2 update-kubeconfig --name eksworkshop-eksctl

    Configure console credentials
    https://www.eksworkshop.com/030_eksctl/console/
    Check:https://us-east-2.console.aws.amazon.com/eks/home?region=us-east-2#/clusters/eksworkshop-eksctl?selectedTab=cluster-compute-tab

2. Install helm and deploy nginx with helm (10 mins)
    
    Install helm (2 mins)
    https://www.eksworkshop.com/beginner/060_helm/helm_intro/install/

    Deploy nginx: (3 mins)
    https://www.eksworkshop.com/beginner/060_helm/helm_nginx/
        
    Deploy microservices with helm:
    https://www.eksworkshop.com/beginner/060_helm/helm_micro/

3 . Exposing a service (15mins)
    https://www.eksworkshop.com/beginner/130_exposing-service/

4 . Kapenter (15 mins)
    https://www.eksworkshop.com/beginner/085_scaling_karpenter/
        
5 . observability (20 mins)
    https://www.eksworkshop.com/intermediate/240_monitoring/

6 . logging (20 mins)
    https://www.eksworkshop.com/intermediate/230_logging/