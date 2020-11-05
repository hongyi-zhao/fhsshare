#!/usr/bin/env bash

#https://github.com/ApolloAuto/apollo/issues/12224
#Disable that proxy and try again, or use http/https proxy. See https://docs.bazel.build/versions/master/external.html#using-proxies

#Based on my testings, both socks5 and socks5h protocols don't take effect when using ~/.docker/config.json
#For settings with the following file: /etc/systemd/system/docker.service.d/http-proxy.conf, only the socks5 protocol is valid.

#For maximum compatibility, only set proxy for docker with http proxy converted by pproxy from socks5 as following:
#$ pproxy --reuse -r socks5://127.0.0.1:18889 -l http://:8080/ -vv



#$ sudo systemctl restart docker

# When the proxy is set via /etc/systemd/system/docker.service.d/http-proxy.conf, it can be checked with the following command:

#$ sudo docker info |& grep -Eie 'dir|proxy'
# Docker Root Dir: /var/lib/docker
# HTTP Proxy: http://127.0.0.1:8080/
# HTTPS Proxy: http://127.0.0.1:8080/

# When using ~/.docker/config.json to set the proxy, check it with the following:

# In the apollo's docker container:
#$ curl -svI www.baidu.com |& grep 8080
#* Connected to 127.0.0.1 (127.0.0.1) port 8080 (#0)

# At the same time, using tcpdump to confirm it:
#$ sudo tcpdump -i any 'port 8080'

# For any case, the current proxy setting can be checked within the docker environment:
#$ env | grep -i proxy
#HTTP_PROXY=http://127.0.0.1:8080
#https_proxy=http://127.0.0.1:8080
#http_proxy=http://127.0.0.1:8080
#no_proxy=localhost,127.0.0.1
#NO_PROXY=localhost,127.0.0.1
#HTTPS_PROXY=http://127.0.0.1:8080


#https://docs.docker.com/network/proxy/#configure-the-docker-client
#Configure Docker to use a proxy server

#If your container needs to use an HTTP, HTTPS, or FTP proxy server, you can configure it in different ways:

#    In Docker 17.07 and higher, you can configure the Docker client to pass proxy information to containers automatically.

#    In Docker 17.06 and lower, you must set appropriate environment variables within the container. You can do this when you build the image (which makes the image less portable) or when you create or run the container.

#Configure the Docker client

#    On the Docker client, create or edit the file ~/.docker/config.json in the home directory of the user which starts containers. Add JSON such as the following, substituting the type of proxy with httpsProxy or ftpProxy if necessary, and substituting the address and port of the proxy server. You can configure multiple proxy servers at the same time.

#    You can optionally exclude hosts or ranges from going through the proxy server by setting a noProxy key to one or more comma-separated IP addresses or hosts. Using the * character as a wildcard is supported, as shown in this example.

#    {
#     "proxies":
#     {
#       "default":
#       {
#         "httpProxy": "http://127.0.0.1:3001",
#         "httpsProxy": "http://127.0.0.1:3001",
#         "noProxy": "*.test.example.com,.example2.com"
#       }
#     }
#    }

#    Save the file.

#    When you create or start new containers, the environment variables are set automatically within the container.

#Use environment variables
#Set the environment variables manually

#When you build the image, or using the --env flag when you create or run the container, you can set one or more of the following variables to the appropriate value. This method makes the image less portable, so if you have Docker 17.07 or higher, you should configure the Docker client instead.
#Variable 	Dockerfile example 	docker run Example
#HTTP_PROXY 	ENV HTTP_PROXY "http://127.0.0.1:3001" 	--env HTTP_PROXY="http://127.0.0.1:3001"
#HTTPS_PROXY 	ENV HTTPS_PROXY "https://127.0.0.1:3001" 	--env HTTPS_PROXY="https://127.0.0.1:3001"
#FTP_PROXY 	ENV FTP_PROXY "ftp://127.0.0.1:3001" 	--env FTP_PROXY="ftp://127.0.0.1:3001"
#NO_PROXY 	ENV NO_PROXY "*.test.example.com,.example2.com" 	--env NO_PROXY="*.test.example.com,.example2.com"


docker_config_dir=$HOME/.docker
docker_config=$docker_config_dir/config.json

# Running the host proxy server on the docker0 interface, so that it can be used from docker container.
#$ ip a s docker0 | grep 'inet '
#    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0

if [ $(id -u) -ne 0 ] && type -fp docker > /dev/null && [[ $( docker -v | egrep -o '[0-9]+[.][0-9]+' | sed -e 's/[.]//' ) -ge 1707 ]]; then
  if [ ! -d "$docker_config_dir" ]; then
    mkdir -p $docker_config_dir
  fi
  if [ ! -e "$docker_config" ] || ! egrep -q '^[ ]*"httpProxy": "http://172.17.0.1:8080",' $docker_config; then
    sed 's/^ *|//' > $docker_config <<-EOF
        |{
        | "proxies":
        | {
        |   "default":
        |   {
        |     "httpProxy": "http://172.17.0.1:8080",
        |     "httpsProxy": "http://172.17.0.1:8080",
        |     "noProxy": "localhost,127.0.0.1",
        |     "comment": "https://docs.docker.com/network/proxy/#configure-the-docker-client"
        |   }
        | }
        |}
	EOF
  fi
fi



