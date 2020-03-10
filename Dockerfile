FROM centos:centos7 AS builder
MAINTAINER Xavier Raemy

VOLUME ["/etc/asterisk"]

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
        make \
        bzip2 \
        libedit-devel \
        libsrtp-devel \
        gsm-devel \
        speex-devel \
        gettext \
        patch \
        file \
        -y && \
    yum clean all && \
    rm -rf /var/cache/yum 

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

RUN make -j4 
RUN make install
RUN make samples
WORKDIR /

# Update max number of open files.

RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk



FROM centos:centos7 

VOLUME ["/etc/asterisk"]
EXPOSE 5060/udp
EXPOSE 5060/tcp

RUN echo "minrate=1" >> /etc/yum.conf
RUN echo "timeout=400" >> /etc/yum.conf

RUN yum update -y -v && \
    yum install -y -v \
        git \
        ncurses \
        libxml2 \
        sqlite \
        xinetd \
        tar \
        bzip2 \
        gettext \
        openssl \
        libuuid \
        vim \
        gsm \
        speex \
        libsrtp \
        libedit \
        newt \
        net-snmp \
        -y && \
    yum clean all && \
    rm -rf /var/cache/yum 

COPY *.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust

COPY --from=builder /sbin/safe_asterisk /sbin/ 
COPY --from=builder /sbin/autosupport /sbin/ 
COPY --from=builder /sbin/astgenkey /sbin/ 
COPY --from=builder /sbin/astversion /sbin/ 
COPY --from=builder /sbin/rasterisk /sbin/ 
COPY --from=builder /sbin/asterisk /sbin/ 
COPY --from=builder /sbin/astdb2bdb /sbin/ 
COPY --from=builder /sbin/astdb2sqlite3 /sbin/ 
COPY --from=builder /sbin/astcanary /sbin/ 

COPY --from=builder /usr/include/asterisk/ /usr/include/asterisk/
COPY --from=builder /usr/lib64/pkgconfig/asterisk.pc /usr/lib64/pkgconfig/asterisk.pc
COPY --from=builder /usr/lib64/libasteriskpj.so /usr/lib64
COPY --from=builder /usr/lib64/libasteriskpj.so.2 /usr/lib64
COPY --from=builder /usr/lib64/libasteriskssl.so /usr/lib64
COPY --from=builder /usr/lib64/libasteriskssl.so.1 /usr/lib64
COPY --from=builder /usr/lib64/asterisk /usr/lib64/asterisk
COPY --from=builder /var/log/asterisk/ /var/log/asterisk/ 
COPY --from=builder /var/spool/asterisk/ /var/spool/asterisk/ 
COPY --from=builder /var/lib/asterisk/ /var/lib/asterisk/ 

COPY --from=builder /usr/src/asterisk/configs /root/sample
RUN ldconfig

# This is weird huh? I'd shell into the container and get errors about en_US.UTF-8 file not found
# found @ https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# And run asterisk in the foreground.

CMD asterisk -f


