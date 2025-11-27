from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse, JSONResponse
import tempfile
import subprocess
import os

app = FastAPI()

@app.get("/")
def root():
    return {"status": "ok", "message": "Reels branding FFmpeg API"}

@app.post("/brand")
async def brand_video(
    video: UploadFile = File(...),
    logo: UploadFile = File(...),
    brandtext: str = Form("@MyBrand")
):
    # For now we only overlay logo (no text) to make debugging easier
    with tempfile.TemporaryDirectory() as tmpdir:
        video_path = os.path.join(tmpdir, "video.mp4")
        logo_path = os.path.join(tmpdir, "logo.png")
        output_path = os.path.join(tmpdir, "output.mp4")

        # Save uploaded files
        with open(video_path, "wb") as f:
            f.write(await video.read())

        with open(logo_path, "wb") as f:
            f.write(await logo.read())

        # Very simple ffmpeg command: just overlay logo at top-right
        cmd = [
            "ffmpeg", "-y",
            "-i", video_path,
            "-i", logo_path,
            "-filter_complex", "[0:v][1:v] overlay=W-w-30:30",
            "-preset", "fast",
            "-vcodec", "libx264",
            "-crf", "23",
            "-acodec", "copy",
            output_path
        ]

        try:
            proc = subprocess.run(
                cmd,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
        except subprocess.CalledProcessError as e:
            # Return full ffmpeg stderr so we can see exact error from PHP
            return JSONResponse(
                status_code=500,
                content={
                    "error": "ffmpeg_failed",
                    "stderr": e.stderr.decode("utf-8", errors="ignore")
                }
            )

        return FileResponse(
            output_path,
            media_type="video/mp4",
            filename="branded_reel.mp4"
        )
