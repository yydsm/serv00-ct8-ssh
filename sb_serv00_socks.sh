#!/bin/bash

# 定义颜色
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }

# 定义路径
USERNAME=$(whoami)
HOSTNAME=$(hostname)
WORKDIR="/home/${USERNAME}/logs"

# 定义变量
export LC_ALL=C
export UUID=${UUID:-'45284abb-c1be-4532-8dfd-5dfb10294044'}
export NEZHA_SERVER=${NEZHA_SERVER:-'nezha.yutian81.top'} 
export NEZHA_PORT=${NEZHA_PORT:-'5555'}     
export NEZHA_KEY=${NEZHA_KEY:-''} 
export ARGO_DOMAIN=${ARGO_DOMAIN:-''}   
export ARGO_AUTH=${ARGO_AUTH:-''} 
export vmess_port=${vmess_port:-'40000'}
export hy2_port=${hy2_port:-'41000'}
export socks_port=${socks_port:-'42000'}
export socks_user=${socks_user:-'abc123'}
export socks_pass=${socks_pass:-'abc456'}
export CFIP=${CFIP:-'whatismyipaddress.com'} 
export CFPORT=${CFPORT:-'443'} 

# 定义文件下载地址
SB_WEB_ARMURL="https://github.com/eooce/test/releases/download/arm64/sb"
# AG_BOT_ARMURL="https://github.com/eooce/test/releases/download/arm64/bot13"
AG_BOT_ARMURL="https://github.com/yutian81/serv00-ct8-ssh/releases/download/arm64/cloudflared_arm64"
# NZ_NPM_ARMURL="https://github.com/eooce/test/releases/download/ARM/swith"
NZ_NPM_ARMURL="https://github.com/yutian81/serv00-ct8-ssh/releases/download/arm64/nezha_agent_arm64"
SB_WEB_X86URL="https://00.2go.us.kg/web"
AG_BOT_X86URL="https://00.2go.us.kg/bot"
NZ_NPM_X86URL="https://00.2go.us.kg/npm"
CORN_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/check_sb_cron.sh"
UPDATA_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/sb_serv00_socks.sh"
REBOOT_URL="https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/reboot.sh"

[ -d "${WORKDIR}" ] || (mkdir -p "${WORKDIR}" && chmod -R 755 "${WORKDIR}")

# 安装singbox
install_singbox() {
echo -e "${yellow}本脚本同时四协议共存${purple}(vmess,vmess-ws-tls(argo),hysteria2,socks5)${re}"
echo -e "${yellow}开始运行前，请确保在面板${purple}已开放3个端口，两个tcp端口和一个udp端口${re}"
echo -e "${yellow}面板${purple}Additional services中的Run your own applications${yellow}已开启为${purple}Enabled${yellow}状态${re}"
green "安装完成后，可在用户根目录输入 \`bash sb00.sh\` 再次进入主菜单"
reading "\n确定继续安装吗？【y/n】: " choice
  case "$choice" in
    [Yy])
        cd "${WORKDIR}"
        read_vmess_port
        read_hy2_port
        read_socks_variables
        argo_configure
        read_nz_variables
        generate_config
        download_singbox
        run_nezha
        run_sb
        run_argo
        get_links
        creat_corn ;;
    [Nn]) menu ;;
    *) red "无效的选择，请输入 y 或 n" && install_singbox ;;
  esac
}

#设置vmess端口
read_vmess_port() {
    while true; do
        reading "请输入vmess端口 (面板开放的tcp端口): " vmess_port
        if [[ "$vmess_port" =~ ^[0-9]+$ ]] && [ "$vmess_port" -ge 1 ] && [ "$vmess_port" -le 65535 ]; then
            green "你的vmess端口为: $vmess_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done
}

# 设置hy2端口
read_hy2_port() {
    while true; do
        reading "请输入hysteria2端口 (面板开放的UDP端口): " hy2_port
        if [[ "$hy2_port" =~ ^[0-9]+$ ]] && [ "$hy2_port" -ge 1 ] && [ "$hy2_port" -le 65535 ]; then
            green "你的hysteria2端口为: $hy2_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的UDP端口"
        fi
    done
}

