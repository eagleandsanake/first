#!/bin/bash

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

#说明
blue "--------------------------------------"
blue "V2RAY+WS+TLS-Script"
blue "Only for Debian9" 
blue "By Myeagleandsnake"
blue "--------------------------------------"

function install_v2ray(){
 #时间校准
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    timenow=$(date -R)
    green "$timenow"
    sleep 5s

 #安装v2ray
    bash <(curl -L -s https://install.direct/go.sh)
    
 #申请并安装证书
    blue "----------------------------------"
    blue "Please input a valid Doman"
    blue "----------------------------------"
    read yourdom
    #依赖
    apt-get install socat 
    sudo apt-get -y install netcat
    #证书申请工具acme
    curl  https://get.acme.sh | sh
    #证书申请
    sudo ~/.acme.sh/acme.sh --issue -d $yourdom --standalone -k ec-256
    #证书安装
    sudo ~/.acme.sh/acme.sh --installcert -d $yourdom --fullchainpath /etc/v2ray/v2ray.crt --keypath /etc/v2ray/v2ray.key --ecc
 #安装nginx源
    wget -nc https://nginx.org/keys/nginx_signing.key
    apt-key add nginx_signing.key
 #安装nginx
    apt install nginx -y
 #nginx站点配置文件的修改
    #vi /etc/nginx/conf.d/v2ray.conf
    blue "----------------------------------------------"
    blue "Please input a port"
    blue "----------------------------------------------"
    read v2ray_port
    blue "----------------------------------------------"
    blue "Please input a path-FEX:/eagleandsnake/"
    blue "----------------------------------------------"
    read v2ray_path
    touch /etc/nginx/conf.d/v2ray.conf
    cat>/etc/nginx/conf.d/v2ray.conf<<EOF
    server {
      listen $v2ray_port ssl;
      ssl on;
      ssl_certificate       /root/.acme.sh/$yourdom_ecc/$yourdom.cer;
      ssl_certificate_key   /root/.acme.sh/$yourdom_ecc/$yourdom.key;
      ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
      ssl_ciphers           HIGH:!aNULL:!MD5;
      server_name           $yourdom;
        location $v2ray_path { # 与 V2Ray 配置中的 path 保持一致
           if ($http_upgrade != "websocket") { # WebSocket协商失败时返回404
           return 404;
           }
           proxy_redirect off;
           proxy_pass http://127.0.0.1:1080; # 假设WebSocket监听在环回地址的10000端口上
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
           proxy_set_header Host $host;
           # Show real IP in v2ray access.log
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
EOF

#配置v2ray
    blue "------------------------------"
    blue "Please input an alterId"
    blue "------------------------------"
    read v2ray_alterId
    UUID=$(cat /proc/sys/kernel/random/uuid)
    cat>/etc/v2ray/config.json<<EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen":"127.0.0.1",//只监听 127.0.0.1，避免除本机外的机器探测到开放了 10000 端口
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
           "id": "$UUID",
            "alterId": $v2ray_alterId
          }
        ]
       },
       "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "$v2ray_path"
        }
       }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
#启动v2ray与nginx
     systemctl start v2ray
     systemctl start nginx
#展示信息
     systemctl status v2ray
     systemctl status nginx

     green "Congratulations!,v2ray services is Ready "
     green "Config INFO is showed below"
     blue "TimeN:" && echo "$timenow"
     blue "Address:" && echo "$yourdom"
     blue "Prot:" && echo "$v2ray_port"
     blue "UUID:" && echo "$UUID"
     blue "AlterId:" && echo "$v2ray_alterId"
     blue "Prot:" && echo "$v2ray_port"
     blue "Security:" && echo "auto"
     blue "Network:" && echo "WS"
     blue "Path:" && echo "$v2ray_path"
     blue "Uderlying Transmission:" && echo "Tls"
}

#===============================================================================================================

#卸载v2ray,以及其依赖
function uninstall_v2ray(){
	
	#卸载v2ray
     sudo systemctl stop v2ray
     sudo systemctl disable v2ray
     sudo service v2ray stop
     sudo update-rc.d -f v2ray remove
     sudo rm -rf /etc/v2ray/*  #配置文件
     sudo rm -rf /usr/bin/v2ray/*  #程序
     sudo rm -rf /var/log/v2ray/*  #日志
     sudo rm -rf /lib/systemd/system/v2ray.service  #systemd 启动项
     sudo rm -rf /etc/init.d/v2ray  #sysv 启动项  

     #卸载nginx
     sudo apt-get remove nginx
     sudo apt-get purge nginx
     sudo apt-get autoremove
     grenn "Scussfully Uninstall"
}

start_menu(){
	
	green "Install V2ray"
	red "Uninstall V2ray"

	read -p "Please input number:" numb
    case "$numb" in
    1)
    install_v2ray
    ;;
    2)
    uninstall_v2ray 
    ;;
    *)
    clear
    red "Please input number"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu