#!/bin/bash

rm -f MotionLogo-Light.mp4 || true
rm -f MotionLogo-Light.gif || true
rm -f MotionLogo-Light-Cropped.gif || true

rm -f MotionLogo-Dark.mp4 || true
rm -f MotionLogo-Dark.gif || true
rm -f MotionLogo-Dark-Cropped.gif || true

# light

ffmpeg -r 60 -pattern_type glob -i "light/*.png" -c:v libx265 -x265-params lossless=1 MotionLogo-Light.mp4

gifski --fps 50 --width 2732 --height 2048 --extra --quality 100 --motion-quality 100 --lossy-quality 100 --repeat 0 -o MotionLogo-Light.gif MotionLogo-Light.mp4

gifsicle --crop 000,640+2732x768 --output MotionLogo-Light-Cropped.gif MotionLogo-Light.gif

# dark

ffmpeg -r 60 -pattern_type glob -i "dark/*.png" -c:v libx265 -x265-params lossless=1 MotionLogo-Dark.mp4

gifski --fps 50 --width 2732 --height 2048 --extra --quality 100 --motion-quality 100 --lossy-quality 100 --repeat 0 -o MotionLogo-Dark.gif MotionLogo-Dark.mp4

gifsicle --crop 000,640+2732x768 --output MotionLogo-Dark-Cropped.gif MotionLogo-Dark.gif
