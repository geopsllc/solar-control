#!/bin/bash

i=1
sp="/-\|"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m'

als="$(cat $HOME/.bashrc | grep ccontrol)"
ccc="$(cat $HOME/.bashrc | grep cccomp)"
env="$(cat $HOME/.bashrc | grep env)"

if [ -f "$HOME/.solarrc" ]; then
  pmtwo="$(cat $HOME/.solarrc | grep env)"
  if [ ! -z "$pmtwo" ]; then
    sudo sed -i "/pm2/c alias pm2=\"$HOME/.solar/.pnpm/bin/pm2\"" $HOME/.solarrc > /dev/null 2>&1
  fi
fi

if [ -z "$als" ]; then
  echo "alias ccontrol=$PWD/ccontrol.sh" >> $HOME/.bashrc
fi

if [ -z "$ccc" ]; then
  echo "source $PWD/cccomp.bash" >> $HOME/.bashrc
fi

if [ -f "$core/packages/core/package.json" ]; then
  corever=$(cat $core/packages/core/package.json | jq -r '.version')
fi

if [ -f "$HOME/install.sh" ]; then
  rm $HOME/install.sh
  setefile
fi
