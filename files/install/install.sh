# Repositories
echo 'deb http://packages.debian.org jessie stable' >> /etc/apt/sources.list

# Install general
apt-get install -qy --force-yes --no-install-recommends wget \
                                                        unzip

# Install window manager and x-server
apt-get install -qy --force-yes --no-install-recommends vnc4server \
                                                        x11-xserver-utils \
                                                        openbox \
							xfonts-base \
							xfonts-100dpi \
							xfonts-75dpi \
							libfuse2

# Install xrdp
apt-get install -qy --force-yes --no-install-recommends xrdp

# Install runit referenced and needed in "my_init" Python script
apt-get install -qy --force-yes --no-install-recommends runit

# Install Guac
apt-get install -qy --force-yes --no-install-recommends openjdk-8-jdk \
							libossp-uuid-dev \
                                                        libpng12-dev \
                                                        libfreerdp-dev \
                                                        libcairo2-dev \
                                                        tomcat8 \
                                                        guacamole

# Install less
apt-get install -qy --force-yes --no-install-recommends less

# Python Skripten bereitstellen
# /sbin/setuser und /sbin/my_init (launched when the container is started)
