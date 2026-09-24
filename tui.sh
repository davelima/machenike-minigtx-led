#!/bin/bash
# Machenike Mini GTX - Terminal User Interface

BACKEND="/usr/local/bin/machenike_rgb"

if [ ! -x "$BACKEND" ]; then
    echo "Error: Backend CLI not found at $BACKEND"
    exit 1
fi

# 1. Zone Selection
ZONE=$(whiptail --title "Machenike RGB Controller" --menu "Select Target Zone:" 15 50 3 \
"all" "Both LEDs" \
"top" "Top LED Only" \
"power" "Power Button Only" 3>&1 1>&2 2>&3)

# Exit if user hits Cancel
[ -z "$ZONE" ] && exit 0

# 2. Color Selection
COLOR=$(whiptail --title "Color Selection" --menu "Choose a color:" 15 50 7 \
"red" "" \
"green" "" \
"blue" "" \
"yellow" "" \
"cyan" "" \
"purple" "" \
"white" "" 3>&1 1>&2 2>&3)

[ -z "$COLOR" ] && exit 0

# 3. Mode/Animation
MODE=$(whiptail --title "Animation Mode" --menu "Select animation:" 15 50 5 \
"static" "Solid light" \
"breathe1" "Slow breathing" \
"breathe2" "Medium breathing" \
"breathe3" "Fast breathing" \
"off" "Turn off LED" 3>&1 1>&2 2>&3)

[ -z "$MODE" ] && exit 0

# 4. Brightness (Skip if turning off)
if [ "$MODE" != "off" ]; then
    BRIGHTNESS=$(whiptail --title "Brightness" --inputbox "Enter brightness percentage (0-100):" 10 50 "100" 3>&1 1>&2 2>&3)
    [ -z "$BRIGHTNESS" ] && exit 0
else
    BRIGHTNESS="0"
fi

# 5. Apply the changes
whiptail --title "Applying Hardware Changes" --infobox "Applying $COLOR to $ZONE zone..." 8 50

# Run the backend script (sudo is handled by our sudoers exception)
sudo $BACKEND --zone "$ZONE" --color "$COLOR" --brightness "$BRIGHTNESS" --mode "$MODE"

sleep 1
clear
