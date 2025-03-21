#!/bin/bash

calendar=(
  icon=􀐫
  icon.font="$FONT:Semibold:13.0"
  icon.padding_right=3
  label.align=right
  padding_left=20
  update_freq=10
  script="$PLUGIN_DIR/calendar.sh"
  click_script="$PLUGIN_DIR/zen.sh"
)

sketchybar --add item calendar right       \
           --set calendar "${calendar[@]}" \
           --subscribe calendar system_woke
