import cv2
import os
import numpy as np
from keras_facenet import FaceNet
from sklearn.neighbors import KNeighborsClassifier
import pickle
from datetime import datetime
import csv

# Initialize FaceNet embedder
embedder = FaceNet()

# Function to preprocess images
def preprocess_image(image_path):
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Image not found: {image_path}")
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    return img

# Function to load dataset and extract embeddings
def load_dataset(dataset_path):
    X, y = [], []
    for person_name in os.listdir(dataset_path):
        person_dir = os.path.join(dataset_path, person_name)
        if os.path.isdir(person_dir):
            for image_name in os.listdir(person_dir):
                image_path = os.path.join(person_dir, image_name)
                try:
                    img = preprocess_image(image_path)
                    embedding = embedder.embeddings([img])[0]
                    X.append(embedding)
                    y.append(person_name)
                except ValueError as e:
                    print(e)
    return np.array(X), np.array(y)

# Function to train KNN classifier
def train_knn_classifier(X, y, n_neighbors=1):
    knn = KNeighborsClassifier(n_neighbors=n_neighbors, metric='euclidean')
    knn.fit(X, y)
    return knn

# Save and load model
def save_model(model, filename='knn_model.pkl'):
    with open(filename, 'wb') as file:
        pickle.dump(model, file)

def load_model(filename='knn_model.pkl'):
    with open(filename, 'rb') as file:
        return pickle.load(file)

# Save attendance to CSV
def log_attendance(name, direction):
    filename = "attendance.csv"
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    file_exists = os.path.isfile(filename)

    with open(filename, mode='a', newline='') as file:
        writer = csv.writer(file)
        if not file_exists:
            writer.writerow(["Name", "Direction", "Timestamp"])
        writer.writerow([name, direction, now])
    print(f"[LOG] {name} {direction} at {now}")

# Real-time face recognition with line-based entry/exit detection
def live_face_recognition(knn):
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return

    print("Press 'q' to quit.")
    person_positions = {}  # {name: previous_side}

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame.")
            break

        height, width = frame.shape[:2]
        line_x = width // 2  # vertical line in center
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Detect faces
        faces = embedder.extract(rgb_frame, threshold=0.95)

        # Draw the line
        cv2.line(frame, (line_x, 0), (line_x, height), (0, 0, 255), 2)

        for face in faces:
            box = face['box']
            embedding = face['embedding']
            name = knn.predict([embedding])[0]

            x, y, w, h = box
            center_x = x + w // 2
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
            cv2.putText(frame, name, (x, y - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)

            # Determine current side (left or right)
            current_side = "left" if center_x < line_x else "right"

            if name in person_positions:
                previous_side = person_positions[name]
                if previous_side != current_side:
                    # Person crossed the line → mark attendance
                    direction = "entered" if current_side == "right" else "exited"
                    log_attendance(name, direction)
                    person_positions[name] = current_side
            else:
                person_positions[name] = current_side

        cv2.imshow("Doorway Face Recognition", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()


# Main execution flow
if __name__ == "__main__":
    dataset_path = 'dataset'
    model_filename = 'knn_model_new_face.pkl'

    if os.path.exists(model_filename):
        knn = load_model(model_filename)
        print("Model loaded from disk.")
    else:
        X, y = load_dataset(dataset_path)
        knn = train_knn_classifier(X, y)
        save_model(knn, model_filename)
        print("Model trained and saved to disk.")

    live_face_recognition(knn)
