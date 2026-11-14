#!/usr/bin/bash -x
E=~/dv/misc_small_utility_0/004/misc_small_utility_0/linux/mm/a/audio_monitor/audio_monitor.py
python3 ${E} --measure-capture \
    --input hw:CARD=Generic,DEV=2 \
    --measure-seconds 10
