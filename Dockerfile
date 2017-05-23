FROM ubuntu:xenial
MAINTAINER Muhammad Salehi <salehi1994@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ENV COVERALLS_TOKEN [secure]
ENV CXX g++
ENV CC gcc
ADD sources.list /etc/apt/sources.list
RUN apt update && apt upgrade -y
RUN apt-get install net-tools git wget redis-server g++ gcc build-essential libglib2.0-dev libtool vim supervisor libglib2.0-dev libpcap-dev python-dev sudo iputils-ping net-tools -y
RUN mkdir /data/
RUN cd /root ; wget http://tools.netsa.cert.org/releases/silk-2.5.0.tar.gz http://tools.netsa.cert.org/releases/libfixbuf-1.2.0.tar.gz http://tools.netsa.cert.org/releases/yaf-2.3.2.tar.gz; tar -xvzf libfixbuf-1.2.0.tar.gz; tar -xvzf silk-2.5.0.tar.gz; tar -xvzf yaf-2.3.2.tar.gz
RUN cd /root/libfixbuf-1.2.0/; ./configure && make; make -j32 install 
RUN cd /root/yaf-2.3.2/; ./configure --enable-applabel && make -j32; make install
RUN cd /root/silk-2.5.0/; ./configure  --with-libfixbuf=/usr/local/lib/pkgconfig/  --with-python  --enable-ipv6; make -j32; make install
ADD silk.conf /data/
ADD silk.conf /etc/ld.so.conf.d/
RUN ldconfig
RUN cp -fv /root/silk-2.5.0/site/twoway/silk.conf /data/
ADD sensors.conf /data/ 
ADD rwflowpack.conf /usr/local/etc/rwflowpack.conf
RUN cp -fv /usr/local/share/silk/etc/init.d/rwflowpack /etc/init.d/
RUN update-rc.d rwflowpack start 20 3 4 5 .
CMD ["nohup /usr/local/bin/yaf --silk --ipfix=tcp --live=pcap  --out=127.0.0.1 --ipfix-port=18001 --in=eth0 --applabel --max-payload=384 &"]
CMD ["ping -c 4 8.8.8.8"]
RUN sh /etc/init.d/rwflowpack status
RUN cat /var/log/rwflowpack-*.log
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
