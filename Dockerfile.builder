FROM debian:11-slim

COPY minimize /etc/dpkg/dpkg.cfg.d/minimize

RUN dpkg --clear-selections \
    && echo "apt install" | dpkg --set-selections \
    && echo "tzdata install" | dpkg --set-selections \
    && SUDO_FORCE_REMOVE=yes DEBIAN_FRONTEND=noninteractive apt-get --purge -y --allow-remove-essential dselect-upgrade \
    && SUDO_FORCE_REMOVE=yes DEBIAN_FRONTEND=noninteractive apt-get --purge -y --allow-remove-essential autoremove \
    && dpkg-query -Wf '${db:Status-Abbrev}\t${binary:Package}\n' | grep -E '^?i' | awk -F'\t' '{print $2 " install"}' | dpkg --set-selections \
    && sed -i -re 's#http://deb.debian.org/#http://ftp.jp.debian.org/#g' /etc/apt/sources.list \
    && apt-get update && apt-get install -y sudo tini \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN find /usr/share/doc \( -name 'copyright' -o -name 'changelog.Debian.*' \) -print | tar cf /copyright.tar -T - \
    && rm -rf /usr/share/doc /usr/share/man/* /usr/share/locale/*/LC_MESSAGES/*.mo /var/lib/apt/lists/*debian* /var/cache/apt/*.bin \
    && tar xf /copyright.tar -C / \
    && rm /copyright.tar

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
