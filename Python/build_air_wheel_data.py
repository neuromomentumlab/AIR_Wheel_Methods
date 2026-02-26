# -*- coding: utf-8 -*-
"""
Created on Tue Feb 24 14:30:28 2026

@author: inayas1
"""

import os
import pickle
from pathlib import Path


# =====================================================
# Detect camera type from filename
# =====================================================
def _detect_camera_type(fname: str):
    fname = fname.lower()

    if fname.startswith("face"):
        return "face"
    elif fname.startswith("pupi"):
        return "pupil"
    elif fname.startswith("video"):
        return "paws"
    else:
        return None


# =====================================================
# Main builder
# =====================================================
def build_airwheel_data(pdata_root):
    """
    Scan PData directory and build airwheel_data structure.
    """

    pdata_root = Path(pdata_root)

    if not pdata_root.exists():
        raise FileNotFoundError(f"PData not found: {pdata_root}")

    airwheel_data = []

    print("\n=== Scanning PData ===")

    # -------------------------------------------------
    # Loop animals (NML_XX)
    # -------------------------------------------------
    for animal_dir in sorted(pdata_root.glob("NML_*")):

        if not animal_dir.is_dir():
            continue

        animal_id = animal_dir.name

        # ---------------------------------------------
        # Loop dates
        # ---------------------------------------------
        for date_dir in sorted(animal_dir.glob("20*")):

            if not date_dir.is_dir():
                continue

            date_str = date_dir.name

            mp4_dict = {
                "face": None,
                "pupil": None,
                "paws": None,
            }

            # -----------------------------------------
            # Find mp4 files
            # -----------------------------------------
            for mp4_file in date_dir.glob("*.mp4"):

                cam_type = _detect_camera_type(mp4_file.name)

                if cam_type is not None:
                    mp4_dict[cam_type] = str(mp4_file)

            # Skip empty sessions
            if all(v is None for v in mp4_dict.values()):
                continue

            entry = {
                "ID": animal_id,
                "date": date_str,
                "session_dir": str(date_dir),
                "video": {"mp4": mp4_dict},
                "roi_reference": {
                    "animal": "NML_GC_01",
                    "date": "2025_12_16",
                },
            }

            airwheel_data.append(entry)

            print(f"[OK] {animal_id} | {date_str}")

    print(f"\nTotal sessions found: {len(airwheel_data)}")

    return airwheel_data


# =====================================================
# Convenience saver
# =====================================================
def build_and_save_airwheel_data(pdata_root, output_pickle):
    data = build_airwheel_data(pdata_root)

    with open(output_pickle, "wb") as f:
        pickle.dump(data, f)

    print(f"\n[SAVED] {output_pickle}")

    return data