#!/bin/bash
# -*- coding: utf-8 -*-
# (c) 2023, Salomão Domingos <salomaodomingos@gmail.com>
#
# NOME     : sshmount-config
# DESCRICAO: Conecta ao VPS
# AUTOR    : Salomão Domingos
# DATA     : 03/11/2023
# ALTERACAO: XX/XX/XXXX
#

source $HOME/.environment 1>/dev/null 2>&1;

# Configurando ambiente
red='\e[1;31m';
purple='\e[1;35m';
gree='\e[1;32m';
blue='\e[1;34m';
end='\e[0m';
#

# Variáveis globais
HORA=$(date +%F_%H:%M:%S);
NET_ADDR="";
CONFIG_FILE_NAME="";
CONF_FOLDER="$HOME/.config/sshmount";
LOG_FILE="$CONF_FOLDER/sshscan_$HORA.log";
LOG_ERR="$CONF_FOLDER/sshscan_$HORA.err";

init() {
  if [ -d "$CONF_FOLDER" ]; then
    return 0;
  else
    if ! mkdir $CONF_FOLDER; then
      return 1;
    fi
  fi

  return 0;
}

get_inet_info() {
  iface=$(ip -o -4 route show to default | awk '{print $5}');
  ip_info=$(ip address show $iface | grep -Eo 'inet [0-9\.\/]+' | cut -d ' ' -f2);
  ip_address=$(echo $ip_info | cut -d '/' -f1);
  network_mask=$(echo $ip_info | cut -d '/' -f2);

  if [ "$network_mask" == "24" ]; then
    NET_ADDR="$(echo $ip_address | cut -d'.' -f1-3).0/24";
  elif [ "$network_mask" == "16" ]; then
    NET_ADDR="$(echo $ip_address | cut -d'.' -f1-2).0.0/16";
  elif [ "$network_mask" == "8" ]; then
    NET_ADDR="$(echo $ip_address | cut -d'.' -f1).0.0.0/8";
  else
    return 1
  fi

  return 0;
}

get_config_file_name() {
  CONFIG_FILE_NAME="$(echo $NET_ADDR | cut -d'/' -f1 ).dat"
}

if ! init; then
  zenity --width=200 --height=130 --modal --error \
  --text="Error configuring application!"
  exit 1;
fi

if get_inet_info; then
  if ! get_config_file_name; then
    zenity --width=250 --height=140 --modal --error \
    --text="Error getting local informations!"
    exit 1;
  fi

  if [ -f $CONF_FOLDER/$CONFIG_FILE_NAME ]; then
    exit 0;
  fi

  (
    nmap -p 22 --open $NET_ADDR -oG - | awk '/Up$/{print $2}' > $CONF_FOLDER/$CONFIG_FILE_NAME 2> $LOG_ERR;
  ) |
  zenity --width=250 --height=140 --modal --progress \
    --title="Setting Up" \
    --text="Scanning local network..." \
    --pulsate

  if [ "$?" = -1 ] ; then
    rm -f $CONF_FOLDER/
    zenity --error \
      --text="Update canceled."
  fi
else
  zenity --width=200 --height=130 --modal --error \
  --text="Error getting local network informations!"
  exit 1;
  exit 2;
fi

exit 0;