#!/bin/bash
# -*- coding: utf-8 -*-
# (c) 2023, Salomão Domingos <salomaodomingos@gmail.com>
#
# NOME     : sshmount
# DESCRICAO: sshmount
# AUTOR    : Salomão Domingos
# DATA     : 02/11/2023
# ALTERACAO: XX/XX/XXXX
#

if [ ! -f $HOME/.environment ]; then
  if [ -e "/usr/local/sshmount/sshmount.sh" ]; then
    /usr/local/sshmount/sshmount-config.sh;
    exit -1
  else
    zenity --width=300 --height=200 --modal --question \
      --title="SSH Mount - [ Not default folder ]" \
      --text="Was this scripts pack installed?";

    if [ "$?" == "1" ]; then
      zenity --width=300 --height=150 --modal --error \
        --title="SSH Mount - [ Configuration error ]" \
        --text="Do must perform a proper instalation!";
      exit -9;
    else
      zenity --width=300 --height=150 --modal --error \
        --title="SSH Mount - [ Installation no default ]" \
        --text="Do must perform a proper instalation!";
      exit -1
    fi
  fi
fi

source $HOME/.environment 1>/dev/null 2>&1;

# Global variables
HORA=$(date +%F_%H:%M:%S);
LOG_FILE="$CONF_FOLDER/sshmount_$HORA.log";

HOSTS=""
NET_ADDR="";
NET_MASK_ADDR=""
CONFIG_FILE_NAME="";
TARGET_HOST="";
TMP_USER="";
TMP_PASS="";
LOCAL_HOST="";

get_inet_info() {
  iface=$(ip -o -4 route show to default | awk '{print $5}');
  ip_info=$(ip address show $iface | grep -Eo 'inet [0-9\.\/]+' | cut -d ' ' -f2);
  ip_address=$(echo $ip_info | cut -d '/' -f1);
  network_mask=$(echo $ip_info | cut -d '/' -f2);

  if [ "$network_mask" == "24" ]; then
    NET_MASK_ADDR="$(echo $ip_address | cut -d'.' -f1-3)";
    NET_ADDR="$(echo $ip_address | cut -d'.' -f1-3).0/24";
  elif [ "$network_mask" == "16" ]; then
    NET_MASK_ADDR="$(echo $ip_address | cut -d'.' -f1-2)";
    NET_ADDR="$(echo $ip_address | cut -d'.' -f1-2).0.0/16";
  elif [ "$network_mask" == "8" ]; then
    NET_MASK_ADDR="$(echo $ip_address | cut -d'.' -f1)";
    NET_ADDR="$(echo $ip_address | cut -d'.' -f1).0.0.0/8";
  else
    return 1
  fi

  LOCAL_HOST=$ip_address;
  return 0;
}

get_config_file_name() {
  CONFIG_FILE_NAME="$(echo $NET_ADDR | cut -d'/' -f1 ).dat";

  return 0;
}

get_host_list() {
  HOSTS=$(getent hosts | grep -v -e 127. -e 255. | grep "^$NET_MASK_ADDR\.");

  if [ -z "$HOSTS" ]; then
    zenity \
        --title="SSH Mount - [ Get Host ]" --width=260 --height=130 --modal --error \
        --text="Configure your hosts file."
    return 1;
  fi

  return 0;
}

get_target_host() {
  TARGET_HOST=$(zenity --width=400 --height=300 --modal --list --title="SSH Mount - [ Hosts available ]" --column="Address" --column="Name" $HOSTS);

  if [ -z $TARGET_HOST ]; then
    return 1;
  fi

  return 0;
}

