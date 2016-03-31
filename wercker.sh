#!/bin/sh

apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Download And Install Atom from Beta channel
wget -nv -O atom-amd64.deb https://atom.io/download/deb?channel=beta && \
DEBIAN_FRONTEND=noninteractive dpkg -i atom-amd64.deb && \
DEBIAN_FRONTEND=noninteractive apt-get install -f && \
rm -rf atom-amd64.deb

# Show version with apm-beta
apm-beta --version

# Install with apm-beta
apm-beta install

# Test with apm-beta
start-stop-daemon --start --pidfile /tmp/xvfb_99.pid --make-pidfile \
  --background --exec /usr/bin/Xvfb -- :99 -screen 0 1024x768x24 -ac \
  +extension GLX +extension RANDR +render -noreset && \
sleep 3 && \
export DISPLAY=:99 && \
apm-beta test -p /usr/bin/atom-beta
