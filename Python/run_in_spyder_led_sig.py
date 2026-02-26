# -*- coding: utf-8 -*-
"""
Created on Tue Feb 24 14:27:59 2026

@author: inayas1
"""

# %% Setup
import sys
import os

# IMPORTANT: adjust to your local repo root
PROJECT_ROOT = r"E:\Data\UNLV\AIR_Wheel_Methods\Python"

if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# %% Imports
from src.utils.extract_led_signal import run_led_roi_selection
import pickle

# %% Load airwheel_data
with open("airwheel_data.pkl", "rb") as f:
    airwheel_data = pickle.load(f)

# %% Run ROI selection
run_led_roi_selection(airwheel_data, overwrite=False)