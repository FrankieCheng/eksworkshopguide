#!/bin/bash
#deploy the 2048 game using helm.
export EKS_CLUSTER_VERSION=$(aws eks describe-cluster --name eksworkshop-eksctl --query cluster.version --output text)

if [ "`echo "${EKS_CLUSTER_VERSION} < 1.19" | bc`" -eq 1 ]; then     
    curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/examples/2048/2048_full.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | kubectl apply -f -
fi

if [ "`echo "${EKS_CLUSTER_VERSION} >= 1.19" | bc`" -eq 1 ]; then     
    curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/examples/2048/2048_full_latest.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | kubectl apply -f -
fi

#sleep 20 seconds for resource creation.
sleep 20
kubectl get ingress/ingress-2048 -n game-2048

#get the information about ingress.
export GAME_INGRESS_NAME=$(kubectl -n game-2048 get targetgroupbindings -o jsonpath='{.items[].metadata.name}')

kubectl -n game-2048 get targetgroupbindings ${GAME_INGRESS_NAME} -o yaml

#sleep 180 seconds for alb start up.
echo 'sleep 180 seconds for alb start, the alb url will print in the console after 180 seconds.'
sleep 180

#find the alb address for 2048 game.
export GAME_2048=$(kubectl get ingress/ingress-2048 -n game-2048 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo http://${GAME_2048}
