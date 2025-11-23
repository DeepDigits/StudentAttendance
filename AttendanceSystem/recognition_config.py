"""
Face Recognition Configuration
Adjust these parameters to fine-tune recognition accuracy and lighting tolerance
"""

# Recognition threshold - lower = stricter matching, higher = more lenient
# Recommended range: 0.6 (very strict) to 1.0 (very lenient)
# Default was 0.7, increased to 0.85 for better lighting tolerance
RECOGNITION_THRESHOLD = 0.85

# CLAHE parameters for lighting normalization
CLAHE_CLIP_LIMIT = 2.0  # Contrast limiting (1.0-4.0 recommended)
CLAHE_TILE_SIZE = (8, 8)  # Grid size for histogram equalization

# Face detection parameters
FACE_DETECTION_SCALE_FACTOR = 1.1  # Lower = more thorough but slower (1.05-1.3)
FACE_DETECTION_MIN_NEIGHBORS = 5   # Higher = fewer false positives (3-6)
FACE_DETECTION_MIN_SIZE = (80, 80)  # Minimum face size in pixels

# KNN classifier parameters
KNN_N_NEIGHBORS = 3  # Number of neighbors to consider (3-5 recommended)

# Camera settings recommendations
"""
For better face recognition accuracy:

1. Lighting:
   - Use diffused, even lighting (avoid direct overhead or backlight)
   - Minimum 300 lux recommended
   - Consider adding LED panels if needed

2. Camera position:
   - Mount at face level (1.5-1.8m height)
   - 45-60 degree angle to doorway
   - 1-3 meters distance from subject

3. Environment:
   - Minimize shadows on faces
   - Avoid windows behind subjects
   - Use curtains to control natural light variation

4. If accuracy is still low:
   - Increase RECOGNITION_THRESHOLD to 0.9-1.0 (but may increase false positives)
   - Reduce CLAHE_CLIP_LIMIT to 1.5 for less aggressive normalization
   - Ensure training images are captured in similar lighting conditions
   - Retrain model with more diverse lighting samples (capture at different times of day)
"""
