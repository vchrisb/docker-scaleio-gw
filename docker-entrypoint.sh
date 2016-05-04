#!/bin/bash

# add MDM IP adresses
sed -i "s/mdm.ip.addresses=.*/mdm.ip.addresses=$MDM1_IP_ADDRESS,$MDM2_IP_ADDRESS/" /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties

# configure password
/opt/emc/scaleio/gateway/bin/SioGWTool.sh --reset_password --password $GW_PASSWORD --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties

# create self signed certificate
mkdir -p /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/certificates
keytool -genkey -alias "Scaleio_Gateway" -dname "OU=ASD, O=EMC, C=US, ST=Massachusetts, L=Hopkinton, CN=Scaleio_Gateway" -keyalg RSA -validity 360 -keysize 2048 -storepass changeit -keypass changeit -keystore /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/certificates/truststore.jks

# add MDM certificates
echo -e "$MDM1_CERT" | keytool -import -trustcacerts --storepass changeit -noprompt -alias "mdm1" -keystore /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/certificates/truststore.jks
echo -e "$MDM2_CERT" | keytool -import -trustcacerts --storepass changeit -noprompt -alias "mdm2" -keystore /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/certificates/truststore.jks

# start gateway
exec /opt/emc/scaleio/gateway/bin/catalina.sh run
