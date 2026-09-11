#!/bin/bash
# Machenike Mini GTX - Smart CLI RGB Controller (Calibrated)
# Usage: sudo ./machenike_cli.sh --color cyan --brightness 100 --mode breathe2

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (sudo)."
  exit 1
fi

if [ ! -f /proc/acpi/call ]; then
  echo "Error: acpi_call module is not loaded."
  exit 1
fi

# --- Default Parameters ---
MODE_IN="static"
BRIGHTNESS_IN="50"
COLOR_IN="white"

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--color) COLOR_IN="$2"; shift ;;
        -b|--brightness) BRIGHTNESS_IN="$2"; shift ;;
        -m|--mode) MODE_IN="$2"; shift ;;
        -h|--help) 
            echo "Usage: sudo $0 [OPTIONS]"
            echo "Options:"
            echo "  -c, --color       Color name (red, blue, cyan) OR Hex code (#FF0000)"
            echo "  -b, --brightness  Brightness level from 0 to 100"
            echo "  -m, --mode        Lighting mode: static, breathe1, breathe2, breathe3, breathe4, off"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# --- 1. Parse Mode & Speed ---
# Byte 1 (Mode) MUST stay '01' to prevent the global white reset.
# Byte 4 (Speed) controls the breathing animation.
MODE_HEX="01" 
IS_OFF=false

case ${MODE_IN,,} in
    off)      IS_OFF=true ;;
    static)   SPEED_HEX="00" ;;
    breathe|breathe1) SPEED_HEX="01" ;;
    breathe2) SPEED_HEX="02" ;;
    breathe3) SPEED_HEX="03" ;;
    breathe4) SPEED_HEX="04" ;;
    *)        SPEED_HEX="00" ;;
esac

# --- 2. Parse Brightness (Scale 0-100 to Hardware 0-78) ---
if ! [[ "$BRIGHTNESS_IN" =~ ^[0-9]+$ ]] || [ "$BRIGHTNESS_IN" -gt 100 ]; then
    BRIGHTNESS_IN=100
fi

if [ "$IS_OFF" = true ]; then
    BRIGHT_HEX="00"
else
    # Scale user percentage (0-100) to hardware max (78)
    BRIGHT_DEC=$(( BRIGHTNESS_IN * 78 / 100 ))
    BRIGHT_HEX=$(printf "%02X" $BRIGHT_DEC)
fi

# --- 3. Parse Color ---
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
            # Extract RGB decimal values and snap to 7-color palette
            R=$((16#${CLEAN_HEX:0:2}))
            G=$((16#${CLEAN_HEX:2:2}))
            B=$((16#${CLEAN_HEX:4:2}))

            BIT_R=$([ $R -gt 127 ] && echo 1 || echo 0)
            BIT_G=$([ $G -gt 127 ] && echo 1 || echo 0)
            BIT_B=$([ $B -gt 127 ] && echo 1 || echo 0)
            
            COMBINED="${BIT_R}${BIT_G}${BIT_B}"
            case $COMBINED in
                100) COLOR_HEX="01" ;; # Red
                010) COLOR_HEX="02" ;; # Green
                001) COLOR_HEX="03" ;; # Blue
                110) COLOR_HEX="04" ;; # Yellow
                011) COLOR_HEX="05" ;; # Cyan
                101) COLOR_HEX="06" ;; # Purple
                111) COLOR_HEX="07" ;; # White
                000) COLOR_HEX="07" ;; # Black mapped to White
            esac
        else
            echo "Warning: Invalid color format. Defaulting to White."
        fi
        ;;
esac

# --- 4. Apply Payload ---
ACPI_BASE="\_SB.PCI0.SBRG.EC0.AMW0"
SAVE="00"

BUFFER="b${MODE_HEX}${BRIGHT_HEX}${COLOR_HEX}${SPEED_HEX}${SAVE}"

echo "Applying: Color=$COLOR_IN, Brightness=${BRIGHTNESS_IN}% (Hex: $BRIGHT_HEX), Animation=${MODE_IN}"

echo "${ACPI_BASE}.WCAA 1" > /proc/acpi/call
echo "${ACPI_BASE}.WSAA 0 ${BUFFER}" > /proc/acpi/call
echo "${ACPI_BASE}.WCAA 0" > /proc/acpi/call