validate_host() {
  (
    nmap -p 22 --open $TARGET_HOST -oG - | awk '/Up$/{print $2}' > $CONF_FOLDER/$TARGET_HOST.dat 2> $CONF_FOLDER/$TARGET_HOST.err;
  ) |
  zenity --width=360 --height=140 --modal --progress \
    --title="SSH Mount - [ Checking Target ]" \
    --text="Scanning local network..." \
    --pulsate \
    --auto-close

  if [ "$?" = -1 ] ; then
    rm -f $CONF_FOLDER/$TARGET_HOST.dat;
    rm -f $CONF_FOLDER/$TARGET_HOST.err;
    zenity --error \
      --text="Scanning canceled."
    return 1;
  fi

  if [ -s "$CONF_FOLDER/$TARGET_HOST.dat" ]; then
    rm -f $CONF_FOLDER/$TARGET_HOST.dat;
    rm -f $CONF_FOLDER/$TARGET_HOST.err;
  else
    rm -f $CONF_FOLDER/$TARGET_HOST.dat;
    return 1;
  fi

  if [ "$TARGET_HOST" == "$LOCAL_HOST" ]; then
    rm -f $CONF_FOLDER/$TARGET_HOST.dat;
    rm -f $CONF_FOLDER/$TARGET_HOST.err;
    zenity --title="SSH Mount - [ Validate ]" --width=260 --height=130 --modal --error \
      --text="You cannot to mount your own workstation."
    return 1;
  fi

  return 0;
}

authentication() {
  form_output=$(zenity --title="SSH Mount - [ Authentication ]" \
    --width=370 --height=165 --modal  \
    --modal \
    --forms --text="-- Login --" --add-entry="User name" --add-password="password");

  case $? in
    0)
      IFS='|' read -r TMP_USER TMP_PASS <<< "$form_output";
      echo "User: $TMP_USER";
      echo "Password: $TMP_PASS";

      return 0;
      ;;
    1)
      zenity \
        --title="SSH Mount - [ Authentication ]" --width=260 --height=130 --modal --error \
        --text="You must fill user name and password fields."
        return 1;
      ;;
    -1)
      zenity \
        --title="SSH Mount - [ Authentication ]" --width=260 --height=130 --modal --error \
        --text="An unexpected error has occurred."
      return 1
      ;;
  esac

  return 0;
}

ssh_mount() {
  if mountpoint -q "$MOUNT_POINT_FOLDER"; then
    notify-send "This file system already mounted!"
    return 1;
  else
    if ! sshfs -o ServerAliveInterval=15 -o reconnect -o StrictHostKeyChecking=accept-new -o password_stdin $TMP_USER@$TARGET_HOST:/home/$TMP_USER $MOUNT_POINT_FOLDER <<< $TMP_PASS 1> /dev/null 2>$LOG_FILE; then
      zenity --width=450 --height=300 --modal --text-info \
        --title="SSH Mount - [ mount - Error ]" \
        --filename=$LOG_FILE;
      
      rm -f $LOG_FILE;
      return 1;
    fi
  fi

  return 0;
}

if ! get_inet_info; then
  zenity --title="SSH Mount - [ Network ]" --width=260 --height=130 --modal --error \
    --text="Error getting netwoking infomation."
  exit 1;
fi

if ! get_config_file_name; then
  zenity --title="SSH Mount - [ Configuration ]" --width=260 --height=130 --modal --error \
    --text="Error getting config file."
  exit 2;
fi

if ! get_host_list; then
  zenity --title="SSH Mount - [ Menu error ]" --width=260 --height=130 --modal --error \
    --text="Error getting host list."
  exit 3;
fi

if ! get_target_host; then
  zenity --title="SSH Mount - [ Menu error ]" --width=260 --height=130 --modal --error \
    --text="Error getting host target."
  exit 4;
fi

if ! validate_host; then
  if [ -e "$CONF_FOLDER/$TARGET_HOST.err" ]; then
    zenity --title="SSH Mount - [ Menu error ]" --width=260 --height=130 --modal --warning \
      --text="Destination host unreachable.";
    rm -f $CONF_FOLDER/$TARGET_HOST.err;
  fi

  exit 5;
fi

if ! authentication; then
  exit 6;
fi

if ! ssh_mount; then
  exit 7;
fi

nohup nautilus > /dev/null 2>&1
exit 0;