FROM ubuntu:latest as builder
MAINTAINER Xavier Raemy

VOLUME ["/etc/asterisk"]
EXPOSE 5060/udp
EXPOSE 5060/tcp


RUN apt-get update && \
    apt-get install -y \
        build-essential \
        git \
        vim \
        libncurses5 \
        libncurses5-dev \
        libxml2 \
        libxml2-dev \
        sqlite3 \
        libsqlite3-dev \
        libssl-dev \
        libnewt-dev \
        uuid-dev \
        xmlstarlet \
        snmp \
        libsnmp-dev \
        tar \
        libogg0 \
        libjansson-dev \
        make \
        bzip2 \
        libedit-dev \
        libsrtp2-dev \
        libgsm1-dev \
        libspeex-dev \
        gettext \
        patch \
        file && \
    rm -rf /var/lib/apt/lists/* 

# Download asterisk.

WORKDIR /usr/src
RUN git clone -b 20.4.0 https://github.com/asterisk/asterisk.git

WORKDIR /usr/src/asterisk

# Configure
RUN ./configure --libdir=/usr/lib64 --with-jansson-bundled 

# Continue with a standard make.

RUN make menuselect.makeopts && \
    menuselect/menuselect \
        --enable codec_opus \
        --disable codec_a_mu \
        --disable codec_adpcm \
        --disable codec_adpcm \
        --disable codec_codec2 \
        --disable codec_dahdi \
        --disable codec_g722 \
        --disable codec_a_mu \
        --disable codec_gsm \
        --disable codec_ilbc \
        --disable codec_g726 \
        --disable codec_lpc10 \
        --disable codec_resample \
        --disable codec_speex \
        --disable chan_iax2 \
        --disable-category MENUSELECT_CORE_SOUNDS \
        --disable-category MENUSELECT_EXTRA_SOUNDS \
    menuselect.makeopts

RUN make -j4 
RUN make install
RUN make samples

FROM ubuntu:latest as final


VOLUME ["/etc/asterisk"]
EXPOSE 5060/udp
EXPOSE 5060/tcp


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        less \
        vim \
        libncurses5 \
        libxml2 \
        sqlite3 \
        libssl-dev \
        libnewt-dev \
        uuid \
        xmlstarlet \
        snmp \
        libogg0 \
        libjansson-dev \
        libedit-dev \
        libsrtp2-dev \
        libgsm1 \
        libspeex-dev \
        gettext && \
    rm -rf /var/lib/apt/lists/* 

RUN groupadd -r asterisk && useradd -r -g asterisk asterisk

COPY --from=builder --chown=asterisk:asterisk /usr/lib64/libasterisk* /usr/lib64/
COPY --from=builder --chown=asterisk:asterisk /usr/lib64/asterisk/ /usr/lib64/asterisk/
COPY --from=builder --chown=asterisk:asterisk /var/spool/asterisk/ /var/spool/asterisk/
COPY --from=builder --chown=asterisk:asterisk /var/log/asterisk/ /var/log/asterisk/
COPY --from=builder --chown=asterisk:asterisk /usr/sbin/asterisk /usr/sbin/asterisk
COPY --from=builder --chown=asterisk:asterisk /var/lib/asterisk/ /var/lib/asterisk/

RUN echo "/usr/lib64" > /etc/ld.so.conf.d/asterisk.conf 
RUN ldconfig

USER asterisk

WORKDIR /
CMD asterisk -fvvv
