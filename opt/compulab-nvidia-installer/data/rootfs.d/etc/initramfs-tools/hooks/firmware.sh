#!/bin/sh

ln -fs nvidia/tegra186/xusb.bin ${DESTDIR}/lib/firmware/tegra18x_xusb_firmware
ln -fs nvidia/tegra194/xusb.bin ${DESTDIR}/lib/firmware/tegra19x_xusb_firmware

exit 0
