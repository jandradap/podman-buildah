FROM registry.access.redhat.com/ubi8:8.5


RUN useradd build; dnf -y module enable container-tools:rhel8; dnf -y update; dnf -y reinstall shadow-utils; dnf -y install podman buildah crun fuse-overlayfs /etc/containers/storage.conf; rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# Set up environment variables to note that this is
# not starting with usernamespace and default to
# isolate the filesystem with chroot.
ENV _BUILDAH_STARTED_IN_USERNS="" \
    BUILDAH_ISOLATION=chroot

RUN useradd -u 1000 -ms /bin/bash podman; \
    echo podman:100000:999999 >/etc/subuid; \
    echo podman:100000:999999 >/etc/subgid;

COPY files/podman-containers.conf /home/podman/.config/containers/containers.conf
COPY files/containers.conf /etc/containers/containers.conf

RUN chown podman:podman -R /home/podman

RUN mkdir -p /home/podman/.local/share/containers; chown podman:podman -R /home/podman

VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers

RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's/driver = "overlay"/driver = "vfs"/g' -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock; touch /var/lib/shared/vfs-images/images.lock; touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

WORKDIR /home/podman
