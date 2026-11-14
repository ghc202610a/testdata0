#!/usr/bin/bash -x
arecord -D default \
    -f S16_LE -r 48000 -c 2 \
    -d 30 3b.capture_default.wav
