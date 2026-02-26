# -*- coding: utf-8 -*-
"""
Created on Tue Feb 24 14:23:19 2026

@author: inayas1
"""

import cv2
import os
import json


# =====================================================
# ROI SELECTION CORE
# =====================================================
def select_led_rois(video_path, overwrite=False):
    """
    Interactive ROI selection for LED and background.
    Must be run on LOCAL machine with GUI.
    """

    root, _ = os.path.splitext(video_path)
    roi_json_path = f"{root}_ledroi.json"

    # ---------------------------------------------
    # Skip if exists
    # ---------------------------------------------
    if os.path.exists(roi_json_path) and not overwrite:
        print(f"[SKIP] ROI exists: {roi_json_path}")
        return

    print(f"\n[ROI] Processing: {video_path}")

    cap = cv2.VideoCapture(video_path)
    ret, frame = cap.read()
    cap.release()

    if not ret:
        print(f"[ERROR] Cannot read video: {video_path}")
        return

    # -------------------------------------------------
    # LED ROI
    # -------------------------------------------------
    print("\nDraw LED ROI → press ENTER when done")
    led_roi = cv2.selectROI("LED ROI", frame, fromCenter=False)
    cv2.destroyAllWindows()

    if led_roi[2] == 0 or led_roi[3] == 0:
        print("[WARNING] LED ROI skipped")
        return

    # -------------------------------------------------
    # Background ROI
    # -------------------------------------------------
    print("\nDraw BACKGROUND ROI → press ENTER when done")
    bg_roi = cv2.selectROI("Background ROI", frame, fromCenter=False)
    cv2.destroyAllWindows()

    if bg_roi[2] == 0 or bg_roi[3] == 0:
        print("[WARNING] Background ROI skipped")
        return

    # -------------------------------------------------
    # Save JSON
    # -------------------------------------------------
    roi_info = {
        "video_path": video_path,
        "led_roi": {
            "x": int(led_roi[0]),
            "y": int(led_roi[1]),
            "w": int(led_roi[2]),
            "h": int(led_roi[3]),
        },
        "bg_roi": {
            "x": int(bg_roi[0]),
            "y": int(bg_roi[1]),
            "w": int(bg_roi[2]),
            "h": int(bg_roi[3]),
        },
    }

    with open(roi_json_path, "w") as f:
        json.dump(roi_info, f, indent=4)

    print(f"[SAVED] {roi_json_path}")


# =====================================================
# BATCH DRIVER
# =====================================================
def run_led_roi_selection(airwheel_data, targets=None, overwrite=False):
    """
    Batch ROI selection across animals.
    Designed for Spyder local execution.
    """

    if targets is None:
        targets = ["face", "pupil", "paws"]

    print("\n=== LED ROI SELECTION ===")

    for entry in airwheel_data:

        animal_id = entry["ID"]
        date = entry["date"]

        print(f"\n--- {animal_id} | {date} ---")

        mp4_files = entry["video"]["mp4"]

        for key in targets:

            video_path = mp4_files.get(key)

            if not video_path:
                continue

            if not os.path.exists(video_path):
                print(f"[MISSING] {video_path}")
                continue

            select_led_rois(video_path, overwrite=overwrite)