# 设置socks5端口、用户名、密码
read_socks_variables() {
    while true; do
        reading "请输入socks端口 (面板开放的TCP端口): " socks_port
        if [[ "$socks_port" =~ ^[0-9]+$ ]] && [ "$socks_port" -ge 1 ] && [ "$socks_port" -le 65535 ]; then
            green "你的socks端口为: $socks_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done

    while true; do
        reading "请输入socks用户名: " socks_user
        if [[ ! -z "$socks_user" ]]; then
            green "你的socks用户名为: $socks_user"
            break
        else
            yellow "用户名不能为空，请重新输入"
        fi
    done

    while true; do
        reading "请输入socks密码，不能包含:和@符号: " socks_pass
        if [[ ! -z "$socks_pass" && ! "$socks_pass" =~ [:@] ]]; then
            green "你的socks密码为: $socks_pass"
            break
        else
            yellow "密码不能为空或包含非法字符(:和@)，请重新输入"
        fi
    done
}

# 设置 argo 隧道域名、json 或 token
argo_configure() {
  if [[ -z "${ARGO_AUTH}" || -z "${ARGO_DOMAIN}" ]]; then
    reading "是否需要使用固定 argo 隧道？【y/n】: " argo_choice
    [[ -z $argo_choice ]] && return
    [[ "$argo_choice" != "y" && "$argo_choice" != "Y" && "$argo_choice" != "n" && "$argo_choice" != "N" ]] && { red "无效的选择，请输入y或n"; return; }
    if [[ "$argo_choice" == "y" || "$argo_choice" == "Y" ]]; then
        reading "请输入 argo 固定隧道域名: " ARGO_DOMAIN
        green "你的 argo 固定隧道域名为: $ARGO_DOMAIN"
        reading "请输入 argo 固定隧道密钥（Json 或 Token）: " ARGO_AUTH
        green "你的 argo 固定隧道密钥为: $ARGO_AUTH"
        echo -e "${red}注意：${purple}使用 token，需要在 cloudflare 后台设置隧道端口和面板开放的 tcp 端口一致${re}"
    else
        green "ARGO 变量未设置，将使用临时隧道"
        return
    fi
  fi
  if [[ "${ARGO_AUTH}" =~ TunnelSecret ]]; then
    echo "${ARGO_AUTH}" > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: ${WORKDIR}/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vmess_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
    # 定义使用 json 时 agro 隧道的启动参数变量
    declare -g args="tunnel --edge-ip-version auto --config tunnel.yml run"
    green "ARGO_AUTH 是 Json 格式，将使用 Json 连接 ARGO；tunnel.yml 配置文件已生成"
  elif [[ "${ARGO_AUTH}" =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
    declare -g args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token \"${ARGO_AUTH}\""
    green "ARGO_AUTH 是 Token 格式，将使用 Token 连接 ARGO"
  else
    declare -g args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vmess_port"
    green "ARGO_AUTH 未定义，将使用 ARGO 临时隧道"
  fi
  # 生成 argo.sh 脚本
  cat > "${WORKDIR}/argo.sh" << EOF
#!/bin/bash

cd ${WORKDIR} || exit
export TMPDIR=$(pwd)
chmod +x ./bot
./bot ${args} >/dev/null 2>&1 &
EOF
  chmod +x "${WORKDIR}/argo.sh"
}

# 设置哪吒域名（或ip）、端口、密钥
read_nz_variables() {
  if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ]; then
      green "使用自定义变量运行哪吒探针"
      return
  else
      reading "是否需要安装哪吒探针？【y/n】: " nz_choice
      [[ -z $nz_choice ]] && return
      [[ "$nz_choice" != "y" && "$nz_choice" != "Y" ]] && return
      reading "请输入哪吒探针域名或ip：" NEZHA_SERVER
      green "你的哪吒域名为: $NEZHA_SERVER"
      reading "请输入哪吒探针端口（回车跳过默认使用5555）：" NEZHA_PORT
      [[ -z "${NEZHA_PORT}" ]] && NEZHA_PORT="5555"
      green "你的哪吒端口为: $NEZHA_PORT"
      reading "请输入哪吒探针密钥：" NEZHA_KEY
      green "你的哪吒密钥为: $NEZHA_KEY"
  fi
  # 处理 NEZHA_TLS 参数
  tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
  if [[ "${tlsPorts[*]}" =~ "${NEZHA_PORT}" ]]; then
    NEZHA_TLS="--tls"
  else
    NEZHA_TLS=""
  fi
  # 生成 nezha.sh 脚本
  cat > "${WORKDIR}/nezha.sh" << EOF
#!/bin/bash

cd ${WORKDIR} || exit
export TMPDIR=$(pwd)
chmod +x ./npm
./npm -s "${NEZHA_SERVER}:${NEZHA_PORT}" -p "${NEZHA_KEY}" "${NEZHA_TLS}" >/dev/null 2>&1 &
EOF
  chmod +x "${WORKDIR}/nezha.sh"
}

# 下载singbo文件
download_singbox() {
  ARCH=$(uname -m) && DOWNLOAD_DIR="." && mkdir -p "${DOWNLOAD_DIR}" && FILE_INFO=()
  if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
      FILE_INFO=("${SB_WEB_ARMURL} web" "${AG_BOT_ARMURL} bot" "${NZ_NPM_ARMURL} npm")
  elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
      FILE_INFO=("${SB_WEB_X86URL} web" "${AG_BOT_X86URL} bot" "${NZ_NPM_X86URL} npm")
  else
      echo "不支持的系统架构: $ARCH"
      exit 1
  fi
  for entry in "${FILE_INFO[@]}"; do
      URL=$(echo "$entry" | cut -d ' ' -f 1)
      NEW_FILENAME=$(echo "$entry" | cut -d ' ' -f 2)
      FILENAME="${DOWNLOAD_DIR}/${NEW_FILENAME}"
      if [ -e "${FILENAME}" ]; then
          green "$FILENAME 已经存在，跳过下载"
      else
          echo "正在下载 $FILENAME"
          if wget -q -O "${FILENAME}" "${URL}"; then
              green "$FILENAME 下载完成"
          else
              red "$FILENAME 下载失败"
              exit 1
          fi
      fi
      chmod +x "${FILENAME}"
  done
}

# 获取argo隧道的域名
get_argodomain() {
  if [[ -n "${ARGO_AUTH}" ]]; then
    echo ${ARGO_DOMAIN}
  else
    grep -oE 'https://[[:alnum:]+\.-]+\.trycloudflare\.com' boot.log | sed 's@https://@@'
  fi
}

# 运行 NEZHA 服务
run_nezha() {
  if [ -e "${WORKDIR}/nezha.sh" ] && [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ]; then
    purple "NEZHA 变量均已设置，且脚本文件已生成"
    cd "${WORKDIR}"
    export TMPDIR=$(pwd)
    [ -x "${WORKDIR}/nezha.sh" ] || chmod +x "${WORKDIR}/nezha.sh"
    [ -x "${WORKDIR}/npm" ] || chmod +x "${WORKDIR}/npm"
    nohup ./nezha.sh >/dev/null 2>&1 &
    sleep 2
    if pgrep -x 'npm' > /dev/null; then
       green "NEZHA 正在运行"
    else
       red "NEZHA 未运行，重启中……"
       pkill -x 'npm' 2>/dev/null
       nohup ./nezha.sh >/dev/null 2>&1 &
       sleep 2
          if pgrep -x 'npm' > /dev/null; then
             green "NEZHA 已重启"
          else
             red "NEZHA 重启失败"
          fi
    fi
  else
    purple "NEZHA 变量为空，跳过运行"
  fi
}

# 运行 singbox 服务
run_sb() {
  if [ -e "${WORKDIR}/web" ] && [ -e "${WORKDIR}/config.json" ]; then
    cd "${WORKDIR}"
    export TMPDIR=$(pwd)
    [ -x "${WORKDIR}/web" ] || chmod +x "${WORKDIR}/web"
    [ -e "${WORKDIR}/config.json" ] || chmod 777 "${WORKDIR}/config.json"
    nohup ./web run -c config.json >/dev/null 2>&1 &
    sleep 2
    if pgrep -x 'web' > /dev/null; then
       green "singbox 正在运行"
    else
       red "singbox 未运行，重启中……"
       pkill -x 'web' 2>/dev/null
       nohup ./web run -c config.json >/dev/null 2>&1 &
       sleep 2
          if pgrep -x 'web' > /dev/null; then
             green "singbox 已重启"
          else
             red "singbox 重启失败"
          fi
    fi
  fi
}

# 运行 argo 服务
run_argo() {
  if [ -e "${WORKDIR}/argo.sh" ] && [ -n "$ARGO_DOMAIN" ] && [ -n "$ARGO_AUTH" ]; then
    purple "ARGO 变量均已设置，且脚本文件已生成"
    cd "${WORKDIR}"
    export TMPDIR=$(pwd)
    [ -x "${WORKDIR}/argo.sh" ] || chmod +x "${WORKDIR}/argo.sh"
    [ -x "${WORKDIR}/bot" ] || chmod +x "${WORKDIR}/bot"
    nohup ./argo.sh >/dev/null 2>&1 &
    sleep 2
    if pgrep -x 'bot' > /dev/null; then
       green "ARGO 正在运行"
    else
       red "ARGO 未运行，重启中……"
       pkill -x 'bot' 2>/dev/null
       nohup ./argo.sh >/dev/null 2>&1 &
       sleep 2
          if pgrep -x 'bot' > /dev/null; then
             green "ARGO 已重启"
          else
             red "ARGO 重启失败"
          fi
    fi
  else
    red "ARGO 变量未设置"
  fi
}

# 获取服务器ip，如果ip被墙，则自动获取服务器域名
get_ip() {
  ip=$(curl -s --max-time 2 ipv4.ip.sb)
  if [ -z "$ip" ]; then
    ip=$( [[ "$HOSTNAME" =~ s[0-9]\.serv00\.com ]] && echo "${HOSTNAME/s/mail}" || echo "$HOSTNAME" )
  else
    url="https://www.toolsdaquan.com/toolapi/public/ipchecking/$ip/443"
    response=$(curl -s --location --max-time 3.5 --request GET "$url" --header 'Referer: https://www.toolsdaquan.com/ipcheck')
    if [ -z "$response" ] || ! echo "$response" | grep -q '"icmp":"success"'; then
        accessible=false
    else
        accessible=true
    fi
    if [ "$accessible" = false ]; then
        ip=$( [[ "$HOSTNAME" =~ s[0-9]\.serv00\.com ]] && echo "${HOSTNAME/s/mail}" || echo "$ip" )
    fi
  fi
  echo "$ip"
}

# 生成节点链接并写入到list.txt，同时检查 socks5 连接是否有效
get_links(){
argodomain=$(get_argodomain)
echo -e "\e[1;32mArgoDomain:\e[1;35m${argodomain}\e[0m\n"
sleep 1
IP=$(get_ip)
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g') 
sleep 1
yellow "注意：v2ray或其他软件的跳过证书验证需设置为true,否则hy2或tuic节点可能不通\n"
cat > list.txt <<EOF
vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$ISP\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/vmess?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)

vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$ISP\", \"add\": \"$CFIP\", \"port\": \"$CFPORT\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)

hysteria2://$UUID@$IP:$hy2_port/?sni=www.bing.com&alpn=h3&insecure=1#$ISP

socks5://$socks_user:$socks_pass@$IP:$socks_port
EOF
cat list.txt
purple "\n$WORKDIR/list.txt 节点文件已保存"
green "安装完成"
sleep 2

response=$(curl -s ip.sb --socks5 "$socks_user:$socks_pass@localhost:$socks_port")
  if [[ $? -eq 0 ]]; then
    if [[ "$response" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      green "SOCKS5 连接有效，服务器 IP 地址为: $response"
    else
      red "SOCKS5 连接无效，返回信息: $response"
    fi
  else
    red "SOCKS5 连接无效，检查端口设置是否正确"
  fi
}

# 是否创建面板corn定时任务
creat_corn() {
  reading "\n是否添加 crontab 守护进程的计划任务【y/n】: " choice
    case "$choice" in
        [Yy])
	   bash <(curl -s ${CORN_URL})
	   sleep 2
           menu ;;
        [Nn]) menu ;;
        *) red "无效的选择，请重新输入 y 或 n" && creat_corn ;;
    esac
}

