FROM debian:stretch

RUN echo "deb-src http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list && \
	echo "deb-src http://security.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
	echo "deb-src http://deb.debian.org/debian stretch-updates main" >> /etc/apt/sources.list && \
	apt-get -y update && \ 
	apt-get install -y devscripts sudo libssl-dev

RUN mk-build-deps squid --install --root-cmd sudo --remove --tool 'apt-get -y'

RUN apt-get install -y procps psmisc && free -m && cat /proc/cpuinfo && nproc

ADD https://github.com/measurement-factory/squid/archive/SQUID-360-peering-for-SslBump.tar.gz  /tmp/squid.tar.gz

WORKDIR /tmp

RUN mkdir -p /tmp/squid /opt/squid && \
    tar -xf squid.tar.gz --strip-components=1 -C squid && \
    rm -rf squid.tar.gz && \
    CPU=$(( `nproc --all`-1 )) && \
    cd squid && \
    ./bootstrap.sh && \
    ./configure --prefix=/opt/squid --enable-icap-client --enable-ssl --with-openssl --enable-ssl-crtd --enable-security-cert-generators=file --enable-auth --enable-basic-auth-helpers="NCSA" --with-default-user=nobody && \
    make -j$CPU && \
    make install


FROM debian:stretch-slim

COPY --from=0 /opt/squid /opt/squid
