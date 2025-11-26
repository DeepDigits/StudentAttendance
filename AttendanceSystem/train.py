"""
Enhanced Face Recognition Training Module for Web Integration
Trains a KNN classifier on face embeddings using FaceNet
"""

import cv2
import os
import numpy as np
import pickle
from pathlib import Path
from typing import Tuple, List, Dict


class FaceRecognitionTrainer:
	"""Train face recognition models for attendance system."""
	
	def __init__(self, dataset_base_path: str = 'dataset', model_base_path: str = 'models'):
		"""
		Initialize the trainer.
		
		Args:
			dataset_base_path: Base directory for student face datasets
			model_base_path: Base directory for trained models
		"""
		self.dataset_base_path = dataset_base_path
		self.model_base_path = model_base_path
		os.makedirs(self.dataset_base_path, exist_ok=True)
		os.makedirs(self.model_base_path, exist_ok=True)
		
		# Import FaceNet embedder
		try:
			from keras_facenet import FaceNet
			self.embedder = FaceNet()
		except ImportError:
			print("ERROR: keras_facenet not installed. Install with: pip install keras-facenet")
			raise
	
	def preprocess_image(self, image_path: str) -> np.ndarray:
		"""
		Load and preprocess an image for embedding extraction.
		
		Args:
			image_path: Path to the image file
			
		Returns:
			RGB image as numpy array
			
		Raises:
			ValueError: If image cannot be loaded
		"""
		img = cv2.imread(image_path)
		if img is None:
			raise ValueError(f"Could not load image: {image_path}")
		
		# Apply lighting normalization
		img_normalized = cv2.normalize(img, None, 0, 255, cv2.NORM_MINMAX)
		
		# Convert BGR to RGB
		img_rgb = cv2.cvtColor(img_normalized, cv2.COLOR_BGR2RGB)
		return img_rgb
	
	def load_dataset(self, student_id: str) -> Tuple[np.ndarray, np.ndarray]:
		"""
		Load all face images for a student and extract embeddings.
		
		Args:
			student_id: Student identifier (e.g., REG001)
			
		Returns:
			Tuple of (embeddings array, labels array)
			
		Raises:
			ValueError: If no valid images found
		"""
		student_dir = os.path.join(self.dataset_base_path, student_id)
		
		if not os.path.exists(student_dir):
			raise ValueError(f"Dataset directory not found: {student_dir}")
		
		embeddings = []
		labels = []
		
		image_files = sorted([
			f for f in os.listdir(student_dir) 
			if f.lower().endswith(('.jpg', '.jpeg', '.png'))
		])
		
		if not image_files:
			raise ValueError(f"No images found in {student_dir}")
		
		print(f"Loading {len(image_files)} images for {student_id}...")
		
		for image_name in image_files:
			image_path = os.path.join(student_dir, image_name)
			try:
				img = self.preprocess_image(image_path)
				
				# Extract embedding using FaceNet
				embedding = self.embedder.embeddings([img])[0]
				embeddings.append(embedding)
				labels.append(student_id)
				
				print(f"  ✓ Processed {image_name}")
				
			except Exception as e:
				print(f"  ✗ Error processing {image_name}: {str(e)}")
				continue
		
		if len(embeddings) < 5:
			raise ValueError(
				f"Insufficient valid images: {len(embeddings)} processed, "
				f"need at least 5 for training"
			)
		
		print(f"Successfully loaded {len(embeddings)} embeddings\n")
		return np.array(embeddings), np.array(labels)
	
	def train_knn_classifier(self, embeddings: np.ndarray, labels: np.ndarray, n_neighbors: int = 3):
		"""
		Train a KNN classifier on face embeddings.
		
		Args:
			embeddings: Array of face embeddings
			labels: Array of corresponding student IDs
			n_neighbors: Number of neighbors for KNN
			
		Returns:
			Trained KNN classifier
		"""
		from sklearn.neighbors import KNeighborsClassifier
		
		# Adjust n_neighbors if necessary
		n_neighbors = min(n_neighbors, len(embeddings))
		
		print(f"Training KNN classifier with {n_neighbors} neighbors...")
		print(f"  - Embeddings: {embeddings.shape}")
		print(f"  - Samples: {len(labels)}\n")
		
		knn = KNeighborsClassifier(n_neighbors=n_neighbors, metric='euclidean')
		knn.fit(embeddings, labels)
		
		print("✓ KNN classifier trained successfully\n")
		return knn
	
	def train_student(self, student_id: str) -> Dict[str, any]:
		"""
		Complete training pipeline for a student.
		
		Args:
			student_id: Student identifier (e.g., REG001)
			
		Returns:
			Dictionary with training results
		"""
		try:
			# Validate student ID format
			if not isinstance(student_id, str) or len(student_id) < 4:
				raise ValueError("Invalid student ID format")
			
			print("=" * 60)
			print(f"STARTING TRAINING FOR: {student_id}")
			print("=" * 60 + "\n")
			
			# Load dataset
			print("STEP 1: Loading Dataset")
			print("-" * 60)
			X, y = self.load_dataset(student_id)
			
			# Train classifier
			print("STEP 2: Training Classifier")
			print("-" * 60)
			knn = self.train_knn_classifier(X, y)
			
			# Save model (per-student legacy behaviour)
			print("STEP 3: Saving Model (per-student legacy)")
			print("-" * 60)
			model_dir = os.path.join(self.model_base_path, student_id)
			os.makedirs(model_dir, exist_ok=True)
			
			model_path = os.path.join(model_dir, 'face_model.pkl')
			with open(model_path, 'wb') as f:
				pickle.dump(knn, f)
			
			print(f"Model saved to: {model_path}\n")
			
			# Get accuracy stats
			accuracy = knn.score(X, y)
			
			print("=" * 60)
			print(f"TRAINING COMPLETED SUCCESSFULLY")
			print("=" * 60)
			print(f"  Student ID: {student_id}")
			print(f"  Samples: {len(X)}")
			print(f"  Model Accuracy: {accuracy:.2%}")
			print(f"  Model Path: {model_path}\n")
			
			return {
				'success': True,
				'student_id': student_id,
				'model_path': model_path,
				'samples': len(X),
				'accuracy': float(accuracy)
			}
			
		except Exception as e:
			error_msg = str(e)
			print(f"\n✗ TRAINING FAILED: {error_msg}\n")
			return {
				'success': False,
				'student_id': student_id,
				'error': error_msg
			}
	
	def load_model(self, student_id: str):
		"""
		Load a trained KNN model for a student.
		
		Args:
			student_id: Student identifier
			
		Returns:
			Trained KNN classifier
			
		Raises:
			FileNotFoundError: If model doesn't exist
		"""
		# Backwards compatible loader for per-student models
		model_path = os.path.join(self.model_base_path, student_id, 'face_model.pkl')
		if not os.path.exists(model_path):
			raise FileNotFoundError(f"Model not found: {model_path}")
		with open(model_path, 'rb') as f:
			knn = pickle.load(f)
		return knn

	def train_all(self, n_neighbors: int = 3) -> Dict[str, any]:
		"""
		Train a single combined KNN classifier for all students found under dataset_base_path
		and save it to models/face_model.pkl (single file, no subdirectories).
		"""
		try:
			print("=" * 60)
			print("STARTING TRAINING FOR ALL STUDENTS")
			print("=" * 60 + "\n")
			# Iterate all student folders
			student_dirs = sorted([d for d in os.listdir(self.dataset_base_path) if os.path.isdir(os.path.join(self.dataset_base_path, d))])
			all_embeddings = []
			all_labels = []
			for sid in student_dirs:
				try:
					x, y = self.load_dataset(sid)
					all_embeddings.extend(x.tolist())
					all_labels.extend(y.tolist())
				except Exception as e:
					print(f"Skipping {sid}: {e}")
					continue
			if not all_embeddings:
				raise ValueError("No embeddings found across datasets; aborting training")
			X = np.array(all_embeddings)
			y = np.array(all_labels)
			# Train classifier
			knn = self.train_knn_classifier(X, y, n_neighbors=n_neighbors)
			# Save combined model and training data into a single file
			combined_path = os.path.join(self.model_base_path, 'face_model.pkl')
			with open(combined_path, 'wb') as f:
				pickle.dump({'knn': knn, 'embeddings': X, 'labels': y}, f)
			print(f"Combined model saved to: {combined_path}\n")
			accuracy = knn.score(X, y)
			return {'success': True, 'model_path': combined_path, 'samples': len(X), 'unique_labels': len(set(y)), 'accuracy': float(accuracy)}
		except Exception as e:
			error_msg = str(e)
			print(f"\n✗ TRAINING ALL FAILED: {error_msg}\n")
			return {'success': False, 'error': error_msg}

	def load_combined_model(self):
		"""Load the combined model file saved by train_all() and return dict with knn, embeddings, labels"""
		combined_path = os.path.join(self.model_base_path, 'face_model.pkl')
		if not os.path.exists(combined_path):
			raise FileNotFoundError(f"Combined model not found: {combined_path}")
		with open(combined_path, 'rb') as f:
			data = pickle.load(f)
		# Expecting a dict with keys: knn, embeddings, labels
		return data


def main():
	"""Command-line interface for training."""
	import sys
	
	if len(sys.argv) < 2:
		print("Usage: python train.py <student_id>")
		print("Example: python train.py REG001")
		sys.exit(1)
	
	student_id = sys.argv[1].strip().upper()
	
	trainer = FaceRecognitionTrainer()
	result = trainer.train_student(student_id)
	
	sys.exit(0 if result['success'] else 1)


if __name__ == '__main__':
	main()
