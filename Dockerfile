FROM alpine:latest
MAINTAINER Xavier Raemy

VOLUME ["/etc/asterisk"]
EXPOSE 5060/udp
EXPOSE 5060/tcp

RUN apk update \
	&& apk add git

WORKDIR /usr/src
RUN git clone -b 20.4.0 https://github.com/asterisk/asterisk.git



RUN apk update \
  	&& apk add libtool libuuid jansson libxml2 sqlite-libs readline libcurl libressl zlib libsrtp lua5.1-libs spandsp unbound-libs \
        git \
        gcc \
        ncurses \
        libxml2 \
        sqlite \
        newt \
        tar \
        make \
        bzip2 \
        pjproject \
        libsrtp \
        gettext \
        patch \
	vim

RUN apk add --virtual .build-deps build-base patch bsd-compat-headers util-linux-dev ncurses-dev libresample \
        jansson-dev libxml2-dev sqlite-dev readline-dev curl-dev unbound-dev \
        zlib-dev libsrtp-dev lua-dev spandsp-dev libedit-dev 


# Download asterisk.

WORKDIR /usr/src/asterisk

# Configure
RUN ./configure --with-pjproject-bundled 

# Continue with a standard make.

RUN make menuselect.makeopts



RUN ./menuselect/menuselect \
    --disable BUILD_NATIVE \
    --disable-category MENUSELECT_CORE_SOUNDS \
    --disable-category MENUSELECT_MOH \
    --disable-category MENUSELECT_EXTRA_SOUNDS \
    --disable app_externalivr \
    --disable app_adsiprog \
    --disable app_alarmreceiver \
    --disable app_getcpeid \
    --disable app_minivm \
    --disable app_morsecode \
    --disable app_mp3 \
    --disable app_zapateller \
    --disable chan_mgcp \
    --disable chan_skinny \
    --disable chan_unistim \
    --disable codec_lpc10 \
    --disable pbx_dundi \
    --disable res_adsi \
    --disable res_smdi \
    --disable astdb2sqlite3 \
    --disable astdb2bdb \
    menuselect.makeopts


# RUN make 
# RUN make install
# RUN make samples
WORKDIR /

# Update max number of open files.

# RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk


# And run asterisk in the foreground.

CMD asterisk -fv
