# Atom Docker Image For Package Testing

# based from the container published at docker hub
# https://registry.hub.docker.com/u/kn1kn1/atom-apm-test/
FROM kn1kn1/atom-apm-test:latest
MAINTAINER Kenichi Kanai <kn1kn1@users.noreply.github.com>

# Make Sure We're Up To Date
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Download And Install Atom
RUN \
  wget -nv -O atom-amd64.deb https://atom.io/download/deb && \
  DEBIAN_FRONTEND=noninteractive dpkg -i atom-amd64.deb && \
  DEBIAN_FRONTEND=noninteractive apt-get install -f && \
  rm -rf atom-amd64.deb
RUN \
  apm --version

# Add Package To `/root` Dir
ENV HOME /root
ADD . $HOME
WORKDIR /root

# Install Package Dependencies
RUN \
  apm install

# Start the Xvfb server with a display 99 and a virtual screen(monitor) 0.
RUN \
  start-stop-daemon --start --pidfile /tmp/xvfb_99.pid --make-pidfile \
    --background --exec /usr/bin/Xvfb -- :99 -screen 0 1024x768x24 -ac \
    +extension GLX +extension RANDR +render -noreset && \
  sleep 3 && \
  export DISPLAY=:99 && \
  apm test
