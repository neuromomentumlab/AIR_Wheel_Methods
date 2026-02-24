import cv2
import os
import json
import csv
import numpy as np
from pathlib import Path
from tqdm.auto import tqdm  # ← notebook friendly


# ============================================================
# ROI LOADER
# ============================================================

def load_roi_with_fallback(local_roi_path, video_path):
    """
    Load ROI JSON.
    If missing locally, fall back to reference animal.
    """

    # ---------- CASE 1: local exists ----------
    if os.path.exists(local_roi_path):
        with open(local_roi_path, 'r') as f:
            return json.load(f)

    print(f"[INFO] Local ROI missing. Using reference ROI.")

    fname = os.path.basename(video_path).lower()

    # ---------- Detect modality ----------
    if fname.startswith("face"):
        cam = "face"
    elif fname.startswith("pupi"):
        cam = "pupi"
    elif fname.startswith("video"):
        cam = "video"
    else:
        print(f"[WARNING] Could not determine camera type for {video_path}")
        return None

    # ---------- Detect reduced ----------
    is_reduced = "_reduced" in fname

    # ---------- Build reference path ----------
    ref_base = Path(video_path).parents[3]
    ref_dir = ref_base / "Air_Wheel_Methods" / "NML_GC_01" / "2025_12_16"

    if cam == "face":
        ref_name = (
            "face_1440x1080_60_20251216_165824_reduced_roi.json"
            if is_reduced
            else "face_1440x1080_60_20251216_165824_roi.json"
        )
    elif cam == "pupi":
        ref_name = "pupi_320x240_60_20251216_165824_roi.json"
    elif cam == "video":
        ref_name = (
            "video_20251216_165824_reduced_roi.json"
            if is_reduced
            else "video_20251216_165824_roi.json"
        )

    ref_roi_path = ref_dir / ref_name

    if not ref_roi_path.exists():
        print(f"[ERROR] Reference ROI not found: {ref_roi_path}")
        return None

    print(f"[INFO] Using reference ROI: {ref_roi_path}")

    with open(ref_roi_path, 'r') as f:
        return json.load(f)


# ============================================================
# MAIN ANALYSIS
# ============================================================

