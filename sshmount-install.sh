#!/bin/bash
# -*- coding: utf-8 -*-
# (c) 2023, Salomão Domingos <salomaodomingos@gmail.com>
#
# NOME     : sshmount-install.sh
# DESCRICAO: Install sshmount
# AUTOR    : Salomão Domingos
# DATA     : 02/11/2023
# ALTERACAO: XX/XX/XXXX
#

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root";
  exit 1;
fi

# Configurando ambiente
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

BRIGHT_RED='\e[91m'
BRIGHT_GREEN='\e[92m'
BRIGHT_YELLOW='\e[93m'
BRIGHT_BLUE='\e[94m'
BRIGHT_MAGENTA='\e[95m'
BRIGHT_CYAN='\e[96m'
RESET='\e[0m'
#

# Variáveis globais
HORA=$(date +%F_%H:%M:%S);
HORA=$(date +%F_%H:%M:%S);
LOG_FILE=".sshmount_$HORA.log";
LOG_ERR=".sshmount_$HORA.err";

INSTALL_DIR="/usr/local/sshmount";

create_app_folder() {
  if [ -d "$INSTALL_DIR" ]; then
    echo -e "\n";
    echo -e "${BRIGHT_RED}It seams that sshmount already installed.${RESET}";
    echo -e "\n";
    return 1;
  else
    if ! sudo mkdir $INSTALL_DIR 1>> $LOG_FILE 2>> $LOG_ERR; then
      return 1;
    fi
  fi

  return 0;
}

copy_files() {
  if cp -f *.sh *.svg $INSTALL_DIR 1>> $LOG_FILE 2>> $LOG_ERR; then
    return 0;
  fi

  return 1;
}

create_sym_links() {
  source=("/usr/local/sshmount/sshmount.sh" "/usr/local/sshmount/sshmount-config.sh");
  target=("/usr/local/bin/sshmount" "/usr/local/bin/sshmount-config");

  if [ ${#source[@]} -ne ${#target[@]} ]; then
    exit 1
  fi

  for (( i=0; i<${#target[@]}; i++ )); do
    ln -s "${source[i]}" "${target[i]}" 2>/dev/null

    if [ $? -ne 0 ]; then
      return 1;
    fi
  done

  return 0;
}

register_app() {
  original_user=${SUDO_USER:-$(whoami)};

  if cp -f ./sshmount.desktop /home/$original_user/.local/share/applications 1>> $LOG_FILE 2>> $LOG_ERR; then
    return 0;
  fi

  return 1;
}

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

draw_progress_bar() {
  # Parameters
  local PROGRESS=$1        # Current progress
  local TOTAL=$2           # Total progress
  local FULL_SIZE=$3       # Size of the full progress bar
  local FILLED_SIZE=$((PROGRESS * FULL_SIZE / TOTAL)) # Number of '=' characters

  # Create the progress bar string
  local BAR=''
  for ((i=0; i<FULL_SIZE; i++)); do
    if [ $i -lt $FILLED_SIZE ]; then
      BAR="${BAR}="
    else
      BAR="${BAR} "
    fi
  done

  # Print the progress bar
  printf "\r[%-${FULL_SIZE}s] %s%%" "$BAR" $((PROGRESS * 100 / TOTAL))
}

echo -e "\n";
echo -e "${BRIGHT_CYAN}Installing sshmount...${RESET}";
echo -e "\n";
draw_progress_bar 1 5 50;

if ! create_app_folder; then
  echo -e "\n";
  echo -e "${BRIGHT_RED}Error creating app folder.${RESET}";
  clean_up;
  exit 1;
fi

draw_progress_bar 10 10 50;
if ! copy_files; then
  echo -e "\n";
  echo -e "${BRIGHT_RED}Error copying app files.${RESET}";
  clean_up;
  exit 2;
fi

draw_progress_bar 15 15 50;
if ! create_sym_links; then
  echo -e "\n";
  echo -e "${BRIGHT_RED}Error creating sym links - see log error.${RESET}";
  clean_up;
  exit 3;
fi

draw_progress_bar 30 30 50;
if ! register_app; then
  echo -e "\n";
  echo -e "${BRIGHT_RED}Error registering application.${RESET}";
  # echo -e "\n";
  clean_up;
  exit 4;
fi

draw_progress_bar 40 40 50;

rm -f $LOG_FILE;
rm -f $LOG_ERR;

draw_progress_bar 50 50 50;
echo -e "\n";
echo -e "${BRIGHT_GREEN}Installation was succeded.${RESET}";
exit 0;