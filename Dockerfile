# Atom Docker Image For Package Testing
FROM ubuntu:trusty
MAINTAINER Kenichi Kanai <kn1kn1@users.noreply.github.com>

ENV HOME /root
ADD . $HOME

# Make Sure We're Up To Date
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

# Install Required Packages For Atom
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git gconf2 gconf-service libgtk2.0-0 libnotify4 libxtst6 libnss3 python gvfs-bin xdg-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y xvfb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget

# Download And Install Atom
RUN wget -O atom-amd64.deb https://atom.io/download/deb -nv
RUN DEBIAN_FRONTEND=noninteractive dpkg -i atom-amd64.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -f
RUN rm -rf atom-amd64.deb
RUN apm --version

# Install Package Dependencies
RUN cd $HOME && apm install

# Start the Xvfb server with a display 99 and a virtual screen(monitor) 0.
RUN start-stop-daemon --start --pidfile /tmp/xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -screen 0 1024x768x24 -ac +extension GLX +extension RANDR +render -noreset && \
    sleep 3 && \
    export DISPLAY=:99 && \
    cd $HOME && \
    apm test
