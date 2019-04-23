#!/bin/bash

# If no env var for FTP_USER has been specified, use 'admin':
if [ "$FTP_USER" = "**String**" ]; then
    export FTP_USER='admin'
fi

# If no env var has been specified, generate a random password for FTP_USER:
if [ "$FTP_PASS" = "**Random**" ]; then
    export FTP_PASS=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-16}`
fi

# Do not log to STDOUT by default:
if [ "$LOG_STDOUT" = "**Boolean**" ]; then
    export LOG_STDOUT=''
else
    export LOG_STDOUT='Yes.'
fi

# Create home dir and update vsftpd user db:
mkdir -p "/home/vsftpd/${FTP_USER}"
chown -R ftp:ftp /home/vsftpd/
/usr/bin/htpasswd -c -p -b /etc/vsftpd/config/virtual_users ${FTP_USER} $(openssl passwd -1 -noverify ${FTP_PASS})

# Set passive mode parameters:
if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
    export PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
fi

if ! grep -q "pasv_address=" /etc/vsftpd/vsftpd.conf ; then echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf; fi
if ! grep -q "pasv_max_port=" /etc/vsftpd/vsftpd.conf ; then echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf; fi
if ! grep -q "pasv_min_port=" /etc/vsftpd/vsftpd.conf ; then echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf; fi
if ! grep -q "pasv_addr_resolve=" /etc/vsftpd/vsftpd.conf ; then echo "pasv_addr_resolve=${PASV_ADDR_RESOLVE}" >> /etc/vsftpd/vsftpd.conf; fi
if ! grep -q "pasv_enable=" /etc/vsftpd/vsftpd.conf ; then echo "pasv_enable=${PASV_ENABLE}" >> /etc/vsftpd/vsftpd.conf; fi
if ! grep -q "file_open_mode=" /etc/vsftpd/vsftpd.conf ; then echo "file_open_mode=${FILE_OPEN_MODE}" >> /etc/vsftpd/vsftpd.conf; fi
if ! grep -q "local_umask=" /etc/vsftpd/vsftpd.conf ; then echo "local_umask=${LOCAL_UMASK}" >> /etc/vsftpd/vsftpd.conf; fi

# Get log file path
export LOG_FILE=`grep xferlog_file /etc/vsftpd/vsftpd.conf|cut -d= -f2`

# stdout server info:
if [ ! $LOG_STDOUT ]; then
cat << EOB
	*************************************************
	*                                               *
	*    Docker image: haup/vsftd                 *
	*    https://github.com/haup/docker-vsftpd    *
	*                                               *
	*************************************************

	SERVER SETTINGS
	---------------
	· FTP User: $FTP_USER
	· FTP Password: $FTP_PASS
	· Log file: $LOG_FILE
	· Redirect vsftpd log to STDOUT: No.
EOB
else
    /usr/bin/ln -sf /dev/stdout $LOG_FILE
fi

if [ "$SSL" = "True" ]; then
	if [ ! -f /etc/vsftpd/config/vsftpd.cert.pem ]; then
		# openssl req -x509 -nodes -newkey rsa:1024 -keyout /etc/vsftpd/vsftpd.pem -out /etc/vsftpd/vsftpd.pem -days 3650
	if [ ! $SSL_CN ]; then
	        export SSL_CN="ftp.example.com"
	fi
	if [ ! $SSL_L ]; then
	        export SSL_L="Timbuktu"
	fi
	if [ ! $SSL_C ] ; then
	        export SSL_C="DE"
	fi
	openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=${SSL_C}/ST=Denial/L=${SSL_L}/O=Dis/CN=${SSL_CN}" -keyout /etc/vsftpd/config/vsftpd.key.pem  -out /etc/vsftpd/config/vsftpd.cert.pem
fi
	if ! grep -q "ssl_enable=YES" /etc/vsftpd/vsftpd.conf ; then echo "ssl_enable=YES" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "allow_anon_ssl=YES" /etc/vsftpd/vsftpd.conf ; then echo "allow_anon_ssl=YES" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "ssl_ciphers=HIGH" /etc/vsftpd/vsftpd.conf ; then echo "ssl_ciphers=HIGH" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "force_local_data_ssl=YES" /etc/vsftpd/vsftpd.conf ; then echo "force_local_data_ssl=YES" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "force_local_logins_ssl=YES" /etc/vsftpd/vsftpd.conf ; then echo "force_local_logins_ssl=YES" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "ssl_tlsv1=YES" /etc/vsftpd/vsftpd.conf ; then echo "ssl_tlsv1=YES" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "ssl_sslv2=NO" /etc/vsftpd/vsftpd.conf ; then echo "ssl_sslv2=NO" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "ssl_sslv3=NO" /etc/vsftpd/vsftpd.conf ; then echo "ssl_sslv3=NO" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "require_ssl_reuse=NO" /etc/vsftpd/vsftpd.conf ; then echo "require_ssl_reuse=NO" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "rsa_cert_file=/etc/vsftpd/config/vsftpd.cert.pem" /etc/vsftpd/vsftpd.conf ; then echo "rsa_cert_file=/etc/vsftpd/config/vsftpd.cert.pem" >> /etc/vsftpd/vsftpd.conf; fi
	if ! grep -q "rsa_private_key_file=/etc/vsftpd/config/vsftpd.key.pem" /etc/vsftpd/vsftpd.conf ; then echo "rsa_private_key_file=/etc/vsftpd/config/vsftpd.key.pem" >> /etc/vsftpd/vsftpd.conf; fi
fi

# Run vsftpd:
&>/dev/null /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
