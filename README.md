# docker-scaleio-gw [![](https://imagelayers.io/badge/vchrisb/scaleio-gw:latest.svg)](https://imagelayers.io/?images=vchrisb/scaleio-gw:latest 'Get your own badge on imagelayers.io')

This image runs EMC ScaleIO as a container.

## How to use this image

```sudo docker run -d --name=scaleio-gw vchrisb/scaleio-gw```

The following environment variables are also honored for configuring your ScaleIO Gateway instance:
* `-e GW_PASSWORD=` (Gateway password, defaults to `Scaleio123`)
* `-e MDM1_IP_ADDRESS=` and `-e MDM2_IP_ADDRESS=` (MDM IP addresses)
* `-e TRUST_MDM_CRT=` (if variable is set with a non empty value will the MDM certifates being trusted)
* `-e GW_KEY=` and `-e GW_CRT=` (public certifcate and private key to be used)
* `-e BYPASS_CRT_CHECK=` (if variable is set with a non empty value will the certificate check for the MDMs bypassed)

### Examples

```docker run -d --name=scaleio-gw --restart=always -p 443:443 -e GW_PASSWORD=Scaleio123 -e BYPASS_CRT_CHECK=true -e MDM1_IP_ADDRESS=192.168.100.1 -e MDM2_IP_ADDRESS=192.168.100.2 vchrisb/scaleio-gw```

```docker run -d --name=scaleio-gw --restart=always -p 443:443 -e GW_PASSWORD=Scaleio123 -e MDM1_IP_ADDRESS=$MDM1_IP_ADDRESS -e MDM2_IP_ADDRESS=$MDM2_IP_ADDRESS -e MDM1_CRT="$MDM1_CRT" -e MDM2_CRT="$MDM2_CRT" vchrisb/scaleio-gw```

```docker run -d --name scaleio-gw --restart=always -p 443:443 -e GW_PASSWORD=Scaleio123 -e MDM1_IP_ADDRESS=$MDM1_IP_ADDRESS -e MDM2_IP_ADDRESS=$MDM2_IP_ADDRESS -e MDM1_CRT="$MDM1_CRT" -e MDM2_CRT="$MDM2_CRT" -e GW_KEY="$GW_KEY" -e GW_CRT="$GW_CRT" -e ROOT_CRT="$ROOT_CRT" -e INTERMEDIATE_CRT="$INTERMEDIATE_CRT" vchrisb/scaleio-gw```

## DC/OS with RexRay

RexRay, a vendor agnostic storage orchestration engine supported by DC/OS, requires a high available connection to the ScaleIO Gateway if using ScaleIO as a storage provider. Normally runnig the gateway on a host makes it harder to maintain the installation and making the gateway redundant. Running the ScaleIO gateway as a container in Mesos makes it much easier to achieve these goals.
The gateway can be reached from within the mesos cluster via `<scaleio-gw name>.marathon.mesos`. To be able to know the the port of the container, you have to use currently a defined `host port`. Using a `VIP`is investigated.  
Please have a look at the sample marathon file `scaleio-gw.json`.

#### certificates
It makes sense to have a common certificate When running multiple instances of scaleio-gw.  
An easy way to create a self-signed certificate is:
```
openssl req -x509 -sha256 -newkey rsa:2048 -keyout certificate.key -out certificate.crt -days 1024 -nodes -subj '/CN=scaleio-gw.marathon.mesos'
export GW_KEY=$(cat certificate.key | sed ':a;N;$!ba;s/\n/\\n/g')
export GW_CRT=$(cat certificate.crt | sed ':a;N;$!ba;s/\n/\\n/g')
```

