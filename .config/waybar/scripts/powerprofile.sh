#!/bin/bash

PROFILE=$(powerprofilesctl get)

case "$PROFILE" in
power-saver)
  echo ""
  ;;
balanced)
  echo ""
  ;;
performance)
  echo ""
  ;;
esac
