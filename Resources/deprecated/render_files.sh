#!/bin/bash

rm MotionLogo-Light.gif
rm MotionLogo-Light-Cropped.gif
rm MotionLogo-Dark.gif
rm MotionLogo-Dark-Cropped.gif

gifski --fps 50 --extra --width 1920 --height 1080 -o MotionLogo-Light.gif MotionLogo-Light.mov

gifsicle --crop 180,400+1560x280 --output MotionLogo-Light-Cropped.gif MotionLogo-Light.gif

gifski --fps 50 --extra --width 1920 --height 1080 -o MotionLogo-Dark.gif MotionLogo-Dark.mov 

gifsicle --crop 180,400+1560x280 --output MotionLogo-Dark-Cropped.gif MotionLogo-Dark.gif
