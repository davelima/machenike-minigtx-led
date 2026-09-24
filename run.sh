#!/bin/bash
# Machenike Mini GTX - Smart CLI RGB Controller (Multi-Zone)
# Usage: sudo ./machenike_cli.sh --zone all --color cyan --brightness 100 --mode breathe2

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (sudo)."
  exit 1
fi

if [ ! -f /proc/acpi/call ]; then
  echo "Error: acpi_call module is not loaded."
  exit 1
fi

# --- Default Parameters ---
ZONE_IN="top"
MODE_IN="static"
BRIGHTNESS_IN="50"
COLOR_IN="white"

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -z|--zone) ZONE_IN="$2"; shift ;;
        -c|--color) COLOR_IN="$2"; shift ;;
        -b|--brightness) BRIGHTNESS_IN="$2"; shift ;;
        -m|--mode) MODE_IN="$2"; shift ;;
        -h|--help) 
            echo "Usage: sudo $0 [OPTIONS]"
            echo "Options:"
            echo "  -z, --zone        Target LED: top, power, or all"
            echo "  -c, --color       Color name (red, blue, cyan) OR Hex code (#FF0000)"
            echo "  -b, --brightness  Brightness level from 0 to 100"
            echo "  -m, --mode        Lighting mode: static, breathe1, breathe2, breathe3, off"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# --- 1. Parse Zone ---
# 01 maps to Top LED (MLED), 08 maps to Power Button (PLED)
case ${ZONE_IN,,} in
    top)   ZONES=("01") ;;
    power) ZONES=("08") ;;
    all)   ZONES=("01" "08") ;;
    *)     echo "Error: Invalid zone. Use 'top', 'power', or 'all'."; exit 1 ;;
esac

# --- 2. Parse Mode & Speed ---
# The target zone byte replaces the old mode byte. Speed byte handles animations.
IS_OFF=false

case ${MODE_IN,,} in
    off)      IS_OFF=true ;;
    static)   SPEED_HEX="00" ;;
    breathe|breathe1) SPEED_HEX="01" ;;
    breathe2) SPEED_HEX="02" ;;
    breathe3) SPEED_HEX="03" ;;
    *)        SPEED_HEX="00" ;;
esac

# --- 3. Parse Brightness (Scale 0-100 to Hardware 0-78) ---
if ! [[ "$BRIGHTNESS_IN" =~ ^[0-9]+$ ]] || [ "$BRIGHTNESS_IN" -gt 100 ]; then
    BRIGHTNESS_IN=100
fi

if [ "$IS_OFF" = true ]; then
    BRIGHT_HEX="00"
else
    BRIGHT_DEC=$(( BRIGHTNESS_IN * 78 / 100 ))
    BRIGHT_HEX=$(printf "%02X" $BRIGHT_DEC)
fi

# --- 4. Parse Color ---
COLOR_HEX="07" # Default to White

case ${COLOR_IN,,} in
    red)    COLOR_HEX="01" ;;
    green)  COLOR_HEX="02" ;;
    blue)   COLOR_HEX="03" ;;
    yellow) COLOR_HEX="04" ;;
    cyan)   COLOR_HEX="05" ;;
    purple) COLOR_HEX="06" ;;
    white)  COLOR_HEX="07" ;;
    *)
        CLEAN_HEX="${COLOR_IN/#\#/}"
        if [[ $CLEAN_HEX =~ ^[0-9A-Fa-f]{6}$ ]]; then
            R=$((16#${CLEAN_HEX:0:2}))
            G=$((16#${CLEAN_HEX:2:2}))
            B=$((16#${CLEAN_HEX:4:2}))

            BIT_R=$([ $R -gt 127 ] && echo 1 || echo 0)
            BIT_G=$([ $G -gt 127 ] && echo 1 || echo 0)
            BIT_B=$([ $B -gt 127 ] && echo 1 || echo 0)
            
            COMBINED="${BIT_R}${BIT_G}${BIT_B}"
            case $COMBINED in
                100) COLOR_HEX="01" ;; 
                010) COLOR_HEX="02" ;; 
                001) COLOR_HEX="03" ;; 
                110) COLOR_HEX="04" ;; 
                011) COLOR_HEX="05" ;; 
                101) COLOR_HEX="06" ;; 
                111|000) COLOR_HEX="07" ;; 
            esac
        else
            echo "Warning: Invalid color format. Defaulting to White."
        fi
        ;;
esac

# --- 5. Apply Payload to Hardware ---
ACPI_BASE="\_SB.PCI0.SBRG.EC0.AMW0"
SAVE="00"

# Unlock Mutex once for the entire batch
echo "${ACPI_BASE}.WCAA 1" > /proc/acpi/call

for ZONE_HEX in "${ZONES[@]}"; do
    BUFFER="b${ZONE_HEX}${BRIGHT_HEX}${COLOR_HEX}${SPEED_HEX}${SAVE}"
    
    ZONE_NAME="Top LED"
    [ "$ZONE_HEX" = "08" ] && ZONE_NAME="Power LED"

    echo "Applying to ${ZONE_NAME}: Color=$COLOR_IN, Brightness=${BRIGHTNESS_IN}%, Animation=${MODE_IN}"
    echo "${ACPI_BASE}.WSAA 0 ${BUFFER}" > /proc/acpi/call
    
    # Tiny pause to ensure the EC processes consecutive commands safely
    sleep 0.1
done

# Lock Mutex
echo "${ACPI_BASE}.WCAA 0" > /proc/acpi/call