# 卸载并重置服务器
clean_all() {
   echo ""
   green "1. 仅卸载singbox"
   echo  "----------------"
   green "2. 重置整个服务器"
   echo  "----------------"
   yellow "0. 返回主菜单"
   echo "----------------"
   reading "\n请输入选择 (0-2): " choice
   echo ""
     case "${choice}" in
        1) uninstall_singbox ;;
        2) clean_all_files ;;
        0) menu ;;
        *) red "无效的选项，请输入 0-2" && clean_all ;;
     esac
}

# 仅卸载 singbox
uninstall_singbox() {
  reading "\n确定要卸载吗？【y/n】: " choice
    case "${choice}" in
       [Yy])
          kill -9 $(ps aux | grep '[w]eb' | awk '{print $2}')
          kill -9 $(ps aux | grep '[b]ot' | awk '{print $2}')
          kill -9 $(ps aux | grep '[n]pm' | awk '{print $2}')
          rm -rf "${WORKDIR}"
          ;;
       [Nn]) menu ;;
       *) red "无效的选择，请重新输入 y 或 n" && uninstall_singbox ;;
    esac
}

# 一键重置服务器
clean_all_files() {
  reading "\n清理所有文件，重置服务器，确定继续吗？【y/n】: " choice
    case "${choice}" in
      [Yy])
        ps aux | grep "$(whoami)" | grep -v "sshd\|bash\|grep" | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
        chmod -R 755 ~/*
        chmod -R 755 ~/.* 
        rm -rf ~/.* 
        rm -rf ~/*
        sleep 2
        green "清理已完成" ;;
      [Nn]) menu ;; 
      *) red "无效的选择，请重新输入 y 或 n" && menu ;;
  esac
}

# 生成节点配置文件并解锁流媒体
generate_config() {
  openssl ecparam -genkey -name prime256v1 -out "private.key"
  openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=${USERNAME}.serv00.net"
  cat > config.json << EOF
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-openai"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
    "inbounds": [
    {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "::",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://bing.com",
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
    {
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmess_port,
      "users": [
      {
        "uuid": "$UUID"
      }
    ],
    "transport": {
      "type": "ws",
      "path": "/vmess",
      "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    },
    {
      "tag": "socks-in",
      "type": "socks",
      "listen": "::",
      "listen_port": $socks_port,
      "users": [
        {
          "username": "$socks_user",
          "password": "$socks_pass"
        }
      ]
    }

 ],
    "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    },
    {
      "type": "wireguard",
      "tag": "wireguard-out",
      "server": "162.159.195.100",
      "server_port": 4500,
      "local_address": [
        "172.16.0.2/32",
        "2606:4700:110:83c7:b31f:5858:b3a8:c6b1/128"
      ],
      "private_key": "mPZo+V9qlrMGCZ7+E6z2NI6NOV34PD++TpAR09PtCWI=",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [
        26,
        21,
        228
      ]
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-openai"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-netflix.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-openai",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/openai.srs",
        "download_detour": "direct"
      },      
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "final": "direct"
   },
   "experimental": {
      "cache_file": {
      "path": "cache.db",
      "cache_id": "mycacheid",
      "store_fakeip": true
    }
  }
}
EOF
}

#主菜单
menu() {
   clear
   echo ""
   purple "--- Serv00|ct8 yutian81魔改sing-box一键脚本 ---\n"
   echo -e "${green}原作者为老王：${re}${yellow}https://github.com/eooce/Sing-box${re}\n"
   echo -e "${green}由yutian81魔改：${re}${yellow}https://github.com/yutian81/serv00-ct8-ssh${re}\n"
   purple "转载请著名出处，请勿滥用\n"
   red "1. 安装sing-box"
   echo  "----------------"
   red "2. 卸载或清理服务器"
   echo  "----------------"
   green "3. 查看节点信息"
   echo  "----------------"
   green "4. 重启所有进程"
   echo  "----------------"
   yellow "5. 写入面板CORN任务"
   echo  "----------------"
   yellow "6. 更新最新脚本"
   echo  "----------------"
   red "0. 退出脚本"
   echo "----------------"
   reading "请输入选择(0-6): " choice
   echo ""
    case "${choice}" in
        1) install_singbox ;;
        2) clean_all ;; 
        3) cat ${WORKDIR}/list.txt ;; 
        4) bash <(curl -s ${REBOOT_URL}) ;;
        5) creat_corn ;;
        6) curl -s ${UPDATA_URL} -o sb00.sh && chmod +x sb00.sh && ./sb00.sh ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 6" && menu ;;
    esac
}
menu