def run_comprehensive_motion_analysis(
    data_list,
    roi_exist=True,
    force_cpu=False,
    verbose=True,
):
    """
    Main AIR Wheel optical flow pipeline.

    Parameters
    ----------
    data_list : list
    roi_exist : bool
    force_cpu : bool
        If True, disables GPU even if available
    verbose : bool
    """

    # --------------------------------------------------------
    # GPU CHECK
    # --------------------------------------------------------
    gpu_available = cv2.cuda.getCudaEnabledDeviceCount() > 0
    use_gpu = gpu_available and not force_cpu

    if verbose:
        print(f"[INFO] GPU available: {gpu_available}")
        print(f"[INFO] Using GPU: {use_gpu}")

    if use_gpu:
        tvl1_gpu = cv2.cuda_OpticalFlowDual_TVL1.create()
        gpu_prev = cv2.cuda_GpuMat()
        gpu_curr = cv2.cuda_GpuMat()
    else:
        tvl1_cpu = cv2.optflow.DualTVL1OpticalFlow_create()

    targets = ['face', 'paws', 'pupil']
    analysis_queue = []

    # ========================================================
    # PHASE 1: BUILD QUEUE
    # ========================================================
    if verbose:
        print("\n--- PHASE 1: SELECT ROIs FOR ALL VIDEOS ---")

    for entry in data_list:
        mp4_files = entry['video']['mp4']

        for key in targets:
            original_path = mp4_files.get(key)
            if not original_path:
                continue

            # ---------- reduced handling ----------
            if key in ['face', 'paws']:
                root, ext = os.path.splitext(original_path)
                video_path = f"{root}_reduced{ext}"
                if not os.path.exists(video_path):
                    video_path = original_path
            else:
                video_path = original_path

            if not os.path.exists(video_path):
                continue

            # ---------- load first frame ----------
            cap = cv2.VideoCapture(video_path)
            ret, first_frame = cap.read()
            cap.release()
            if not ret:
                continue

            root, _ = os.path.splitext(video_path)
            roi_json_path = f"{root}_roi.json"

            # ---------- ROI ----------
            if not roi_exist:
                win_name = f"SELECT ROI: {key} ({os.path.basename(video_path)})"
                roi = cv2.selectROI(win_name, first_frame, fromCenter=False)
                cv2.destroyWindow(win_name)

                x, y, w, h = [int(v) for v in roi]

                if w > 0 and h > 0:
                    roi_info = {"x": x, "y": y, "w": w, "h": h, "source": video_path}
                    with open(roi_json_path, 'w') as f:
                        json.dump(roi_info, f, indent=4)
            else:
                roi_info = load_roi_with_fallback(roi_json_path, video_path)
                if roi_info is None:
                    continue

                x = int(roi_info["x"])
                y = int(roi_info["y"])
                w = int(roi_info["w"])
                h = int(roi_info["h"])

            analysis_queue.append({
                'key': key,
                'path': video_path,
                'roi': (x, y, w, h),
                'output': f"{root}_OF.csv"
            })
    
    # ========================================================
    # PHASE 2: PROCESS
    # ========================================================
    if verbose:
        print(f"\n--- PHASE 2: PROCESSING {len(analysis_queue)} ANALYSES ---")

    for task in analysis_queue:
        # print(task["output"])
        # continue
        video_path = task['path']
        x, y, w, h = task['roi']

        cap = cv2.VideoCapture(video_path)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        # import matplotlib.pyplot as plt

        # # --- QC: show first frame with ROI ---
        # ret_qc, frame_qc = cap.read()
        # if not ret_qc:
        #     print(f"[WARNING] Could not read first frame: {video_path}")
        #     cap.release()
        #     continue

        # qc_frame = frame_qc.copy()
        # cv2.rectangle(qc_frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

        # # convert BGR → RGB for matplotlib
        # qc_rgb = cv2.cvtColor(qc_frame, cv2.COLOR_BGR2RGB)

        # plt.figure(figsize=(5,4))
        # plt.imshow(qc_rgb)
        # plt.title(f"QC ROI — {task['key']}")
        # plt.axis("off")
        # plt.show()

        # # reset video to frame 0
        # cap.set(cv2.CAP_PROP_POS_FRAMES, 0)

        # continue

        ret, prev_frame = cap.read()
        if not ret:
            cap.release()
            continue

        prev_gray = cv2.cvtColor(prev_frame[y:y+h, x:x+w], cv2.COLOR_BGR2GRAY)

        with open(task['output'], mode='w', newline='') as csv_file:
            writer = csv.writer(csv_file)
            writer.writerow(['frame_number', 'time_ms', 'avg_u', 'avg_v', 'motion_energy'])

            pbar = tqdm(total=total_frames,
                        desc=f"Analyzing {task['key']}",
                        unit="fr",
                        leave=True)

            pbar.update(1)
            frame_count = 1

            while True:
                ret, frame = cap.read()
                if not ret:
                    break

                timestamp = cap.get(cv2.CAP_PROP_POS_MSEC)
                curr_gray = cv2.cvtColor(frame[y:y+h, x:x+w], cv2.COLOR_BGR2GRAY)

                # ---------- GPU ----------
                if use_gpu:
                    gpu_prev.upload(prev_gray)
                    gpu_curr.upload(curr_gray)
                    flow_gpu = tvl1_gpu.calc(gpu_prev, gpu_curr, None)
                    flow = flow_gpu.download()
                else:
                    flow = tvl1_cpu.calc(prev_gray, curr_gray, None)

                avg_u = np.mean(flow[..., 0])
                avg_v = np.mean(flow[..., 1])
                motion_energy = np.mean(cv2.absdiff(curr_gray, prev_gray))

                writer.writerow([
                    frame_count,
                    round(timestamp, 2),
                    avg_u,
                    avg_v,
                    motion_energy
                ])

                prev_gray = curr_gray
                frame_count += 1
                pbar.update(1)

            pbar.close()

        cap.release()