from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Literal
import subprocess
import uvicorn

app = FastAPI(title="Machenike RGB API")

# Strict data validation to prevent command injection
class LEDRequest(BaseModel):
    zone: Literal["top", "power", "all"] = Field(..., description="Target LED zone")
    color: str = Field(..., description="Color name or hex code")
    brightness: int = Field(..., ge=0, le=100, description="Brightness percentage")
    mode: Literal["static", "breathe1", "breathe2", "breathe3", "off"] = Field(..., description="Animation mode")

@app.post("/api/rgb")
def update_leds(req: LEDRequest):
    command = [
        "sudo", "/usr/local/bin/machenike_rgb",
        "--zone", req.zone,
        "--color", req.color,
        "--brightness", str(req.brightness),
        "--mode", req.mode
    ]
    
    try:
        # Execute the script
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return {"status": "success", "message": result.stdout.strip()}
    except subprocess.CalledProcessError as e:
        # If the bash script fails, return a 500 error with the stderr
        raise HTTPException(status_code=500, detail=e.stderr.strip())

if __name__ == "__main__":
    # 0.0.0.0 exposes the API to your local network
    uvicorn.run(app, host="0.0.0.0", port=8314)

