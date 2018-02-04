############################
### ENVIRONMENTAL CONFIG ###
############################

# Configure existing user "nobody" for later usage
export DEBIAN_FRONTEND="noninteractive"
mkdir /nobody
usermod -m -d /nobody nobody
usermod -s /bin/bash nobody
usermod -a -G adm,sudo nobody
usermod -R nobody:users /nobody
echo "nobody:PASSWD" | chpasswd

#####################################
### REPOSITORIES AND DEPENDENCIES ###
#####################################

# Repositories (details see https://willy-tech.de/upgrade-auf-debian-9-alias-stretch/)
# echo 'deb http://deb.debian.org/debian stretch main contrib non-free' > /etc/apt/sources.list
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <missing_key>
echo 'deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi firmware' > sources.list
apt-get update

# Install general tools (e.g. wget HTTP client, compressor, editor)
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends wget \
                                                        unzip \
							vim

# Install "Openbox" (window manager) and a leightweight VNC-/X-server combination
# called "vnc4server" (details see: http://www.butschek.de/fachartikel/vnc4server/).
# The "menu" package is to integrate all existing programs in "openbox".
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends vnc4server \
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
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends xrdp

# Install network tools like "telnet" and "net-tools" (including "netstat") for testing purposes
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends telnet net-tools

# Install runit referenced and needed in "my_init" Python script
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends runit

# Install "Guacamole" web client web application in combination with "Apache Tomcat"
# and the "VNC support plugin for Guacamole" (for a web-based access without a dedicated client software).
# The "libguac-client-vnc0" library is necessary according to "https://packages.debian.org/jessie/net/guacamole"
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends libossp-uuid-dev \
                                                        tomcat8 \
							tomcat8-admin \
							tomcat8-examples \
                                                        guacamole \
							libguac-client-vnc0

# Installed after above step to meet dependencies
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends libpng12-dev \
                                                        libfreerdp-dev

# Installed after above step to meet dependencies
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends libcairo2-dev

# Install "terminator" terminal for window manager "openbox"
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages terminator

# Install "less" (for easily reading/tailing files)
apt-get install -qy --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends less

# Install "unrar" for ARM (to allow unpacking downloaded files)
wget --no-cookies --no-check-certificate https://www.rarlab.com/rar/unrar-5.5.0-arm.gz

# Install Oracle JDK 8u161 for ARM 32bit as the packaged OpenJDK for Debian performs too slow when starting JDownloader
wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-arm32-vfp-hflt.tar.gz" -O /tmp/jdk-8u161-linux-arm32-vfp-hflt.tar.gz
gunzip jdk-8u161-linux-arm32-vfp-hflt.tar.gz
tar -xvf /tmp/jdk-8u161-linux-arm32-vfp-hflt.tar -C /opt
update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_161/jre/bin/java 1100



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
; xrdp.ini file version number
ini_version=1

; fork a new process for each incoming connection
fork=yes
; tcp port to listen
port=3389
; regulate if the listening socket use socket option tcp_nodelay
; no buffering will be performed in the TCP stack
tcp_nodelay=true
; regulate if the listening socket use socket option keepalive
; if the network connection disappear without close messages the connection will be closed
tcp_keepalive=true

; security layer can be 'tls', 'rdp' or 'negotiate'
; for client compatible layer
security_layer=rdp
; minimum security level allowed for client
; can be 'none', 'low', 'medium', 'high', 'fips'
crypt_level=low
; X.509 certificate and private key
; openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 365
certificate=
key_file=
; specify whether SSLv3 should be disabled
#disableSSLv3=true
; set TLS cipher suites
#tls_ciphers=HIGH

; Section name to use for automatic login if the client sends username
; and password. If empty, the domain name sent by the client is used.
; If empty and no domain name is given, the first suitable section in
; this file will be used.
autorun=xrdp1

allow_channels=true
allow_multimon=false
bitmap_cache=true
bitmap_compression=yes
bulk_compression=true
hidelogwindow=true
max_bpp=16
new_cursors=true
; fastpath - can be 'input', 'output', 'both', 'none'
use_fastpath=both

;
; colors used by windows in RGB format
;
blue=009cb5
grey=dedede
#black=000000
#dark_grey=808080
#blue=08246b
#dark_blue=08246b
#white=ffffff
#red=ff0000
#green=00ff00
#background=626c72

;
; configure login screen
;

; Login Screen Window Title
ls_title=LibreElec Container Remote Control

; top level window background color in RGB format
ls_top_window_bg_color=009cb5

; width and height of login screen
ls_width=350
ls_height=430

; login screen background color in RGB format
ls_bg_color=dedede

