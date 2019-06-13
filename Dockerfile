FROM debian:stretch-slim

RUN apt-get -y update && apt-get -y install tar build-essential autoconf libtool automake ed libssl1.0

ADD https://github.com/measurement-factory/squid/archive/SQUID-360-peering-for-SslBump.tar.gz  /tmp/squid.tar.gz

WORKDIR /tmp

RUN mkdir -p /tmp/squid /opt/squid && \
    tar -xf squid.tar.gz --strip-components=1 -C squid && \
    rm -rf squid.tar.gz && \
    cd squid && \
    ./bootstrap.sh && \
    ./configure --prefix=/opt/squid --enable-icap-client --enable-ssl --with-openssl --enable-ssl-crtd --enable-security-cert-generators=file --enable-auth --enable-basic-auth-helpers="NCSA" --with-default-user=nobody && \
    make -j$CPU && \
    make install


