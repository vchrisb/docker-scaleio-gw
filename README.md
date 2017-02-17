# docker-scaleio-gw [![](https://images.microbadger.com/badges/image/vchrisb/scaleio-gw.svg)](https://microbadger.com/images/vchrisb/scaleio-gw "Get your own image badge on microbadger.com")

This image runs EMC ScaleIO as a container.

## How to use this image

```sudo docker run -d --name=scaleio-gw vchrisb/scaleio-gw```

The following environment variables are also honored for configuring your ScaleIO Gateway instance:
* `-e GW_PASSWORD=` (Gateway password, defaults to `Scaleio123`)
* `-e MDM1_IP_ADDRESS=` and `-e MDM2_IP_ADDRESS=` (MDM IP addresses)
* `-e MDM1_CRT=` and `-e MDM2_CRT=` (manually add the MDM public certificates to the truststore)
* `-e TRUST_MDM_CRT=` (if variable is set with a non empty value will the MDM certificate being trusted)
* `-e GW_KEY=` and `-e GW_CRT=` (public certificate and private key to be used)
* `-e BYPASS_CRT_CHECK=` (if variable is set with a non empty value will the certificate check for the MDMs and LIAs bypassed)

### Examples

```docker run -d --name=scaleio-gw --restart=always -p 443:443 -e GW_PASSWORD=Scaleio123 -e MDM1_IP_ADDRESS=192.168.100.1 -e MDM2_IP_ADDRESS=192.168.100.2 -e TRUST_MDM_CRT=true vchrisb/scaleio-gw```

```docker run -d --name scaleio-gw --restart=always -p 443:443 -e GW_PASSWORD=Scaleio123 -e MDM1_IP_ADDRESS=192.168.100.1 -e MDM2_IP_ADDRESS=192.168.100.2 -e TRUST_MDM_CRT=true -e GW_KEY="$GW_KEY" -e GW_CRT="$GW_CRT" vchrisb/scaleio-gw```

### Docker Tags

* latest -> v2.0.1.2
* v2.0.1.2
* v2.0.0.2
* v2.0.0.1

## certificates

#### Gateway certificate

It makes sense to have a common certificate when running multiple instances of scaleio-gw or to persist the certificate between scaleio-gw upgrades.
You can either generate your own self-signed certificate or add signed certificate from your certificate authority.
  
##### create a self-signed certificate is
```
openssl req -x509 -sha256 -newkey rsa:2048 -keyout certificate.key -out certificate.crt -days 1024 -nodes -subj '/CN=scaleio-gw.marathon.mesos'
export GW_KEY=$(cat certificate.key | sed ':a;N;$!ba;s/\n/\\n/g')
export GW_CRT=$(cat certificate.crt | sed ':a;N;$!ba;s/\n/\\n/g')
```

#### MDM certificates

Following commands can be used to get the `MDM1`and `MDM2` certificates:
```
export MDM1_IP_ADDRESS=x.x.x.x
export MDM2_IP_ADDRESS=x.x.x.x
export MDM1_CRT=$(ssh -q $MDM1_IP_ADDRESS sudo cat /opt/emc/scaleio/mdm/cfg/mdm_management_certificate.pem | sed -n -e '/-----BEGIN CERTIFICATE-----/,$p' | sed ':a;N;$!ba;s/\n/\\n/g')
export MDM2_CRT=$(ssh -q $MDM2_IP_ADDRESS sudo cat /opt/emc/scaleio/mdm/cfg/mdm_management_certificate.pem | sed -n -e '/-----BEGIN CERTIFICATE-----/,$p' | sed ':a;N;$!ba;s/\n/\\n/g')
```

If `requiretty` is not enabled in sudoers, please use following commands instead:
```
export MDM1_IP_ADDRESS=x.x.x.x  
export MDM2_IP_ADDRESS=x.x.x.x  
export MDM1_CRT=$(ssh -qt $MDM1_IP_ADDRESS sudo cat /opt/emc/scaleio/mdm/cfg/mdm_management_certificate.pem | sed -n -e '/-----BEGIN CERTIFICATE-----/,$p' | tr -d "\r" | sed ':a;N;$!ba;s/\n/\\n/g')
export MDM2_CRT=$(ssh -qt $MDM2_IP_ADDRESS sudo cat /opt/emc/scaleio/mdm/cfg/mdm_management_certificate.pem | sed -n -e '/-----BEGIN CERTIFICATE-----/,$p' | tr -d "\r" | sed ':a;N;$!ba;s/\n/\\n/g')
```

## DC/OS with RexRay

RexRay, a vendor agnostic storage orchestration engine supported by DC/OS, requires a high available connection to the ScaleIO Gateway if using ScaleIO as a storage provider. Normally runnig the gateway on a host makes it harder to maintain the installation and making the gateway redundant. Running the ScaleIO gateway as a container in Mesos makes it much easier to achieve these goals.
The gateway can be reached from within the mesos cluster via `<scaleio-gw name>.marathon.mesos`. To be able to know the the port of the container, you have to use currently a defined `host port`. Using a `VIP`is investigated.  
Please have a look at the sample marathon file `scaleio-gw.json`.

## Support

If you need generic help with the ScaleIO Gateway please reach out to the [ScaleIO Community ](https://community.emc.com/community/products/scaleio)  or the [EMC CodeCommunity](http://community.emccode.com/) on Slack in the `scaleio_rest`channel.
For problems or questions regarding the Docker Image please report an issue on [GitHub](https://github.com/vchrisb/docker-scaleio-gw/issues).

## Disclaimer

This is not an official EMC product/solution. Use at your own risk!
