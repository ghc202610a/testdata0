#!/usr/bin/bash -x
arecord -D default \
    -f S16_LE -r 48000 -c 2 \
    -d 30 3.capture_default.wav
