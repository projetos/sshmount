#!/bin/bash
# -*- coding: utf-8 -*-
# (c) 2023, Salomão Domingos <salomaodomingos@gmail.com>
#
# NOME     : sshmount-config.sh
# DESCRICAO: Setup sshmount
# AUTOR    : Salomão Domingos
# DATA     : 03/11/2023
# ALTERACAO: XX/XX/XXXX
#

HORA=$(date +%F_%H:%M:%S);
LOG_ERR="./sshmount_$HORA.err";
CONF_FOLDER="$HOME/.config/sshmount";
MOUNT_POINT_FOLDER="";
CONFIG_FILE="$HOME/.environment";
INSTALL_FODER="/usr/local/bin/sshmount";

init() {
  if [ -d "$CONF_FOLDER" ]; then
    return 0;
  else
    if ! mkdir $CONF_FOLDER 1> /dev/null 2> $LOG_ERR; then
      return 1;
    fi
  fi

  return 0;
}

set_environment() {
  MOUNT_POINT_FOLDER=`zenity --width=450 --height=300 --modal --file-selection --directory --title="SSH Mount - [ Setting environment ]" --text="Select the mount point folder."`

  case $? in
    0)
      zenity --width=200 --height=130 --modal --info \
        --text="Environment setted.";

      return 0;
      ;;
    1)
      zenity --width=200 --height=130 --modal --warning \
        --text="Environment not setted.";

      return 1
      ;;
    -1)
      zenity --width=200 --height=130 --modal --error \
        --text="An unexpected error has occurred.";

      return 1;
      ;;
  esac

  echo "SAIU POR FORA";
  return 0;
}

zenity --width=300 --height=200 --modal --question \
  --title="SSH Mount - [ Configuration ]" \
  --text="It will erase all config files. Are you sure?";

if [ "$?" == "1" ]; then
  exit -1;
fi

if ! init; then
  zenity --width=450 --height=300 --modal --text-info \
    --title="SSH Mount - [ Configuration ]" \
    --filename=$LOG_ERR;
  
  rm -f $LOG_ERR;
  exit 1;
fi

rm -f $LOG_ERR;

if ! set_environment; then
  exit 1;
fi

echo "MOUNT_POINT_FOLDER=\"$MOUNT_POINT_FOLDER\"" > $CONFIG_FILE;
echo "CONF_FOLDER=\"$CONF_FOLDER\"" >> $CONFIG_FILE;

zenity --width=260 --height=130 --modal --info \
  --title="SSH Mount - [ Configuration ]" \
  --text="Configuration was done. Please execute sshmount again.";
exit 0;