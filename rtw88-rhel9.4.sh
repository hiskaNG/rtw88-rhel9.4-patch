lsusb
# Bus 002 Device 004: ID 0bda:b812 Realtek Semiconductor Corp. RTL88x2bu [AC1200 Techkey]

# https://github.com/lwfinger/rtw88

dnf groupinstall "Development Tools"
dnf install kernel-devel-$(uname -r) kernel-headers-$(uname -r)

podman pull docker.io/redhat/ubi9:9.4

mkdir -p /mnt/cdrom
mount -oloop,ro /data/images/rhel-9.4-x86_64-dvd.iso /mnt/cdrom

podman run --rm -it \
  --privileged \
  --network host \
  --security-opt label=disable \
  -v /mnt/cdrom:/mnt/cdrom:ro \
  -v /lib/modules:/lib/modules:rw \
  -v /lib/firmware:/lib/firmware:rw \
  -v /etc/modprobe.d:/etc/modprobe.d:rw \
  docker.io/redhat/ubi9:9.4 \
  bash -c "rm -f /etc/yum.repos.d/*.repo && \
  echo -e '[BaseOS]\nname=BaseOS\nbaseurl=file:///mnt/cdrom/BaseOS/\nenabled=1\nrepo_gpgcheck=0\n[AppStream]\nname=AppStream\nbaseurl=file:///mnt/cdrom/AppStream/\nenabled=1\nrepo_gpgcheck=0\n' > /etc/yum.repos.d/dvd.repo && \
           dnf install -y gcc make perl bc elfutils-libelf-devel kernel-headers-$(uname -r) kernel-devel-$(uname -r) git patch xz kmod && \
           git clone --depth 1 https://github.com/lwfinger/rtw88.git && \
           git clone --depth 1 https://github.com/lwfinger/rtw88-rhel9.4-patch.git && \
           cd rtw88 && \
           patch -p1 < ../rtw88-rhel9.4-patch/kawa12/rtw88-rhel9.4.patch && \
           make && make install && make install_fw && cp rtw88.conf /etc/modprobe.d/"

restorecon -RFv /lib/{modules,firmware} /etc/modprobe.d

umount /mnt/cdrom

modprobe -v rtw_8822bu
lsmod | grep _88
# rtw_8822bu             16384  0
# rtw_8822b             233472  1 rtw_8822bu
# rtw_usb                36864  1 rtw_8822bu
# rtw_core              319488  2 rtw_usb,rtw_8822b