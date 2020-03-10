FROM centos:centos7
MAINTAINER Xavier Raemy

VOLUME ["/etc/asterisk"]
EXPOSE 5060/udp
EXPOSE 5060/tcp

RUN echo "minrate=1" >> /etc/yum.conf
RUN echo "timeout=400" >> /etc/yum.conf

RUN yum update -y -v && \
    yum install -y -v \
        git \
        kernel-headers \
        gcc \
        gcc-c++ \
        cpp \
        ncurses \
        ncurses-devel \
        libxml2 \
        libxml2-devel \
        sqlite \
        sqlite-devel \
        openssl-devel \
        newt-devel \
        kernel-devel \
        libuuid-devel \
        net-snmp-devel \
        xinetd \
        tar \
        jansson-devel \
        make \
        bzip2 \
        pjproject-devel \
        libsrtp-devel \
        gsm-devel \
        speex-devel \
        gettext \
        -y


# Download asterisk.

WORKDIR /usr/src
RUN git clone -b 14.7 --depth 1 https://github.com/asterisk/asterisk.git

WORKDIR /usr/src/asterisk

# Configure
RUN ./configure --libdir=/usr/lib64 1> /dev/null

# Continue with a standard make.

RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make samples 1> /dev/null
WORKDIR /

# Update max number of open files.

RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk

# This is weird huh? I'd shell into the container and get errors about en_US.UTF-8 file not found
# found @ https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# And run asterisk in the foreground.

CMD asterisk -f
