FROM debian:12.2
MAINTAINER Xavier Raemy

VOLUME ["/etc/asterisk"]
VOLUME ["/var/lib/asterisk/sounds"]
EXPOSE 5060/udp
EXPOSE 5060/tcp

RUN apt update \
	&& apt install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# Download asterisk.
RUN git clone -b 20.4.0 https://github.com/asterisk/asterisk.git

RUN apt update &&apt -y install build-essential git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev libjansson-dev libxml2-dev uuid-dev default-libmysqlclient-dev \
	libedit-dev libspeex-dev libspeexdsp-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/asterisk

RUN apt update &&contrib/scripts/install_prereq install && rm -rf /var/lib/apt/lists/*

# Configure
RUN ./configure 

# Continue with a standard make.
RUN make menuselect.makeopts

RUN ./menuselect/menuselect \
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
    --disable cdr_radius \
    --disable cel_radius \
    --disable cdr_pgsql \
    --disable cel_pgsql \
    --disable cel_tds \
    --disable cdr_tds \
    --disable cdr_sqlite3_custom \
    --disable cel_sqlite3_custom \
    menuselect.makeopts


RUN make -j4 
RUN make install
WORKDIR /

# And run asterisk in the foreground.
CMD ["/usr/sbin/asterisk" , "-cvvv"]
