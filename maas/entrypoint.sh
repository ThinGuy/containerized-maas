#!/bin/bash

systemctl="$(command -v systemctl)"

CMD="$1"
shift
args=""
if [ $# -gt 0 ]; then
    args="$(printf "%q " "$@")"
fi

case "$CMD" in
    maas|/snap/bin/maas)
        CMD="snap run maas"
        stdin_mode=null
        ;;
esac

. /etc/lsb-release


if [ ! -e /var/lib/apt/lists ]; then
    apt-get update
fi

cat > /usr/local/bin/docker_commandline.sh <<EOF
#!/bin/bash
# Default environment variables

# Recreate the initial environment from docker run
$(export -p)

# Force these environment variables
export PATH="/snap/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export SNAPCRAFT_BUILD_ENVIRONMENT=host
export SNAPCRAFT_MANAGED_MODE=y

# Run the command
echo "Executing: '$CMD $args'"
$CMD $args
/bin/systemctl exit \$?
EOF
chmod +x /usr/local/bin/docker_commandline.sh

cat > /etc/systemd/system/docker-exec.service <<EOF
[Unit]
Description=Docker commandline
Wants=snapd.seeded.service
After=snapd.service snapd.socket snapd.seeded.service

[Service]
ExecStartPre=/bin/bash -c '/usr/bin/snap install /snapd.snap --dangerous < /dev/null'
ExecStartPre=/bin/bash -c '/usr/bin/snap install maas < /dev/null'
ExecStart=/usr/local/bin/docker_commandline.sh
Environment="SNAPPY_LAUNCHER_INSIDE_TESTS=true"
Environment="LANG=en_US.UTF-8"
Restart=no
Type=oneshot
StandardInput=tty
StandardOutput=tty
StandardError=tty
WorkingDirectory=$PWD

[Install]
WantedBy=default.target
EOF

"$systemctl" enable docker-exec.service


# The presence of either .dockerenv or /run/.containerenv cause maas to
# incorrectly stage more than it should (e.g. libc and systemd). Remove them.
if [ -f /.dockerenv ]; then
    rm -f /.dockerenv
fi
if [ -f /run/.containerenv ]; then
    umount /run/.containerenv
    rm -f /run/.containerenv
fi

if grep -q securityfs /proc/filesystems; then
    mount -o rw,nosuid,nodev,noexec,relatime securityfs -t securityfs /sys/kernel/security
fi
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /run/lock
exec /lib/systemd/systemd --system --system-unit docker-exec.service
