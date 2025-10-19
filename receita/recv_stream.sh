#!/bin/env bash

echo "Assim que a stream começar uma janela será aberta!"

gst-launch-1.0 udpsrc port=5000 caps="application/x-rtp, media=video, encoding-name=H264, payload=96" \
! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! autovideosink
