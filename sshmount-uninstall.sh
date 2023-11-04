#!/bin/bash
# -*- coding: utf-8 -*-
# (c) 2023, Salomão Domingos <salomaodomingos@gmail.com>
#
# NOME     : sshmount-uninstall
# DESCRICAO: Uninstall sshmount
# AUTOR    : Salomão Domingos
# DATA     : 02/11/2023
# ALTERACAO: XX/XX/XXXX
#

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root";
  exit 1;
fi

clean_up() {
  original_user=${SUDO_USER:-$(whoami)};

  rm -f /home/$original_user/.local/share/applications/sshmount.desktop 1> /dev/null 2>&1;
  rm -f /home/$original_user/.environment 1> /dev/null 2>&1;
  rm -f /home/$original_user/.config/ssmbount/* 1> /dev/null 2>&1;
  rmdir /home/$original_user/.config/ssmbount 1> /dev/null 2>&1;

  rm -f /usr/local/bin/sshmount 1> /dev/null 2>&1;
  rm -f /usr/local/bin/sshmount-config 1> /dev/null 2>&1;
  rm -f /usr/local/sshmount/* 1> /dev/null 2>&1;
  rmdir /usr/local/sshmount/ 1> /dev/null 2>&1;
}

clean_up;
exit 0