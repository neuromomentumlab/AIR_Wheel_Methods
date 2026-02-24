import cv2
import os

def save_first_frame(video_path, overwrite=False):
    """
    Extract and save first frame next to video.
    Headless-safe.
    """

    if not os.path.exists(video_path):
        print(f"[MISSING] {video_path}")
        return

    root, _ = os.path.splitext(video_path)
    out_png = f"{root}_firstframe.png"

    if os.path.exists(out_png) and not overwrite:
        return

    cap = cv2.VideoCapture(video_path)
    ret, frame = cap.read()
    cap.release()

    if not ret:
        print(f"[ERROR] Could not read {video_path}")
        return

    cv2.imwrite(out_png, frame)
    print(f"[SAVED] {out_png}")


def extract_first_frames_airwheel(airwheel_data, overwrite=False):

    targets = ["face", "pupil", "paws"]

    for entry in airwheel_data:
        mp4s = entry["video"]["mp4"]

        for key in targets:
            video_path = mp4s.get(key)
            if video_path:
                save_first_frame(video_path, overwrite)