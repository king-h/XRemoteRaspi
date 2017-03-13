# Repositories
echo 'deb http://packages.debian.org jessie stable' >> /etc/apt/sources.list

# Install general
apt-get install -qy --force-yes --no-install-recommends wget \
                                                        unzip

# Install "Openbox" (window manager) and a leightweight VNC-/X-server combination
# called "vnc4server" (details see: http://www.butschek.de/fachartikel/vnc4server/).
apt-get install -qy --force-yes --no-install-recommends vnc4server \
                                                        x11-xserver-utils \
							xfonts-base \
							xfonts-100dpi \
							xfonts-75dpi \
                                                        openbox \
							openbox-themes \
							obconf \
							obmenu \
							xterm \
							firefox-esr \
							libfuse2

# Install "xrdp" (e.g. to allow connecting via "Windows Remote Desktop")
apt-get install -qy --force-yes --no-install-recommends xrdp

# Install network tools like "telnet" and "net-tools" (including "netstat") for testing purposes
apt-get install -qy --force-yes --no-install-recommends telnet net-tools

# Install runit referenced and needed in "my_init" Python script
apt-get install -qy --force-yes --no-install-recommends runit

# Install "Guacamole" web client web application in combination with "Apache Tomcat"
# and the "VNC support plugin for Guacamole" (for a web-based access without a dedicated client software)
apt-get install -qy --force-yes --no-install-recommends openjdk-8-jdk \
							libossp-uuid-dev \
                                                        libpng12-dev \
                                                        libfreerdp-dev \
                                                        libcairo2-dev \
                                                        tomcat8 \
                                                        guacamole \
							libguac-client-vnc0

# Install "less" (for easily reading/tailing files)
apt-get install -qy --force-yes --no-install-recommends less

# Python Skripten bereitstellen
# /sbin/setuser und /sbin/my_init (launched when the container is started)
