#!/bin/bash

rm MotionLogo-Light-Cropped.mov
rm MotionLogo-Light-Cropped.gif
rm MotionLogo-Dark-Cropped.mov
rm MotionLogo-Dark-Cropped.gif

ffmpeg -i MotionLogo-Light.mov -filter:v "crop=in_w-360:in_h-800" -c:a copy MotionLogo-Light-Cropped.mov

gifski --fps 29 -o MotionLogo-Light-Cropped.gif MotionLogo-Light-Cropped.mov

ffmpeg -i MotionLogo-Dark.mov -filter:v "crop=in_w-360:in_h-800" -c:a copy MotionLogo-Dark-Cropped.mov

gifski --fps 29 -o MotionLogo-Dark-Cropped.gif MotionLogo-Dark-Cropped.mov 
