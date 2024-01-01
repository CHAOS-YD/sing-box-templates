#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <template file> <output directory>"
  exit 1
fi
template=$1
output_dir=$2
if [ ! -f "$template" ]; then
  echo "File does not exist."
  exit 1
fi

# 更多 DNS 参考: https://senzyo.net/2022-22/
dns_global_list=(
  # AdGuard DNS
  https://94.140.14.140/dns-query
  https://94.140.14.141/dns-query
  tls://94.140.14.140
  tls://94.140.14.141
  # Cisco OpenDNS
  https://208.67.220.220/dns-query
  https://208.67.222.222/dns-query
  tls://208.67.220.220
  tls://208.67.222.222
  # Cloudflare DNS
  https://1.1.1.1/dns-query
  https://1.0.0.1/dns-query
  tls://1.1.1.1
  tls://1.0.0.1
  # Google DNS
  https://8.8.8.8/dns-query
  https://8.8.4.4/dns-query
  tls://8.8.8.8
  tls://8.8.4.4
)
cdn_snippet_list=(
  https://fastly.jsdelivr.net/gh/senzyo/sing-box-rules@master/
  https://gcore.jsdelivr.net/gh/senzyo/sing-box-rules@master/
  https://testingcf.jsdelivr.net/gh/senzyo/sing-box-rules@master/
  https://mirror.ghproxy.com/https://raw.githubusercontent.com/senzyo/sing-box-rules/master/
  https://ghproxy.net/https://raw.githubusercontent.com/senzyo/sing-box-rules/master/
  https://ghproxy.senzyo.net/https://raw.githubusercontent.com/senzyo/sing-box-rules/master/
)

for dns_global in "${dns_global_list[@]}"; do
  if [[ $dns_global =~ "https:" ]]; then
    dns_protocol="doh"
    dns_china="https://223.5.5.5/dns-query"
  fi
  if [[ $dns_global =~ "tls:" ]]; then
    dns_protocol="dot"
    dns_china="tls://223.5.5.5"
  fi
  dns_server=$(echo "$dns_global" | awk -F/ '{print $3}')
  if [ -n "$dns_server" ]; then
    echo "Matched $dns_protocol of $dns_server"
    for cdn_snippet in "${cdn_snippet_list[@]}"; do
      cdn_server=$(echo "$cdn_snippet" | awk -F/ '{print $3}')
      if [ -n "$cdn_server" ]; then
        echo "Matched $cdn_server"
        final_output_dir=$output_dir/$dns_protocol/$dns_server/$cdn_server
        mkdir -p $final_output_dir
        jq --arg dns_china "$dns_china" --arg dns_global "$dns_global" --arg cdn_snippet "$cdn_snippet" \
          '.dns.servers[] |= if .tag=="国外DNS" then .address = $dns_global elif .tag=="国内DNS" then .address = $dns_china else . end | .route.rule_set[].url |= sub("https.*?master\/"; $cdn_snippet)' $template >$final_output_dir/config.json
      else
        echo "Not matched."
      fi
    done
  else
    echo "Not matched."
  fi
done
