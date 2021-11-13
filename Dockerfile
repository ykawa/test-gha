FROM scratch

ADD rootfs.tar.gz /

ENTRYPOINT [ "/usr/bin/tini", "--", "/entrypoint.sh" ]

CMD [ "bash" ]
