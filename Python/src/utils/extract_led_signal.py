import cv2
import os
import json
import matplotlib.pyplot as plt
from matplotlib.widgets import RectangleSelector


# =========================================================
# ----------- MATPLOTLIB ROI SELECTOR ---------------------
# =========================================================

class ROISelector:
    def __init__(self, image, title="Draw ROI"):
        self.image = image
        self.roi = None

        self.fig, self.ax = plt.subplots()
        self.ax.imshow(image, cmap='gray')
        self.ax.set_title(title)

        self.selector = RectangleSelector(
            self.ax,
            self.onselect,
            useblit=True,
            button=[1],
            interactive=True
        )

        plt.connect('key_press_event', self.on_key)
        plt.show()

    def onselect(self, eclick, erelease):
        x1, y1 = int(eclick.xdata), int(eclick.ydata)
        x2, y2 = int(erelease.xdata), int(erelease.ydata)

        self.roi = (
            min(x1, x2),
            min(y1, y2),
            abs(x2 - x1),
            abs(y2 - y1),
        )

    def on_key(self, event):
        if event.key == 'enter':
            plt.close(self.fig)


# =========================================================
# ---------------- MAIN FUNCTION --------------------------
# =========================================================

def select_led_rois(video_path, save_json=True):
    """
    Interactive LED + background ROI selector.

    Works over SSH using matplotlib.

    Returns ROI dict.
    """

    if not os.path.exists(video_path):
        raise FileNotFoundError(video_path)

    print(f"[INFO] Opening video: {video_path}")

    cap = cv2.VideoCapture(video_path)
    ret, frame = cap.read()
    cap.release()

    if not ret:
        raise RuntimeError("Could not read first frame.")

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # -----------------------------------------------------
    print("\nDraw LED ROI → press ENTER when done")
    led_selector = ROISelector(gray, "Draw LED ROI (press ENTER)")
    led_roi = led_selector.roi

    if led_roi is None:
        raise RuntimeError("LED ROI not selected")

    # -----------------------------------------------------
    print("\nDraw BACKGROUND ROI → press ENTER when done")
    bg_selector = ROISelector(gray, "Draw Background ROI (press ENTER)")
    bg_roi = bg_selector.roi

    if bg_roi is None:
        raise RuntimeError("Background ROI not selected")

    roi_info = {
        "video_path": video_path,
        "led_roi": dict(zip(["x","y","w","h"], led_roi)),
        "bg_roi": dict(zip(["x","y","w","h"], bg_roi)),
    }

    # -----------------------------------------------------
    if save_json:
        root, _ = os.path.splitext(video_path)
        json_path = f"{root}_led_roi.json"

        with open(json_path, "w") as f:
            json.dump(roi_info, f, indent=4)

        print(f"[SAVED] {json_path}")

    return roi_info


def run_led_roi_selection(airwheel_data, targets=("face","pupil","paws"), overwrite=False):
    """
    Iterate through airwheel_data and launch ROI selector.
    """

    for entry in airwheel_data:
        animal = entry["ID"]
        date = entry["date"]

        print(f"\n==============================")
        print(f"Processing {animal} | {date}")
        print(f"==============================")

        mp4s = entry["video"]["mp4"]

        for key in targets:
            video_path = mp4s.get(key)

            if not video_path:
                continue

            if not os.path.exists(video_path):
                print(f"[MISSING] {video_path}")
                continue

            select_led_rois(video_path)