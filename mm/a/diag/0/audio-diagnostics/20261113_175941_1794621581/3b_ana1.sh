#!/usr/bin/bash -x

sox 3b.capture_default.wav -n \
    remix 1 \
    spectrogram -x 1600 -y 512 -z 100 \
    -o 3b_spectrogram.png

sox 3b.capture_default.wav 3b_burst_12s.wav \
    trim 12 1

sox 3b_burst_12s.wav -n stats

