#!/bin/bash

# configure password
if [ -v GW_PASSWORD ]; then
	echo "Configuring gateway password"
	/opt/emc/scaleio/gateway/bin/SioGWTool.sh --reset_password --password $GW_PASSWORD --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
else
	echo "no gateway password specified!"
	exit 1
fi

# add MDM IP adresses
if [ -v MDM1_IP_ADDRESS ] && [ -v MDM2_IP_ADDRESS ]; then
	  echo "Adding MDM1 and MDM2 IP addresses"
	sed -i "s/mdm.ip.addresses=.*/mdm.ip.addresses=$MDM1_IP_ADDRESS,$MDM2_IP_ADDRESS/" /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
fi

export KEYSTORE="/etc/keystore"
export TRUSTSTORE="/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/certificates/truststore.jks"
export KEYSTORE_PASS="changeit"

# delete KEYSTORE
rm -rf $KEYSTORE

sed -i "s|keystore.file = .*|keystore.file = $KEYSTORE|" /opt/emc/scaleio/gateway/conf/catalina.properties
sed -i "s|keystore.password = .*|keystore.password = $KEYSTORE_PASS|" /opt/emc/scaleio/gateway/conf/catalina.properties

# import certificate or self-generate
if [ -v GW_CRT ] && [ -v GW_KEY ]; then
	echo "Importing GW cert:"
	echo -e "$GW_KEY\n$GW_CRT" | openssl pkcs12 -export -out certificate.pfx -passout pass:$KEYSTORE_PASS
	keytool -importkeystore -deststorepass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS -srckeystore certificate.pfx -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASS -destkeystore $KEYSTORE
else
	echo "Generating GW cert:"
	keytool -genkey -alias "Scaleio_Gateway" -dname "OU=ASD, O=EMC, C=US, ST=Massachusetts, L=Hopkinton, CN=Scaleio_Gateway" -keyalg RSA -validity 360 -keysize 2048 -storepass $KEYSTORE_PASS -keypass $KEYSTORE_PASS -keystore $KEYSTORE
fi

mkdir -p /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/certificates

# adding root and intermediate public certs to truststore
if [ -v ROOT_CRT ]; then
	echo "Importing ROOT cert to truststore:"
	echo -e "$ROOT_CRT" | keytool -import -trustcacerts --storepass $KEYSTORE_PASS -noprompt -alias "root" -keystore $TRUSTSTORE
fi
if [ -v INTERMEDIATE_CRT ]; then
	echo "Importing INTERMEDIATE cert to truststore:"
	echo -e "$INTERMEDIATE_CRT" | keytool -import -trustcacerts --storepass $KEYSTORE_PASS -noprompt -alias "intermediate" -keystore $TRUSTSTORE
fi

# add MDM certificates to truststore
if [ -v MDM1_CRT ] && [ -v MDM2_CRT ]; then
	echo "Importing MDM1 cert to truststore:"
	echo -e "$MDM1_CRT" | keytool -import -trustcacerts --storepass $KEYSTORE_PASS -noprompt -alias "mdm1" -keystore $TRUSTSTORE
	echo "Importing MDM2 cert to truststore:"
	echo -e "$MDM2_CRT" | keytool -import -trustcacerts --storepass $KEYSTORE_PASS -noprompt -alias "mdm2" -keystore $TRUSTSTORE
elif [ -v BYPASS_CRT_CHECK ]; then
	echo "Bypass MDM security check"
	sed -i "s/security.bypass_certificate_check.*/security.bypass_certificate_check=true/" /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
fi

# start gateway
exec /opt/emc/scaleio/gateway/bin/catalina.sh run
