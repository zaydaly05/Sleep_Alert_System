import cv2
import imutils
import numpy as np
import winsound
from fastapi import FastAPI
import threading

# ==============================
# CONSTANTS
# ==============================
EYE_FAIL_CONSEC_FRAMES = 15

# ==============================
# FASTAPI APP
# ==============================
app = FastAPI()

# ==============================
# LOAD CASCADES
# ==============================
face_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)
eye_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_eye.xml"
)

# ==============================
# GLOBAL STATE
# ==============================
cap = None
running = False
counter = 0

current_status = {
    "face_detected": False,
    "pupil_detected": False,
    "status": "STOPPED"
}

# ==============================
# ALARM
# ==============================
def play_alarm():
    try:
        winsound.Beep(800, 200)
    except:
        pass

# ==============================
# HELPER FUNCTION
# ==============================
def open_camera():
    """Try to open camera with DirectShow backend (Windows)"""
    for i in range(5):
        cap_temp = cv2.VideoCapture(i, cv2.CAP_DSHOW)
        if cap_temp.isOpened():
            ret, frame = cap_temp.read()
            if ret:
                print(f"✅ Camera opened at index {i}")
                return cap_temp
            cap_temp.release()
    return None

# ==============================
# DETECTION LOOP
# ==============================
def detect_loop():
    global cap, running, counter, current_status

    # Open camera when monitoring starts
    cap = open_camera()
    
    if cap is None or not cap.isOpened():
        print("[ERROR] Camera not accessible")
        running = False
        current_status["status"] = "CAMERA_ERROR"
        return

    print("[INFO] Camera started")

    while running:
        ret, frame = cap.read()
        if not ret:
            break

        frame = imutils.resize(frame, width=600)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # ==============================
        # FACE DETECTION (IMPROVED)
        # ==============================
        faces = face_cascade.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=3,
            minSize=(60, 60)
        )

        face_visible = len(faces) > 0
        pupil_detected = False

        for (x, y, w, h) in faces:
            # Draw face rectangle (DEBUG)
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

            roi_gray = gray[y:y + h // 2, x:x + w]
            roi_color = frame[y:y + h // 2, x:x + w]

            eyes = eye_cascade.detectMultiScale(
                roi_gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(30, 30)
            )

            for (ex, ey, ew, eh) in eyes:
                # Draw eye rectangle (DEBUG)
                cv2.rectangle(
                    roi_color,
                    (ex, ey),
                    (ex + ew, ey + eh),
                    (255, 0, 0),
                    2
                )

                eye_roi = roi_color[ey:ey + eh, ex:ex + ew]
                gray_eye = cv2.cvtColor(eye_roi, cv2.COLOR_BGR2GRAY)
                gray_eye = cv2.GaussianBlur(gray_eye, (5, 5), 0)

                _, th = cv2.threshold(
                    gray_eye, 40, 255, cv2.THRESH_BINARY_INV
                )

                contours, _ = cv2.findContours(
                    th, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
                )

                if contours:
                    pupil_detected = True
                    break

        # ==============================
        # LOGIC
        # ==============================
        if face_visible and not pupil_detected:
            counter += 1
            if counter >= EYE_FAIL_CONSEC_FRAMES:
                current_status["status"] = "SLEEPING"
                play_alarm()
            else:
                current_status["status"] = "DROWSY"
        else:
            counter = 0
            if face_visible:
                current_status["status"] = "AWAKE"
            else:
                current_status["status"] = "NO_FACE"

        current_status["face_detected"] = face_visible
        current_status["pupil_detected"] = pupil_detected

        # ==============================
        # DEBUG CAMERA WINDOW
        # ==============================
        cv2.imshow("Sleep Detection Camera", frame)
        if cv2.waitKey(1) & 0xFF == 27:  # ESC key
            break

    cap.release()
    cv2.destroyAllWindows()
    running = False
    current_status["status"] = "STOPPED"
    print("[INFO] Camera stopped")

# ==============================
# API ENDPOINTS
# ==============================
@app.post("/start")
def start_detection():
    global running
    if not running:
        running = True
        threading.Thread(target=detect_loop, daemon=True).start()
    return {"message": "Detection started"}

@app.post("/stop")
def stop_detection():
    global running
    running = False
    return {"message": "Detection stopped"}

@app.get("/status")
def get_status():
    return current_status
