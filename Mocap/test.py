import cv2
import mediapipe as mp
import socket
import json
from time import sleep

# UDP Setup
SERVER_IP = "127.0.0.1"  # Change if needed
SERVER_PORT = 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Load MediaPipe Hands and Gesture Recognizer
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5)
mp_handedness = mp.solutions.holistic  # Used to check if left or right hand

# Start webcam
cap = cv2.VideoCapture(0)

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        print("Failed to grab frame. Exiting...")
        break

    # Convert BGR to RGB (Required for MediaPipe)
    image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    image.flags.writeable = False
    results = hands.process(image)
    image.flags.writeable = True
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    hand_data = []  # Store keypoint data

    if results.multi_hand_landmarks:
        for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
            mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

            h, w, _ = image.shape
            keypoints = {}

            # Extract only landmarks 8 and 7
            for i in [8, 7]:
                landmark = hand_landmarks.landmark[i]
                keypoints[str(i)] = {
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z
                }

            # Determine if the hand is left or right
            handedness = results.multi_handedness[idx].classification[0].label
            keypoints["isleft"] = handedness == "Left"  # True if left, False if right

            hand_data.append(keypoints)

    # Send hand tracking data as JSON over UDP
    if hand_data:
        json_data = json.dumps({"hands": hand_data})
        sock.sendto(json_data.encode(), (SERVER_IP, SERVER_PORT))
        # print("Sent:", json_data)
    sleep(1/20)
    # Display output
    # cv2.imshow('Hand Recognition', image)

    # Exit on 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
