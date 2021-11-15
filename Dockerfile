FROM debian:11-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends tini \
  && apt-get -y clean \
  && apt-get -y --purge autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && { \
    echo '#!/bin/bash'; \
    echo 'set -eu'; \
    echo 'set -o pipefail'; \
    echo ''; \
    echo '[ -e .env ] && . .env'; \
    echo ''; \
    echo 'init_wrapper()'; \
    echo '{'; \
    echo '  if egrep "^/sbin/docker-init" /proc/1/cmdline >/dev/null 2>&1; then'; \
    echo '    exec "$@"'; \
    echo '  else'; \
    echo '    exec /usr/bin/tini -- "$@"'; \
    echo '  fi'; \
    echo '}'; \
    echo ''; \
    echo 'if [ $(id -u) -eq $(id -u root) ]; then'; \
    echo '  # rootユーザー時'; \
    echo '  #------------------------------------------------------------'; \
    echo '  # SET_GIDの指定が無い場合はカレントディレクトリの所有グループ'; \
    echo '  # SET_UIDの指定が無い場合はカレントディレクトリの所有ユーザー'; \
    echo '  # https://zenn.dev/anyakichi/articles/73765814e57cba'; \
    echo '  #------------------------------------------------------------'; \
    echo '  SET_GID=${SET_GID:-$(stat -c "%g" .)}'; \
    echo '  SET_UID=${SET_UID:-$(stat -c "%u" .)}'; \
    echo '  if [ $(id -u root) -eq $SET_UID -a $(id -g root) -eq $SET_GID ]; then'; \
    echo '    # rootだったときはそのまま実行'; \
    echo '    init_wrapper "$@"'; \
    echo '  else'; \
    echo '    if [[ -n ${HOME:+$HOME} ]]; then'; \
    echo '      if [ $(getent passwd root | cut -d: -f6) = "$HOME" ]; then'; \
    echo '        if getent passwd $SET_UID >/dev/null 2>&1; then'; \
    echo '          HOME=$(getent passwd $SET_UID | cut -d: -f6)'; \
    echo '        else'; \
    echo '          # su-execと同じにするなら HOME=/'; \
    echo '          HOME=$PWD'; \
    echo '        fi'; \
    echo '      fi'; \
    echo '    fi'; \
    echo '    #eval exec setpriv --reuid=$SET_UID --regid=$SET_GID --groups $SET_GID "$@"'; \
    echo '    init_wrapper setpriv --reuid=$SET_UID --regid=$SET_GID --groups $SET_GID "$@"'; \
    echo '  fi'; \
    echo 'else'; \
    echo '  # 一般ユーザー指定(-u)時はそのままexec'; \
    echo '  #eval exec "$@"'; \
    echo '  init_wrapper "$@"'; \
    echo 'fi'; \
  } > /entrypoint.sh \
  && chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "bash" ]
