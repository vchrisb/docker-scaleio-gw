# docker-scaleio-gw

export MDM1_IP_ADDRESS=<MDM1 IP ADDRESS>
export MDM2_IP_ADDRESS=<MDM2 IP ADDRESS>

Get the MDM puplic certificats:
export MDM1_CERT=$(ssh -qt $MDM1_IP_ADDRESS sudo cat /opt/emc/scaleio/mdm/cfg/mdm_management_certificate.pem | sed -n -e '/-----BEGIN CERTIFICATE-----/,$p' | tr -d "\r")
export MDM2_CERT=$(ssh -qt $MDM2_IP_ADDRESS sudo cat /opt/emc/scaleio/mdm/cfg/mdm_management_certificate.pem | sed -n -e '/-----BEGIN CERTIFICATE-----/,$p' | tr -d "\r")

start the docker container
sudo docker run -d -p 443:443 -e GW_PASSWORD=Scaleio123 -e MDM1_IP_ADDRESS=$MDM1_IP_ADDRESS -e MDM2_IP_ADDRESS=$MDM2_IP_ADDRESS -e MDM1_CERT="$MDM1_CERT" -e MDM2_CERT="$MDM2_CERT" vchrisb/scaleio-gw