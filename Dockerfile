FROM centos:latest
MAINTAINER Christopher Banck <christopher@banck.net>

RUN yum -y update && yum -y install java-1.8.0-openjdk which bsdtar openssl

RUN cd /tmp && \
	curl http://downloads.emc.com/emc-com/usa/ScaleIO/ScaleIO_Linux_v2.0.zip \
	| bsdtar -xvf- "ScaleIO_2.0.0.2_Complete_Linux_SW_Download/ScaleIO_2.0.0.2_Gateway_for_Linux_Download/EMC-ScaleIO-gateway-2.0-7120.0.x86_64.rpm" && \
	rpm -i ScaleIO_2.0.0.2_Complete_Linux_SW_Download/ScaleIO_2.0.0.2_Gateway_for_Linux_Download/EMC-ScaleIO-gateway-2.0-7120.0.x86_64.rpm

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 443