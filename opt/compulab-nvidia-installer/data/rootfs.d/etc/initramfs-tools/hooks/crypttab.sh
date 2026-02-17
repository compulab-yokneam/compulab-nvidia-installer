#!/bin/sh

mkdir -p  "${DESTDIR}/cryptroot"
cp /etc/crypttab "${DESTDIR}/cryptroot/crypttab"
cp /etc/crypttab "${DESTDIR}/etc/"

mkdir -p  "${DESTDIR}/etc/keys"
cp -v /etc/keys/*.key "${DESTDIR}/etc/keys/"

exit 0
