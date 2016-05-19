# CloudSuite
A benchmark suite for emerging scale-out applications.

## Instruction for CloudSuite installation on ubuntu 14.04
(Becuase of USA sanctions against some countries such as Iran, it's not possible to pull docker images from docker hub in those countries)

## Docker
from <a href="https://docs.docker.com/engine/installation/linux/ubuntulinux/"> Docker Documentations </a> instal docker according to OS version

## ShadowSocks
ShadowSocks is a secure socks5 proxy, designed to protect your Internet traffic. We use it to not get limited by aformentioned sanctions. You need a server which have a installed shadowsocks server. For more information see <a href="https://shadowsocks.org/en/index.html">ShadowSocks Website</a>.

### Install ShadowSocks
```bash
sudo apt-get update
sudo apt-get install libevent-dev python-pip python-dev python-m2crypto

sudo pip install shadowsocks
```

### Configure ShadowSocks
```bash
mkdir ~/shadowsocks
cd ~/shadowsocks
```

Add following line in `~/shadowsocks/proxyconf`
```bash
{
  "server": "<sever addr>",
  "server_port": <port>,
  "local_port": 1080,
  "password": "<password>",
  "timeout":600,
  "method":"aes-256-cfb"
}
```

### Start ShadowSocks

```bash
cd ~/shadowsocks
sslocal -c proxyconf &
```
<strong>Warning:</strong> Remember after restart server, you need to start shadowsocks client again. This is not a servcie.


## Polipo

ShadowSocks make socks5 proxy. In commandline, we need http proxy. Polipo is a small and fast caching web proxy. for more information see <a href="https://www.irif.univ-paris-diderot.fr/~jch/software/polipo/">Polipo Website</a>.

### Install Polipo
```bash
sudo apt-get install polipo
```

### Configure Polipo
Add following line in `/etc/polipo/config`
```bash
socksParentProxy = "localhost:1080"
socksProxyType = socks5
```
We run ShadowSocks on localhost, port 1080. So we set parent proxy of Polipo to this address. Default Polipo's port is 8123.

### Start Polipo
```bash
sudo service polipo restart
```

## Check Proxy configuration
For setting proxy on terminal:
```bash
export http_proxy="http://127.0.0.1:8123"
export https_proxy="http://127.0.0.1:8123"
```

If everything is ok, our public address must be ShadowSocks server IP:

```bash
curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'
```

### Configure Docker proxy
Add next two line to `/etc/default/docker`:

```bash
export http_proxy="http://127.0.0.1:8123/"
export https_proxy="http://127.0.0.1:8123"
```

now we need to restart docker service:

```bash
sudo service docker restart
```

## Pull CloudSuite images from docker hub

After all these steps, we can pull from docker hub. For running CloudSuite Benchmarks, see <a href="http://cloudsuite.ch/">CloudSuite Website</a>.

