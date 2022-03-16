#!/bin/bash

wrong_arguments () {

  echo -e "\nMissing: arg1 [arg2]\n"
  echo -e " -------------------------------------------------------------------------------"
  echo -e "| arg1      | arg2                         | Description                        |"
  echo -e " -------------------------------------------------------------------------------"
  echo -e "| install   | core                         | Install Core                       |"
  echo -e "| reinstall | core                         | Reinstall Core                     |"
  echo -e "| update    | core / self / check          | Update Core / Core-Control / Check |"
  echo -e "| remove    | core / self                  | Remove Core / Core-Control         |"
  echo -e "| secret    | set / clear                  | Delegate Secret Set / Clear        |"
  echo -e "| start     | relay / forger / all         | Start Core Services                |"
  echo -e "| restart   | relay / forger / all / safe  | Restart Core Services              |"
  echo -e "| stop      | relay / forger / all         | Stop Core Services                 |"
  echo -e "| status    | relay / forger / all         | Show Core Services Status          |"
  echo -e "| logs      | relay / forger / all         | Show Core Logs                     |"
  echo -e "| snapshot  | create / restore             | Snapshot Create / Restore          |"
  echo -e "| system    | info / update                | System Info / Update               |"
  echo -e "| config    | reset                        | Reset Config Files to Defaults     |"
  echo -e "| rollback  |                              | Rollback to Specified Height       |"
  echo -e " -------------------------------------------------------------------------------\n"
  exit 1

}

pm2status () {

   echo $(pm2 describe $1 2>/dev/null | grep "status")

}

git_check () {

  git fetch > /dev/null 2>&1
  loc=$(git rev-parse --short @)
  rem=$(git rev-parse --short @{u})

  if [ "$loc" = "$rem" ]; then
    up2date="yes"
  else
    up2date="no"
  fi

}

setefile () {

  local envFile="$config/.env"

  if [ -f $envFile ]; then
    rm $envFile
  fi

  touch "$envFile"

  echo "CORE_LOG_LEVEL=$log_level" >> "$envFile" 2>&1
  echo "CORE_LOG_LEVEL_FILE=$log_level" >> "$envFile" 2>&1
  echo "CORE_P2P_HOST=0.0.0.0" >> "$envFile" 2>&1
  echo "CORE_P2P_PORT=$p2p_port" >> "$envFile" 2>&1
  echo "CORE_API_HOST=0.0.0.0" >> "$envFile" 2>&1
  echo "CORE_API_PORT=$api_port" >> "$envFile" 2>&1
  echo "CORE_WEBHOOKS_HOST=0.0.0.0" >> "$envFile" 2>&1
  echo "CORE_WEBHOOKS_PORT=$wh_port" >> "$envFile" 2>&1

}

start () {

  local secrets=$(cat $config/delegates.json | jq -r '.secrets')

  if [ "$1" = "all" ]; then

    local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
    local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

    if [ "$rstatus" != "online" ]; then
      pm2 --name "${name}-relay" start $core/packages/core/bin/run -- relay:run --network $network --token $name > /dev/null 2>&1
    else
      echo -e "\n${red}Process relay already running. Skipping...${nc}"
    fi

    if [ "$secrets" = "[]" ]; then
      echo -e "\n${red}Delegate secret is missing. Forger start aborted!${nc}"
    elif [ "$fstatus" != "online" ]; then
      pm2 --name "${name}-forger" start $core/packages/core/bin/run -- forger:run --network $network --token $name > /dev/null 2>&1
    else
      echo -e "\n${red}Process forger already running. Skipping...${nc}"
    fi

    local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

    if [ "$rstatus" != "online" ]; then
      echo -e "\n${red}Process startup failed.${nc}"
    fi

  else

    local pstatus=$(pm2status "${name}-$1" | awk '{print $4}')

    if [[ "$secrets" = "[]" && "$1" = "forger" ]]; then
      echo -e "\n${red}Delegate secret is missing. Forger start aborted!${nc}"
    elif [ "$pstatus" != "online" ]; then
      pm2 --name "${name}-$1" start $core/packages/core/bin/run -- ${1}:run --network $network --token $name > /dev/null 2>&1
    else
      echo -e "\n${red}Process $1 already running. Skipping...${nc}"
    fi

    local pstatus=$(pm2status "${name}-$1" | awk '{print $4}')

    if [[ "$pstatus" != "online" && "$1" = "relay" ]]; then
      echo -e "\n${red}Process startup failed.${nc}"
    fi

  fi

  pm2 save > /dev/null 2>&1

}

