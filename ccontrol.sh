#!/bin/bash

basedir="$(dirname "$(cat $HOME/.bashrc | grep ccontrol | awk -F"=" '{print $2}')")"
execdir="$(dirname "$0")"

if [[ "$basedir" != "." && "$execdir" != "." ]]; then
  cd $basedir
elif [[ "$basedir" = "." && "$execdir" != "." ]]; then
  cd $PWD/$execdir
fi

basedir="$PWD"

. "project.conf"
. "functions.sh"
. "misc.sh"

main () {

  if [[ ( "$1" = "install" ) && ( "$2" = "core" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ -d $data || -d $core ]]; then
      echo -e "\n${red}Core already installed. Please remove first.${nc}\n"
      exit 1
    fi

    sysinfo
    sudo apt update > /dev/null 2>&1
    install_deps &

    echo -ne "${cyan}Installing Dependencies...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}"

    secure &

    echo -ne "${cyan}Securing System...  ${red}"

    while [ -d /proc/$! ]; do
      printf "\b${sp:i++%${#sp}:1}" && sleep .1
    done

    echo -e "\b${green}Done${nc}"

    install_core

  elif [[ ( "$1" = "reinstall" ) && ( "$2" = "core" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    sysinfo
    $HOME/.solar/bin/node $HOME/solar-core/packages/core/bin/run reinstall --token=$name --force

  elif [[ ( "$1" = "update" ) && ( "$2" = "core" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    $HOME/.solar/bin/node $HOME/solar-core/packages/core/bin/run update --token=$name --force --restart

  elif [[ ( "$1" = "config" ) && ( "$2" = "reset"  ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    config_reset &

    sleep 1
    echo -e "\n${cyan}Processes Stopped...${nc}"
    sleep 1
    echo -e "${cyan}Configs Replaced with Defaults...${nc}"
    echo -e "${green}All Done!${nc}\n"

  elif [[ ( "$1" = "start" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    start $2

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "restart" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || "$2" = "safe" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    restart $2

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "stop" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    stop $2

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "status" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    status $2

  elif [[ ( "$1" = "system" ) && ( "$2" = "info" || -z "$2" ) && ( -z "$3" ) ]]; then

    sysinfo

  elif [[ ( "$1" = "system" ) && ( "$2" = "update" ) && ( -z "$3" ) ]]; then

    sysinfo
    sudo apt update > /dev/null 2>&1
    sysupdate

  elif [[ ( "$1" = "logs" ) && ( "$2" = "relay" || "$2" = "forger" || "$2" = "all" || -z "$2" ) && ( -z "$3" ) ]]; then

    if [ -z "$2" ]; then
      set -- "$1" "all"
    fi

    logs $2

  elif [[ ( "$1" = "secret" ) && ( ( "$2" = "set" && ! -z "${14}" && -z "${15}" ) || ( "$2" = "set" && ! -z "${26}" && -z "${27}" ) || ( "$2" = "clear" && -z "$3" ) ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    if [[ "$2" = "set" && -z "${15}" ]]; then
      secret_set12 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14}
    elif [[ "$2" = "set" && -z "${27}" ]]; then
      secret_set24 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17} ${18} ${19} ${20} ${21} ${22} ${23} ${24} ${25} ${26}
    else
      secret_clear
    fi

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "update" ) && ( "$2" = "self" ) && ( -z "$3" ) ]]; then

    git pull

  elif [[ ( "$1" = "remove" ) && ( "$2" = "core" ) && ( -z "$3" ) ]]; then

    if [[ ! -d $data || ! -d $core ]]; then
      echo -e "\n${red}Core not installed. Please install first.${nc}\n"
      exit 1
    fi

    sysinfo
    sudo apt update > /dev/null 2>&1

    if [ ! -z "$env" ]; then
      sed -i '/env/d' $HOME/.bashrc > /dev/null 2>&1
    fi

    rm $HOME/.pm2/dump* > /dev/null 2>&1
    sudo ufw delete allow $p2p_port/tcp > /dev/null 2>&1
    sudo ufw delete allow $api_port/tcp > /dev/null 2>&1

    $HOME/.solar/bin/node $HOME/solar-core/packages/core/bin/run uninstall --token=$name --force

  elif [[ ( "$1" = "remove" ) && ( "$2" = "self" ) && ( -z "$3" ) ]]; then

    selfremove

    echo -e "\n${green}All Done!${nc}\n"

  elif [[ ( "$1" = "update" ) && ( "$2" = "check" || -z "$2" ) && ( -z "$3" ) ]]; then

    update_info

  elif [[ ( "$1" = "rollback" ) && ( ! -z "$2" ) && ( -z "$3" ) ]]; then

    rollback $2

  else

    wrong_arguments

  fi

  trap cleanup SIGINT SIGTERM SIGKILL

}

main "$@"
