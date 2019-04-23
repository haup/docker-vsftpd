FROM alpine:latest

MAINTAINER Tim Unkrig <tunkrig@gmail.com>
LABEL Description="vsftpd Docker image based on Alpine. Supports passive mode and virtual users with basic TLS Support. Forked from fauria/vsftpd" \
	License="Apache License 2.0" \
	Usage="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd -e [SSL=True]  haup/vsftpd" \
	Version="1.0"

RUN build_pkgs="build-base curl linux-pam-dev tar" && \
    runtime_pkgs="bash ca-certificates openssl apache2-utils linux-pam" && \
    apk update && \
    apk upgrade && \
    apk --update --no-cache add vsftpd ${build_pkgs} ${runtime_pkgs} && \
    # get us pam_pwdfile
    mkdir pam_pwdfile && \
    cd pam_pwdfile && \
    curl -sSL https://github.com/tiwe-de/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1 && \
    make install && \
    cd .. && \
	rm -rf pam_pwdfile && \
	# remove dev dependencies
    apk del ${build_pkgs} && \
    # other clean up
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
	rm -rf /var/log/*

ENV FTP_USER **String**
ENV FTP_PASS **Random**
ENV PASV_ADDRESS **IPv4**
ENV PASV_ADDR_RESOLVE NO
ENV PASV_ENABLE YES
ENV PASV_MIN_PORT 50110
ENV PASV_MAX_PORT 50310
ENV LOG_STDOUT **Boolean**
ENV FILE_OPEN_MODE 0666
ENV LOCAL_UMASK 077

COPY vsftpd.conf /etc/vsftpd/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/sbin/

RUN chmod +x /usr/sbin/run-vsftpd.sh
RUN mkdir -p /home/vsftpd/
RUN chown -R ftp:ftp /home/vsftpd/

VOLUME /home/vsftpd
VOLUME /var/log/vsftpd
VOLUME /etc/vsftpd/config

EXPOSE 20 21

CMD ["/usr/sbin/run-vsftpd.sh"]
