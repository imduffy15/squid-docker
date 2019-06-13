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
    ./configure --prefix=/opt/squid --enable-icap-client --enable-ssl --with-openssl --enable-ssl-crtd --enable-security-cert-generators=file --enable-auth --enable-basic-auth-helpers="NCSA" --with-default-user=squid --disable-ipv6 &&  \
    make -j$CPU && \
    make install


FROM debian:stretch-slim

ENV PATH="/opt/squid/bin:/opt/squid/sbin:${PATH}"

RUN apt-get update && \
	apt-get install -y --no-install-recommends openssl libnetfilter-conntrack3 libcap2 libgssapi-krb5-2 libgnutls-openssl27 libxml2 libexpat1 libatomic1 libltdl7 ca-certificates && \
	apt-get clean && \
	rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=0 /opt/squid /opt/squid

RUN update-ca-certificates && \
	addgroup --system --gid 3128 squid && \
	adduser --system --gid 3128 --uid 3128 --shell /bin/false --home /opt/squid --disabled-password squid && \
    chown squid:squid -R /opt/squid

ENTRYPOINT ["/opt/squid/sbin/squid"]
