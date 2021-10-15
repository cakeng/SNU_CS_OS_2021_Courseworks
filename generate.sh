#!/bin/bash
./build-rpi3-arm64.sh
sudo ./scripts/mkbootimg_rpi3.sh
cp boot.img modules.img ../tizen-image