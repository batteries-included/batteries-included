#!/usr/bin/env bash
#
shopt -s nullglob

systemctl stop containerd k3s || true

find /sys/fs/cgroup/systemd/system.slice/containerd.service* \
  /sys/fs/cgroup/systemd/kubepods* \
  /sys/fs/cgroup/kubepods* \
  -name cgroup.procs -print0 | xargs -0 -r cat | xargs -r kill -9
mount | awk '/\/var\/lib\/kubelet|\/run\/netns|\/run\/containerd/ {print $3}' | xargs -r umount
rm -rf /var/lib/rancher/ /var/lib/containerd /etc/rancher /run/containerd/ /var/lib/cni/
systemctl start k3s