restart () {

  if [ "$1" = "all" ]; then

    local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
    local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

    if [ "$rstatus" = "online" ]; then
      pm2 restart ${name}-relay > /dev/null 2>&1
    else
      echo -e "\n${red}Process relay not running. Skipping...${nc}"
    fi

    if [ "$fstatus" = "online" ]; then
      pm2 restart ${name}-forger > /dev/null 2>&1
    else
      echo -e "\n${red}Process forger not running. Skipping...${nc}"
    fi

  elif [ "$1" = "safe" ]; then

    local api=$(curl -Is http://127.0.0.1:$(($p2p_port+1000)))
    local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
    local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

    if [[ "$rstatus" != "online" || "$fstatus" != "online" ]]; then
      echo -e "\n${red}Core forger is offline. Use '${cyan}ccontrol restart${red}' instead.${nc}\n"
      exit 1
    elif [ -z "$api" ]; then
      echo -e "\n${red}Plugin round-monitor not active. Use '${cyan}ccontrol restart${red}' instead.${nc}\n"
      exit 1
    else
      curl -X POST http://127.0.0.1:$(($p2p_port+1000))/restart > /dev/null 2>&1
      echo -e "\n${green}Restart requested. Check logs to monitor progress.${nc}"
    fi

  else

    local pstatus=$(pm2status "${name}-$1" | awk '{print $4}')

    if [ "$pstatus" = "online" ]; then
      pm2 restart ${name}-$1 > /dev/null 2>&1
    else
      echo -e "\n${red}Process $1 not running. Skipping...${nc}"
    fi

  fi

}

stop () {

  if [ "$1" = "all" ]; then

    local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
    local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

    if [ "$rstatus" = "online" ]; then
      pm2 stop ${name}-relay > /dev/null 2>&1
    else
      echo -e "\n${red}Process relay not running. Skipping...${nc}"
    fi

    if [ "$fstatus" = "online" ]; then
      pm2 stop ${name}-forger > /dev/null 2>&1
    else
      echo -e "\n${red}Process forger not running. Skipping...${nc}"
    fi

  else

    local pstatus=$(pm2status "${name}-$1" | awk '{print $4}')

    if [ "$pstatus" = "online" ]; then
      pm2 stop ${name}-$1 > /dev/null 2>&1
    else
      echo -e "\n${red}Process $1 not running. Skipping...${nc}"
    fi

  fi

  pm2 save > /dev/null 2>&1

}

status () {

  echo -e -n "\n${cyan}${name}-core${nc} v${cyan}${corever}${nc} "

  if [ "$1" = "all" ]; then

    local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
    local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

    if [ "$rstatus" = "online" ]; then
      echo -ne "relay: ${green}online${nc} "
    else
      echo -ne "relay: ${red}offline${nc} "
    fi

    if [ "$fstatus" = "online" ]; then
      echo -e "forger: ${green}online${nc}\n"
    else
      echo -e "forger: ${red}offline${nc}\n"
    fi

  else

    local pstatus=$(pm2status "${name}-$1" | awk '{print $4}')

    if [ "$pstatus" = "online" ]; then
      echo -e "$1: ${green}online${nc}\n"
    else
      echo -e "$1: ${red}offline${nc}\n"
    fi

  fi

}

install_deps () {

  sudo timedatectl set-ntp no > /dev/null 2>&1
  sudo apt install -y htop curl build-essential python git libpq-dev ntp gawk jq libjemalloc-dev > /dev/null 2>&1

}

secure () {

  local ssh_port="22"
  local ssh_sys_port=$(cat /etc/ssh/sshd_config | grep ^Port | tail -1 | awk '{print $2}')
  if [[ "$ssh_port" != "$ssh_sys_port" && ! -z "$ssh_sys_port" ]]; then
    ssh_port=$ssh_sys_port
  fi

  sudo apt install -y ufw fail2ban > /dev/null 2>&1
  sudo ufw allow ${ssh_port}/tcp > /dev/null 2>&1
  sudo ufw allow ${p2p_port}/tcp > /dev/null 2>&1
  sudo ufw allow ${api_port}/tcp > /dev/null 2>&1
  sudo ufw --force enable > /dev/null 2>&1
  sudo sed -i "/^PermitRootLogin/c PermitRootLogin prohibit-password" /etc/ssh/sshd_config > /dev/null 2>&1
  sudo systemctl restart sshd.service > /dev/null 2>&1

}

install_core () {

  cd $HOME > /dev/null 2>&1
  curl -o install.sh https://raw.githubusercontent.com/solar-network/core/develop/install.sh > /dev/null 2>&1
  bash install.sh &
  while [ -d /proc/$! ]; do
      sleep .1
  done
  rm install.sh

}

remove () {

  pm2 delete ${name}-forger > /dev/null 2>&1
  pm2 delete ${name}-relay > /dev/null 2>&1
  pm2 save > /dev/null 2>&1
  sudo ufw delete allow $p2p_port/tcp > /dev/null 2>&1
  sudo ufw delete allow $api_port/tcp > /dev/null 2>&1

  $core/packages/core/bin/run uninstall --network $network --token $name

}

config_reset () {

  stop all > /dev/null 2>&1
  rm -rf $config > /dev/null 2>&1
  cp -rf "$core/packages/core/bin/config/$network" "$data" > /dev/null 2>&1
  setefile

}

sysinfo () {

  local sockets="$(lscpu | grep "Socket(s):" | head -n1 | awk '{ printf $2 }')"
  local cps="$(lscpu | grep "Core(s) per socket:" | awk '{ printf $4 }')"
  local tpc="$(lscpu | grep "Thread(s) per core:" | awk '{ printf $4 }')"
  local os="$(lsb_release -d | awk '{ for (i=2;i<=NF;++i) printf $i " " }')"
  local cpu="$(lscpu | grep "Model name" | awk '{ for (i=3;i<=NF;++i) printf $i " " }')"
  local mhz="$(lscpu | grep "CPU MHz:" | awk '{ printf $3 }' | cut -f1 -d".")"
  local maxmhz="$(lscpu | grep "CPU max MHz:" | awk '{ printf $4 }' | cut -f1 -d".")"
  local hn="$(hostname --fqdn)"
  local ips="$(hostname --all-ip-address)"

  echo -e "\n${cyan}System: ${nc}$os"
  w | head -n1

  echo -e "\n${cyan}CPU(s): ${nc}${sockets}x ${cpu}with $cps Cores and $[cps*tpc] Threads"
  echo -ne " ${cyan}Total: ${nc}$[sockets*cps] Cores and $[sockets*cps*tpc] Threads"
  if [ -z "$maxmhz" ]; then
    echo -e " @ ${mhz}MHz"
  else
    echo -e " @ ${maxmhz}MHz"
  fi

  echo -e "\n${cyan}Hostname: ${nc}$hn"
  echo -e " ${cyan}IP(s): ${nc}$ips"

  echo -e "${yellow}"
  free -h

  echo -e "${magenta}"
  df -h | grep -v tmpfs | grep -v udev | grep -v loop

  echo -e "${nc}"

}

sysupdate () {

  sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade -y
  sudo apt-get autoremove -y
  sudo apt-get autoclean -y

}

logs () {

  if [ "$1" = "all" ]; then
    pm2 logs
  else
    pm2 logs ${name}-$1
  fi

}

secret_clear () {

  jq '.secrets = []' $config/delegates.json > delegates.tmp
  mv delegates.tmp $config/delegates.json

}

secret_set12 () {

  local scrt="$1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}"
  jq --arg scrt "$scrt" '.secrets = [$scrt]' $config/delegates.json > delegates.tmp
  mv delegates.tmp $config/delegates.json

}

secret_set24 () {

  local scrt="$1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17} ${18} ${19} ${20} ${21} ${22} ${23} ${24}"
  jq --arg scrt "$scrt" '.secrets = [$scrt]' $config/delegates.json > delegates.tmp
  mv delegates.tmp $config/delegates.json

}

snapshot () {

  local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
  local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')
  stop all > /dev/null 2>&1

  if [ "$1" = "restore" ]; then
    $core/packages/core/bin/run snapshot:restore --network $network --token $name
  else
    $core/packages/core/bin/run snapshot:dump --network $network --token $name
  fi

  if [ "$rstatus" = "online" ]; then
    start relay > /dev/null 2>&1
  fi

  if [ "$fstatus" = "online" ]; then
    start forger > /dev/null 2>&1
  fi

}

selfremove () {

  cd $HOME > /dev/null 2>&1
  rm -rf $basedir > /dev/null 2>&1
  sed -i '/ccontrol/d' $HOME/.bashrc > /dev/null 2>&1
  sed -i '/cccomp/d' $HOME/.bashrc > /dev/null 2>&1

}

rollback () {

  local fstatus=$(pm2status "${name}-forger" | awk '{print $4}')
  local rstatus=$(pm2status "${name}-relay" | awk '{print $4}')

  stop all > /dev/null 2>&1

  $core/packages/core/bin/run snapshot:rollback --height $1 --network $network --token $name

  if [ "$rstatus" = "online" ]; then
    start relay > /dev/null 2>&1
  fi

  if [ "$fstatus" = "online" ]; then
    start forger > /dev/null 2>&1
  fi

}

update_info () {

  cd $basedir > /dev/null 2>&1
  git_check

  echo -e -n "\n${cyan}core-control${nc} v${cyan}${version}${nc} hash: ${cyan}${loc}${nc} status: "

  if [ "$up2date" = "yes" ]; then
    echo -e "${green}current${nc}\n"
  else
    echo -e "${red}stale${nc}\n"
  fi

}
