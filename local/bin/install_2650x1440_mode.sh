#!/bin/bash

sudo xrandr --newmode "2560x1440_60.00"  312.25  2560 2752 3024 3488  1440 1443 1448 1493 -hsync +vsync
sudo xrandr --addmode eDP-1 2560x1440_60.00
