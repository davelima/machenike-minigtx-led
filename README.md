# Machenike Mini GTX Linux LED controller

This shell executable is used to control the top LED on the [Machenike Mini GTX PC](https://global.machenike.com/pt-br/products/gtx-minipc).
Unfortunately, the LEDs used on the chassis of this PC are not so common, so software
like `openrgb` doesn't support it, and since there is no official Linux controller,
I've built this one.

This is not (yet) close to the official Machenike Windows GUI, but it is functional.

## Before you use it
This project needs the `acpi_call` module enabled. For this project, I have used the
[Nix Community's acpi_call](https://github.com/nix-community/acpi_call/) and built it from source.

This executable is **NOT** thoroughly tested. I tested it on my own machine running Fedora 44 and
it is working just fine.

## How it works
The executable sends signals directly via ACPI to the hardware based on parameters you pass to it.

## How to use it
Once you have enabled the `acpi_call` module, the command should work without any extra configuration.
Since it deals with ACPI calls, you normally need to run it with `sudo`.

## What this software can do

- Change the LED colors:
```sh
# Top LED only
sudo ./run.sh --color red // or --zone top
# Output:
# Applying to Top LED: Color=red, Brightness=50%, Animation=static

# Power LED only
sudo ./run.sh --color red --zone power
# Output:
# Applying to Power LED: Color=red, Brightness=50%, Animation=static

# All LEDs
sudo ./run.sh --color red --zone all
# Output:
# Applying to Top LED: Color=red, Brightness=50%, Animation=static
# Applying to Power LED: Color=red, Brightness=50%, Animation=static
```

- Change brightness:
```sh
sudo ./run.sh --color red --brightness 100
# Output:
# Applying: Color=red, Brightness=100% (Hex: 4E), Animation=static
```

- Change the LED animation:
```sh
# breathe2 to 4 applies different speeds
sudo ./run.sh --color red --brightness 100 --mode breathe4
# Output:
# Applying: Color=red, Brightness=100% (Hex: 4E), Animation=bre

# Goes back to static
sudo ./run.sh --color red --brightness 100 --mode static
# Output:
# Applying: Color=red, Brightness=100% (Hex: 4E), Animation=static
```

- Turn the LED off:
```sh
sudo ./run.sh --mode off
# Output:
Applying: Color=white, Brightness=50% (Hex: 00), Animation=off
```
---

## HTTP API Server (`server.py`)
To integrate this controller with web GUIs, external automations, or AI agents (like Open WebUI running in Docker), you can run the included FastAPI server to control the LEDs via standard HTTP POST requests.

**Requirements:**
```sh
pip install fastapi uvicorn pydantic
```

**Running the server:**
```sh
python3 server.py
```
The API will be available on your local network at `http://0.0.0.0:8314`. You can view the auto-generated documentation by visiting `http://localhost:8314/docs`.

**Example API Request:**
```sh
curl -X POST "http://localhost:8314/api/rgb" \
     -H "Content-Type: application/json" \
     -d '{"zone": "all", "color": "cyan", "brightness": 100, "mode": "breathe1"}'
```
---

## Available (tested) LED colors
- red
- green
- blue
- yellow
- cyan
- purple
- white

> [!NOTE]
> You can also use hex color notation, but for now, it will only fall back
> to the closest color from the list above

## Available animation types
- static
- breathe2
- breathe3
- breathe4

---

> [!WARNING]
> This software is NOT affiliated or endorsed by Machenike in any way.
> This is a piece of code that solved a problem for me.

> [!IMPORTANT]
> This software was written with the help of AI

