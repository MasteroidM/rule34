import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf

# Load MediaPipe Hands
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# Load EfficientDet-Lite0 TFLite Model
MODEL_PATH = "model\efficientdet_lite0 (f16).tflite"

try:
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()

    # Get input/output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    input_shape = input_details[0]['shape']  # Expected shape (1, 320, 320, 3)
    print("Model expects input shape:", input_shape)

except Exception as e:
    print("Error loading TFLite model:", e)
    exit()

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

    # Draw hand landmarks if detected
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

            # Extract bounding box
            h, w, _ = image.shape
            x_min, y_min, x_max, y_max = w, h, 0, 0

            for landmark in hand_landmarks.landmark:
                x, y = int(landmark.x * w), int(landmark.y * h)
                x_min, y_min = min(x, x_min), min(y, y_min)
                x_max, y_max = max(x, x_max), max(y, y_max)

            # Ensure valid bounding box
            if x_max - x_min > 10 and y_max - y_min > 10:
                # Validate hand_crop before resizing
                if 0 <= x_min < w and 0 <= x_max < w and 0 <= y_min < h and 0 <= y_max < h:
                    hand_crop = image[y_min:y_max, x_min:x_max]

                    if hand_crop.shape[0] > 0 and hand_crop.shape[1] > 0:  # Ensure it's not empty
                        hand_crop = cv2.resize(hand_crop, (320, 320))  # Resize correctly
                        hand_crop = np.expand_dims(hand_crop, axis=0).astype(np.float32) / 255.0  # Normalize

                        # Run TFLite Inference
                        interpreter.set_tensor(input_details[0]['index'], hand_crop)
                        interpreter.invoke()
                        detections = interpreter.get_tensor(output_details[0]['index'])

                        print("EfficientDet Output:", detections)
                    else:
                        print("Warning: Empty hand_crop detected, skipping processing.")
                else:
                    print("Warning: Hand bounding box out of bounds.")

    # Display output
    cv2.imshow('Hand Recognition', image)

    # Exit on 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
