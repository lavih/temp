#!/bin/bash
# Backup your data
# Use at your own risk
# Usage ./extended-cleanup-rancher2.sh
# Include clearing all iptables: ./extended-cleanup-rancher2.sh flush
containers=$(docker ps -qa)
[[ ! -z "$containers" ]] && docker rm -f $containers
images=$(docker images -q)
[[ ! -z "$images" ]] && docker rmi -f $images
volumes=$(docker volume ls -q)
[[ ! -z "$volumes" ]] && docker volume rm $volumes
for mount in $(mount | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done
cleanupdirs="/etc/ceph /etc/cni /etc/kubernetes /opt/cni /opt/rke /run/secrets/kubernetes.io /run/calico /run/flannel /var/lib/calico /var/lib/etcd /var/lib/cni /var/lib/kubelet /var/lib/rancher/rke/log /var/log/containers /var/log/pods /var/run/calico"
for dir in $cleanupdirs; do
  echo "Removing $dir"
  rm -rf $dir
done
cleanupinterfaces="flannel.1 cni0 tunl0"
for interface in $cleanupinterfaces; do
  echo "Deleting $interface"
  ip link delete $interface
done
if [ "$1" = "flush" ]; then
  echo "Parameter flush found, flushing all iptables"
  iptables -F -t nat
  iptables -X -t nat
  iptables -F -t mangle
  iptables -X -t mangle
  iptables -F
  iptables -X
  service docker restart
else
  echo "Parameter flush not found, iptables not cleaned"
fi



##################################################
# Customized cleanup in the right order
##################################################
# cleanup with the right order
# container
containers=$(docker ps -qa)
[[ ! -z "$containers" ]] && docker rm -f $containers
# volumes
volumes=$(docker volume ls -q)
[[ ! -z "$volumes" ]] && docker volume rm $volumes
# images
images=$(docker image ls -q)
[[ ! -z "$images" ]] && docker rmi -f $images
# interfaces
cleanupinterfaces="flannel.1 cni0 tunl0"
for interface in $cleanupinterfaces; do
  echo "Deleting $interface"
  ip link delete $interface
done
for mount in $(mount | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done
cleanupdirs="/etc/ceph /etc/cni /etc/kubernetes /opt/cni /opt/rke /run/secrets/kubernetes.io /run/calico /run/flannel /var/lib/calico /var/lib/etcd /var/lib/cni /var/lib/kubelet /var/lib/rancher/rke/log /var/log/containers /var/log/pods /var/run/calico"
for dir in $cleanupdirs; do
  echo "Removing $dir"
  rm -rf $dir
done
# iptables
iptables -F -t nat
iptables -X -t nat
iptables -F -t mangle
iptables -X -t mangle
iptables -F
iptables -X
# reaload docker
systemctl restart docker
