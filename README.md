# XRemoteRaspi
XRemoteRaspi is a docker base image derived from the base image of "resin/rpi-raspbian". This image allows to remote control graphical applications executed on a Raspberry Pi (ARM), e.g. JDownloader2. It can be used in combination with media center JEOS solutions like LibreELEC to run headless applications.

In general, Docker containers are designed to execute a single process. Here, a complete INIT environment is used based on RUNIT to allow starting server processes in daemon mode easily. It's a powerful alternative for SYSTEMD and Sys-V-INIT scripts.

The services are located below "/etc/service" where they can be started from via:
- runsvdir
- runsv

Due to performance problems with OpenJDK in combination with JDownloader2 the commercial flavor of Oracle JDK has been taken. To start JDownloader manually please issue the following command:
<jdk_install_dir>/jre/bin/java -jar /opt/jd2/JDownloader.jar
