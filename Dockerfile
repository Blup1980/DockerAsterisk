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
        libedit-devel \
        pjproject-devel \
        libsrtp-devel \
        gsm-devel \
        speex-devel \
        gettext \
        patch \
        -y

COPY *.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust

# Download asterisk.

WORKDIR /usr/src
RUN git config --global http.sslVerify false
RUN git clone -b 16.8 http://gerrit.asterisk.org/asterisk

WORKDIR /usr/src/asterisk

# Configure
RUN ./configure --libdir=/usr/lib64 --with-jansson-bundled 

# Continue with a standard make.

RUN make 
RUN make install
RUN make samples
WORKDIR /

# Update max number of open files.

RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk

# This is weird huh? I'd shell into the container and get errors about en_US.UTF-8 file not found
# found @ https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# And run asterisk in the foreground.

CMD asterisk -f
