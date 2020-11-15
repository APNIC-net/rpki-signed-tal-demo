FROM ubuntu:20.04

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
    libdatetime-perl
RUN cpanm Set::IntSpan Net::CIDR::Set
RUN wget https://ftp.openssl.org/source/openssl-1.0.2p.tar.gz \
    && tar xf openssl-1.0.2p.tar.gz \
    && cd openssl-1.0.2p \
    && ./config enable-rfc3779 \
    && make \
    && make install
RUN yes | unminimize
RUN git clone https://github.com/kristapsdz/rpki-client.git \
    && cd rpki-client \
    && ./configure \
    && sed -i 's/^RPKI_PRIVDROP.*/RPKI_PRIVDROP = 0/' Makefile \
    && make \
    && make install \
    && cd ..
RUN git clone https://github.com/kristapsdz/openrsync.git \
    && cd openrsync \
    && ./configure \
    && make \
    && make install \
    && cd ..
RUN apt-get install -y \
    libdigest-sha-perl
COPY . /root/rpki-signed-tal-demo
RUN cd /root/rpki-signed-tal-demo/ && perl Makefile.PL && make && make test && make install
RUN rm -rf /root/rpki-signed-tal-demo/