; optional background image filename (bmp format).
#ls_background_image=

; logo
; full path to bmp-file or file in shared folder
ls_logo_filename=
ls_logo_x_pos=55
ls_logo_y_pos=50

; for positioning labels such as username, password etc
ls_label_x_pos=30
ls_label_width=60

; for positioning text and combo boxes next to above labels
ls_input_x_pos=110
ls_input_width=210

; y pos for first label and combo box
ls_input_y_pos=220

; OK button
ls_btn_ok_x_pos=142
ls_btn_ok_y_pos=370
ls_btn_ok_width=85
ls_btn_ok_height=30

; Cancel button
ls_btn_cancel_x_pos=237
ls_btn_cancel_y_pos=370
ls_btn_cancel_width=85
ls_btn_cancel_height=30

[channels]
; Channel names not listed here will be blocked by XRDP.
; You can block any channel by setting its value to false.
; IMPORTANT! All channels are not supported in all use
; cases even if you set all values to true.
; You can override these settings on each session type
; These settings are only used if allow_channels=true
rdpdr=true
rdpsnd=true
drdynvc=true
cliprdr=true
rail=true
xrdpvr=true
tcutils=true

[xrdp1]
name=VNC Remote
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=5901
EOT

# Configuring "xrdp-sesman" service for the "runit" init daemon
mkdir -p /etc/sv/xrdp-sesman
mkdir -p /etc/sv/xrdp-sesman/log
mkdir -p /var/log/xrdp-sesman

cat <<'EOT' > /etc/sv/xrdp-sesman/run
#!/bin/bash
exec 2>&1

exec /usr/sbin/xrdp-sesman --nodaemon >> /var/log/xrdp-sesman/xrdp-sesman_run.log 2>&1
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
; When AlwaysGroupCheck=false access will be permitted
; if the group TerminalServerUsers is not defined.
AlwaysGroupCheck = false

[Sessions]
;; X11DisplayOffset - x11 display number offset
; Type: integer
; Default: 10
X11DisplayOffset=10

;; MaxSessions - maximum number of connections to an xrdp server
; Type: integer
; Default: 0
MaxSessions=50

;; KillDisconnected - kill disconnected sessions
; Type: boolean
; Default: false
; if 1, true, or yes, kill session after 60 seconds
KillDisconnected=false

;; IdleTimeLimit - when to disconnect idle sessions
; Type: integer
; Default: 0
; if not zero, the seconds without mouse or keyboard input before disconnect
; not complete yet
IdleTimeLimit=0

;; DisconnectedTimeLimit - when to kill idle sessions
; Type: integer
; Default: 0
; if not zero, the seconds before a disconnected session is killed
; min 60 seconds
DisconnectedTimeLimit=0

;; Policy - session allocation policy
; Type: enum [ "Default" | "UBD" | "UBI" | "UBC" | "UBDI" | "UBDC" ]
; Default: Xrdp:<User,BitPerPixel> and Xvnc:<User,BitPerPixel,DisplaySize>
; "UBD" session per <User,BitPerPixel,DisplaySize>
; "UBI" session per <User,BitPerPixel,IPAddr>
; "UBC" session per <User,BitPerPixel,Connection>
; "UBDI" session per <User,BitPerPixel,DisplaySize,IPAddr>
; "UBDC" session per <User,BitPerPixel,DisplaySize,Connection>
Policy=Default

[Logging]
LogFile=xrdp-sesman.log
LogLevel=DEBUG
EnableSyslog=1
SyslogLevel=DEBUG

[Xorg]
param=Xorg
param=-config
param=xrdp/xorg.conf
param=-noreset
param=-nolisten
param=tcp

[Xvnc]
param=Xvnc
param=-bs
param=-ac
param=-nolisten
param=tcp
param=-localhost
param=-dpi
param=96

[Chansrv]
; drive redirection, defaults to xrdp_client if not set
FuseMountName=thinclient_drives

[SessionVariables]
PULSE_SCRIPT=/etc/xrdp/pulse/default.pa
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
wget --user-agent=Mozilla -H --max-redirect=10 -O /tmp/guacamole-0.9.13-incubating.war "http://mirror.23media.de/apache/incubator/guacamole/0.9.13-incubating/binary/guacamole-0.9.13-incubating.war"

# Download latest JDownloader JAR
mkdir /opt/jd2
wget http://installer.jdownloader.org/JDownloader.jar -O /opt/jd2/JDownloader.jar

# Install Guacamole web app on Tomcat
mv /tmp/guacamole-0.9.13-incubating.war /var/lib/tomcat8/webapps/guacamole.war

# Python Skripten bereitstellen
# /sbin/setuser und /sbin/my_init (launched when the container is started)
