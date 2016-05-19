#!/bin/bash

# configure password
: ${GW_PASSWORD:=Scaleio123}
echo "Configuring gateway password"
/opt/emc/scaleio/gateway/bin/SioGWTool.sh --reset_password --password $GW_PASSWORD --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties

KEYSTORE="/etc/keystore"
KEYSTORE_PASS="changeit"

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
	echo "Generating GW cert"
	keytool -genkey -alias "Scaleio_Gateway" -dname "OU=ASD, O=EMC, C=US, ST=Massachusetts, L=Hopkinton, CN=Scaleio_Gateway" -keyalg RSA -validity 360 -keysize 2048 -storepass $KEYSTORE_PASS -keypass $KEYSTORE_PASS -keystore $KEYSTORE
fi

if [ -v BYPASS_CRT_CHECK ]; then
	echo "Bypass MDM security check"
	sed -i "s/security.bypass_certificate_check.*/security.bypass_certificate_check=true/" /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties
fi

# configure trap to be able to gracefully shutdown the gateway in the background
trap 'kill -TERM $PID' TERM INT

# start gateway in background
/opt/emc/scaleio/gateway/bin/catalina.sh run &
PID=$!

# wait for the gateway to be started
gw_is_ready() {
    eval "[ $(curl --silent --insecure --write-out %{http_code} --output /dev/null https://localhost/api/version) = 200 ]"
}

WAIT_LOOPS=40
WAIT_SLEEP=2
i=0
while ! gw_is_ready; do
    i=`expr $i + 1`
    if [ $i -ge $WAIT_LOOPS ]; then
        echo "gateway still not ready, giving up"
        exit 1
    fi
    sleep $WAIT_SLEEP
done

# configure MDM IP addresses and trust host certificates
if [ -v MDM1_IP_ADDRESS ] && [ -v MDM2_IP_ADDRESS ]; then

	TOKEN=$(curl --silent --insecure --user admin:$GW_PASSWORD https://localhost/api/gatewayLogin  | sed 's:^.\(.*\).$:\1:')
	if [ -v TRUST_MDM_CRT ]; then
		echo "trust MDM1 host certificate"
		curl --silent --show-error --insecure --user :$TOKEN -X GET https://localhost/api/getHostCertificate/Mdm?host=$MDM1_IP_ADDRESS > /tmp/mdm.cer
		curl --silent --show-error --insecure --user :$TOKEN -X POST -H "Content-Type: multipart/form-data" -F "file=@/tmp/mdm.cer" https://localhost/api/trustHostCertificate/Mdm
		echo "trust MDM2 host certificate"
		curl --silent --show-error --insecure --user :$TOKEN -X GET https://localhost/api/getHostCertificate/Mdm?host=$MDM2_IP_ADDRESS> /tmp/mdm.cer
		curl --silent --show-error --insecure --user :$TOKEN -X POST -H "Content-Type: multipart/form-data" -F "file=@/tmp/mdm.cer" https://localhost/api/trustHostCertificate/Mdm
	elif [ -v MDM1_CRT ] && [ -v MDM2_CRT ]; then
		echo "trust provided MDM1 host certificate"
		echo -e "$MDM1_CRT" > /tmp/mdm.cer
		curl --silent --show-error --insecure --user :$TOKEN -X POST -H "Content-Type: multipart/form-data" -F "file=@/tmp/mdm.cer" https://localhost/api/trustHostCertificate/Mdm
		echo "trust provided MDM2 host certificate"
		echo -e "$MDM2_CRT" > /tmp/mdm.cer
		curl --silent --show-error --insecure --user :$TOKEN -X POST -H "Content-Type: multipart/form-data" -F "file=@/tmp/mdm.cer" https://localhost/api/trustHostCertificate/Mdm
	fi
	echo "Adding MDM1 and MDM2 IP addresses to gateway configuration"
	CONTENT='{"mdmAddresses":["'$MDM1_IP_ADDRESS'", "'$MDM2_IP_ADDRESS'"]}'
	curl --silent --show-error --insecure --user :$TOKEN -X POST -H "Content-Type: application/json" -d "${CONTENT}" https://localhost/api/updateConfiguration
	#logout
	curl --silent --show-error --insecure --user :$TOKEN https://localhost/api/gatewayLogout
fi

wait $PID
trap - TERM INT
wait $PID
EXIT_STATUS=$?