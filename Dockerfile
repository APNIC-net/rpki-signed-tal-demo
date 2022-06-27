FROM ubuntu:22.10

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install -y \
    libhttp-daemon-perl \
    liblist-moreutils-perl \
    libwww-perl \
    libcarp-always-perl \
    libconvert-asn1-perl \
    libclass-accessor-perl \
    libssl-dev \
    libyaml-perl \
    libxml-libxml-perl \
    libio-capture-perl \
    libnet-ip-perl \
    make \
    wget \
    patch \
    gcc \
    rsync \
    libfile-slurp-perl \
    libjson-xs-perl \
    cpanminus \
    jq \
    vim \
    git \
    libdatetime-perl \
    libtls25 \
    libtls-dev \
    libdigest-sha-perl \
    libexpat1-dev \
    sudo
RUN cpanm Set::IntSpan Net::CIDR::Set
RUN wget https://ftp.openssl.org/source/openssl-1.0.2p.tar.gz \
    && tar xf openssl-1.0.2p.tar.gz \
    && cd openssl-1.0.2p \
    && ./config enable-rfc3779 \
    && make \
    && make install
RUN yes | unminimize
RUN addgroup \
    --gid 1000 \
    rpki-client && \
  adduser \
    --home /var/lib/rpki-client \
    --disabled-password \
    --gid 1000 \
    --uid 1000 \
    rpki-client
RUN wget https://ftp.openbsd.org/pub/OpenBSD/rpki-client/rpki-client-7.8.tar.gz \
    && tar xf rpki-client-7.8.tar.gz \
    && cd rpki-client-7.8 \
    && ./configure --with-user=rpki-client \
    && make \
    && make install \
    && cd ..
RUN git clone https://github.com/kristapsdz/openrsync.git \
    && cd openrsync \
    && ./configure \
    && make \
    && make install \
    && cd ..
COPY . /root/rpki-signed-tal-demo
RUN cd /root/rpki-signed-tal-demo/ && perl Makefile.PL && make && make test && make install
RUN rm -rf /root/rpki-signed-tal-demo/
