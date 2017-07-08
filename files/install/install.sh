############################
### ENVIRONMENTAL CONFIG ###
############################

# Configure existing user "nobody" for later usage
export DEBIAN_FRONTEND="noninteractive"
usermod -m -d /nobody nobody
usermod -s /bin/bash nobody
usermod -a -G adm,sudo nobody
echo "nobody:PASSWD" | chpasswd



#####################################
### REPOSITORIES AND DEPENDENCIES ###
#####################################

# Repositories
echo 'deb http://packages.debian.org stretch main contrib non-free rpi firmware' > /etc/apt/sources.list

# Install general tools (e.g. wget HTTP client, compressor, editor)
apt-get install -qy --force-yes --no-install-recommends wget \
                                                        unzip \
							vim

# Install "Openbox" (window manager) and a leightweight VNC-/X-server combination
# called "vnc4server" (details see: http://www.butschek.de/fachartikel/vnc4server/).
# The "menu" package is to integrate all existing programs in "openbox".
apt-get install -qy --force-yes --no-install-recommends vnc4server \
                                                        x11-xserver-utils \
							xfonts-base \
							xfonts-100dpi \
							xfonts-75dpi \
                                                        openbox \
							openbox-themes \
							obconf \
							obmenu \
							menu \
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
# and the "VNC support plugin for Guacamole" (for a web-based access without a dedicated client software).
# The "libguac-client-vnc0" library is necessary according to "https://packages.debian.org/jessie/net/guacamole"
apt-get install -qy --force-yes --no-install-recommends libossp-uuid-dev \
                                                        libpng12-dev \
                                                        libfreerdp-dev \
                                                        libcairo2-dev \
                                                        tomcat8 \
							tomcat8-admin \
							tomcat8-examples \
                                                        guacamole \
							libguac-client-vnc0

# Install "terminator" terminal for window manager "openbox"
apt-get install -qy --force-yes terminator

# Install "less" (for easily reading/tailing files)
apt-get install -qy --force-yes --no-install-recommends less

# Install Oracle JDK 8u131 for ARM as the packaged OpenJDK for Debian performs too slow when starting JDownloader
wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-arm32-vfp-hflt.tar.gz" -O jdk-8u131-linux-arm32-vfp-hflt.tar.gz
update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_131/jre/bin/java 1100



#########################################
### FILES, SERVICES AND CONFIGURATION ###
#########################################

# Configuring the "XVNC" service for the "runit" init daemon
mkdir -p /etc/sv/Xvnc
mkdir -p /etc/sv/Xvnc/log
mkdir -p /var/log/Xvnc

cat <<'EOT' > /etc/sv/Xvnc/run
#!/bin/bash
exec 2>&1
WD=${WIDTH:-1280}
HT=${HEIGHT:-720}

exec /usr/bin/sudo -u nobody Xvnc4 :1 -geometry ${WD}x${HT} -depth 16 -rfbwait 30000 -SecurityTypes None -rfbport 5901 -bs -ac \
				   -pn -fp /usr/share/fonts/X11/misc/,/usr/share/fonts/X11/75dpi/,/usr/share/fonts/X11/100dpi/ \
				   -co /etc/X11/rgb -dpi 96
EOT

cat <<'EOT' > /etc/sv/Xvnc/log/run
#!/bin/bash
exec svlogd -tt /var/log/Xvnc
EOT

ln -s /etc/sv/Xvnc /etc/service/Xvnc

# Configuring "xrdp" service for the "runit" init daemon
mkdir -p /etc/sv/xrdp
mkdir -p /etc/sv/xrdp/log
mkdir -p /var/log/xrdp

cat <<'EOT' > /etc/sv/xrdp/run
#!/bin/bash
exec 2>&1
RSAKEYS=/etc/xrdp/rsakeys.ini
    # Check for rsa key
    if [ ! -f $RSAKEYS ] || cmp $RSAKEYS /usr/share/doc/xrdp/rsakeys.ini > /dev/null; then
        echo "Generating xrdp RSA keys..."
        (umask 077 ; xrdp-keygen xrdp $RSAKEYS)
        chown root:root $RSAKEYS
        if [ ! -f $RSAKEYS ] ; then
            echo "could not create $RSAKEYS"
            exit 1
        fi
        echo "done"
    fi
exec /usr/sbin/xrdp --nodaemon
EOT

cat <<'EOT' > /etc/sv/xrdp/log/run
#!/bin/bash
exec svlogd -tt /var/log/xrdp
EOT

ln -s /etc/sv/xrdp /etc/service/xrdp

# Providing a custom "Xrdp" configuration file "xrdp.ini"
cat <<'EOT' > /etc/xrdp/xrdp.ini
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
allow_channels=true
max_bpp=16
fork=yes
crypt_level=low
security_layer=rdp
tcp_nodelay=yes
tcp_keepalive=yes
blue=009cb5
grey=dedede
autorun=xrdp1
bulk_compression=yes
new_cursors=yes
use_fastpath=both
hidelogwindow=yes

[xrdp1]
name=GUI_APPLICATION
lib=libvnc.so
username=nobody
password=PASSWD
ip=127.0.0.1
port=5901

