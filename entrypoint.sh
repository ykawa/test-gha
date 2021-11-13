#!/bin/bash
#exec 9>debug_output.txt
#BASH_XTRACEFD=9
#PS4='$LINENO: '
#set -eux
set -eu
set -o pipefail

[ -e .env ] && . .env

if [ $(id -u) -eq $(id -u root) ]; then
  # rootユーザー時
  #------------------------------------------------------------
  # SET_GIDの指定が無い場合はカレントディレクトリの所有グループ
  # SET_UIDの指定が無い場合はカレントディレクトリの所有ユーザー
  # https://zenn.dev/anyakichi/articles/73765814e57cba
  #------------------------------------------------------------
  SET_GID=${SET_GID:-$(stat -c "%g" .)}
  SET_UID=${SET_UID:-$(stat -c "%u" .)}
  if [ $(id -u root) -eq $SET_UID -a $(id -g root) -eq $SET_GID ]; then
    # rootだったときはそのまま実行
    eval exec "$@"
  else
    if [[ -n ${HOME:+$HOME} ]]; then
      if [ $(getent passwd root | cut -d: -f6) = "$HOME" ]; then
        if getent passwd $SET_UID >/dev/null 2>&1; then
          HOME=$(getent passwd $SET_UID | cut -d: -f6)
        else
          # su-execと同じにするなら HOME=/
          HOME=$PWD
        fi
      fi
    fi
    eval exec setpriv --reuid=$SET_UID --regid=$SET_GID --groups $SET_GID "$@"
  fi
else
  # 一般ユーザー指定(-u)時はそのままexec
  eval exec "$@"
fi

