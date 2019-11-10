# XRemoteRaspi on Debian Buster
XRemoteRaspi is an enhanced Docker container base image derived from base image "<a href="https://hub.docker.com/r/balenalib/rpi-raspbian">balenalib/rpi-raspbian</a>" (formerly: "<a href="https://hub.docker.com/r/balenalib/rpi-raspbian/tags">resin/rpi-raspbian</a>", now deprecated). This image allows to remote control graphical applications executed on a Raspberry Pi (ARM), e.g. JDownloader2. It can be used in combination with media center JEOS solutions like LibreELEC to run headless applications.

The docker container might be started using:
```
docker run -it -d -v /storage/JDownloader:/root/Downloads -p 3389:3389 -p 9022:22 -p 8088:8080 -p 5901:5901 balenalib/rpi-raspbian /bin/bash
```

In general, Docker containers are designed to execute a single process. Here, a complete INIT environment is used based on RUNIT to allow starting server processes in daemon mode easily. It's a powerful alternative for SYSTEMD and Sys-V-INIT scripts.

Set a VNC password for the user that is used to launch Xvnc, here "nobody". Important: confirm setting a view-only password when the following message appears "*Would you like to enter a view-only password (y/n)?*" Otherwise the VNC authentication fails"
```
vncpasswd
```

The services are located below "/etc/service" where they can be started from via:
- runsvdir
- runsv

Ideally using "runsvdir" to load all runit services located and specified in directory "/etc/service"
```
runsvdir /etc/service &
```

Alternatively, the configured runit services can be instantiated individually using:
```
runsv /etc/service/<service_name> &
```

Due to performance problems with OpenJDK in combination with JDownloader2 the commercial flavor of Oracle JDK has been taken. To start JDownloader manually please issue the following command:
```
<jdk_install_dir>/jre/bin/java -jar /opt/jd2/JDownloader.jar
```

## Open Points:
The following packages cannot installed with Debian Buster - currently not yet available:
- guacamole
- libguac-client-vnc0