[channels]
rdpdr=true
rdpsnd=true
drdynvc=true
cliprdr=true
rail=true
EOT

# Configuring "xrdp-sesman" service for the "runit" init daemon
mkdir -p /etc/sv/xrdp-sesman
mkdir -p /etc/sv/xrdp-sesman/log
mkdir -p /var/log/xrdp-sesman

cat <<'EOT' > /etc/sv/xrdp-sesman/run
#!/bin/bash
exec 2>&1

exec /usr/sbin/xrdp-sesman --nodaemon >> /var/log/xrdp-sesman_run.log 2>&1
EOT

cat <<'EOT' > /etc/sv/xrdp-sesman/log/run
#!/bin/bash
exec svlogd -tt /var/log/xrdp-sesman
EOT

ln -s /etc/sv/xrdp-sesman /etc/service/xrdp-sesman

# Providing a custom "sesman" configuration file "sesman.ini"
cat <<'EOT' > /etc/xrdp/sesman.ini
[Globals]
ListenAddress=127.0.0.1
ListenPort=3350
EnableUserWindowManager=true
UserWindowManager=startwm.sh
DefaultWindowManager=startwm.sh

[Security]
AllowRootLogin=true
MaxLoginRetry=4
TerminalServerUsers=tsusers
TerminalServerAdmins=tsadmins
AlwaysGroupCheck = false

[Sessions]
X11DisplayOffset=10
MaxSessions=50
KillDisconnected=false
IdleTimeLimit=0
DisconnectedTimeLimit=0
Policy=Default

[Logging]
LogFile=xrdp-sesman.log
LogLevel=DEBUG
EnableSyslog=1
SyslogLevel=DEBUG

[Xvnc]
param=Xvnc
param=-bs
param=-ac
param=-nolisten
param=tcp
param=-localhost
param=-dpi
param=96
EOT

# Configuring "openbox" window manager service for the "runit" init daemon
mkdir -p /etc/sv/openbox
mkdir -p /etc/sv/openbox/log
mkdir -p /var/log/openbox

cat <<'EOT' > /etc/sv/openbox/run
#!/bin/bash
exec 2>&1

exec env DISPLAY=:1 HOME=/nobody /usr/bin/sudo -u nobody /usr/bin/openbox-session
EOT

cat <<'EOT' > /etc/sv/openbox/log/run
#!/bin/bash
exec 2>&1
exec svlogd -tt /var/log/openbox
EOT

ln -s /etc/sv/openbox /etc/service/openbox

# Configuring "Tomcat 8" servlet container for the "runit" init daemon
mkdir -p /etc/sv/tomcat8
mkdir -p /etc/sv/tomcat8/log

cat <<'EOT' > /etc/sv/tomcat8/run
#!/bin/bash
exec 2>&1

touch /var/lib/tomcat8/logs/catalina.out

cd /var/lib/tomcat8

exec /usr/bin/java -Dguacamole.home=/etc/guacamole \
                   -Djava.util.logging.config.file=/var/lib/tomcat8/conf/logging.properties \
                   -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
                   -Djava.awt.headless=true -Xmx128m -XX:+UseConcMarkSweepGC \
                   -Djava.endorsed.dirs=/usr/share/tomcat8/endorsed \
                   -classpath /usr/share/tomcat8/bin/bootstrap.jar:/usr/share/tomcat8/bin/tomcat-juli.jar \
                   -Dcatalina.base=/var/lib/tomcat8 -Dcatalina.home=/usr/share/tomcat8 \
                   -Djava.io.tmpdir=/tmp/tomcat8-tomcat8-tmp org.apache.catalina.startup.Bootstrap start
EOT

cat <<'EOT' > /etc/sv/tomcat8/log/run
#!/bin/bash
exec svlogd -tt /var/log/tomcat8
EOT

ln -s /etc/sv/tomcat8 /etc/service/tomcat8

# Configuring "Guacamole" proxy server for "runit" init daemon
mkdir -p /etc/sv/guacd
mkdir -p /etc/sv/guacd/log
mkdir -p /var/log/guacd

cat <<'EOT' > /etc/sv/guacd/run
#!/bin/bash
exec 2>&1

exec /usr/sbin/guacd -f
EOT

cat <<'EOT' > /etc/sv/guacd/log/run
#!/bin/bash
exec svlogd -tt /var/log/guacd
EOT

ln -s /etc/sv/guacd /etc/service/guacd

# setting correct execution permission rights for above added custom runit scripts
find /etc/sv -name "run" -type f -exec chmod 755 {} \; -print

####################
### INSTALLATION ###
####################

# Download latest Guacamole package
wget --user-agent=Mozilla -H --max-redirect=10 -O /tmp/guacamole-0.9.12-incubating.war "http://mirror.23media.de/apache/incubator/guacamole/0.9.12-incubating/binary/guacamole-0.9.12-incubating.war"

# Download latest JDownloader JAR
wget http://installer.jdownloader.org/JDownloader.jar

# Install Guacamole web app on Tomcat
mv /tmp/guacamole-0.9.12-incubating.war /var/lib/tomcat8/webapps/guacamole.war

# Python Skripten bereitstellen
# /sbin/setuser und /sbin/my_init (launched when the container is started)
