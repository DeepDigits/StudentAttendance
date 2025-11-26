import cv2
import os
import numpy as np
from keras_facenet import FaceNet
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Initialize FaceNet embedder
embedder = FaceNet()

# Function to capture and save face images
def capture_faces(name, num_images=50):
    cap = cv2.VideoCapture(0)
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    count = 0

    person_dir = os.path.join("dataset", name)
    os.makedirs(person_dir, exist_ok=True)

    while count < num_images:
        ret, frame = cap.read()
        if not ret:
            break

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)

        for (x, y, w, h) in faces:
            face = frame[y:y+h, x:x+w]
            count += 1
            cv2.imwrite(os.path.join(person_dir, f"{name}_{count}.jpg"), face)
            cv2.rectangle(frame, (x, y), (x+w, y+h), (255, 0, 0), 2)
            if count >= num_images:
                break

        cv2.imshow("Capture Face", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

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

# Function to recognize faces in real-time
def recognize_faces(knn):
    cap = cv2.VideoCapture(0)
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        faces = embedder.extract(rgb_frame, threshold=0.95)
        for face in faces:
            embedding = face['embedding']
            name = knn.predict([embedding])[0]
            (x, y, w, h) = face['box']
            cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
            cv2.putText(frame, name, (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)
        cv2.imshow("Face Recognition", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

# Main execution flow
if __name__ == "__main__":
    dataset_path = 'dataset'
    os.makedirs(dataset_path, exist_ok=True)

    # Capture faces for a new user
    name = input("Enter your name: ")
    capture_faces(name)

    # Load dataset and extract embeddings
    X, y = load_dataset(dataset_path)

    # Train KNN classifier
    knn = train_knn_classifier(X, y)

    # Evaluate the classifier
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    y_pred = knn.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Model accuracy: {accuracy * 100:.2f}%")

    # Perform real-time face recognition
    recognize_faces(knn)
