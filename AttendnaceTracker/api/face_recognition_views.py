# Face Recognition and Attendance Views from AttendanceSystem
from django.shortcuts import render
from django.http import JsonResponse, StreamingHttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login as auth_login, logout as auth_logout
from django.shortcuts import redirect
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_POST
from .models import UserProfile, Attendance, UnknownPerson
import re
import cv2
import os
import json
import time
import threading
from pathlib import Path
import sys

# Add parent directory to path for recognition_config import
parent_dir = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(parent_dir / 'AttendanceSystem'))

try:
    from recognition_config import (
        RECOGNITION_THRESHOLD,
        CLAHE_CLIP_LIMIT,
        CLAHE_TILE_SIZE,
        FACE_DETECTION_SCALE_FACTOR,
        FACE_DETECTION_MIN_NEIGHBORS,
        FACE_DETECTION_MIN_SIZE
    )
except ImportError:
    # Fallback defaults if config file not found
    RECOGNITION_THRESHOLD = 0.85
    CLAHE_CLIP_LIMIT = 2.0
    CLAHE_TILE_SIZE = (8, 8)
    FACE_DETECTION_SCALE_FACTOR = 1.1
    FACE_DETECTION_MIN_NEIGHBORS = 5
    FACE_DETECTION_MIN_SIZE = (80, 80)


def index(request):
    """Render the project's index.html template."""
    return render(request, 'index.html')


@login_required
def dashboard(request):
    """Render the dashboard for authenticated users."""
    # Check if user is admin/staff - if not, they need a UserProfile
    if not request.user.is_superuser and not request.user.is_staff:
        try:
            user_profile = UserProfile.objects.get(user=request.user)
        except UserProfile.DoesNotExist:
            # User is not a student with face recognition profile
            return JsonResponse({'error': 'No UserProfile found for this user'}, status=403)
    
    user_profile = None
    try:
        user_profile = UserProfile.objects.get(user=request.user)
    except UserProfile.DoesNotExist:
        pass
    
    # Load all students for the table
    students = UserProfile.objects.select_related('user').all().order_by('user__first_name', 'user__username')

    context = {
        'user_profile': user_profile,
        'students': students,
        'is_admin': request.user.is_superuser or request.user.is_staff,
    }
    return render(request, 'dashboard.html', context)


@csrf_exempt
def signup(request):
    """Handle signup POST requests. Returns JSON with errors or success."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    # Extract fields from request.POST / request.FILES
    name = request.POST.get('name', '').strip()
    username = request.POST.get('username', '').strip()
    email = request.POST.get('email', '').strip()
    phone = request.POST.get('phone', '').strip()
    student_id = request.POST.get('student_id', '').strip()
    department = request.POST.get('department', '').strip()
    password = request.POST.get('password', '')

    errors = {}

    # First name validation: only letters and spaces
    if not name or not re.match(r'^[A-Za-z ]+$', name):
        errors['name'] = 'Full name must contain only letters and spaces.'

    # Username cannot be only numbers and must be unique
    if not username or re.match(r'^\d+$', username):
        errors['username'] = 'Username cannot be only numbers and is required.'
    elif User.objects.filter(username__iexact=username).exists():
        errors['username'] = 'Username already exists.'

    # Email basic validation: not numeric-only local part and uniqueness
    if not email or '@' not in email:
        errors['email'] = 'Valid email is required.'
    else:
        local = email.split('@', 1)[0]
        if re.match(r'^\d+$', local):
            errors['email'] = 'Email local part cannot be numbers only.'
        elif User.objects.filter(email__iexact=email).exists():
            errors['email'] = 'Email already in use.'

    # Phone must be 10 digits
    if not re.match(r'^\d{10}$', phone or ''):
        errors['phone'] = 'Phone number must be 10 digits.'

    # Student ID pattern REG001 (REG followed by digits) and unique
    if not re.match(r'^REG\d{3,}$', student_id or ''):
        errors['student_id'] = 'Student ID must be in format REG001.'
    elif UserProfile.objects.filter(student_id__iexact=student_id).exists():
        errors['student_id'] = 'Student ID already exists.'

    # Password length
    if not password or len(password) < 6:
        errors['password'] = 'Password must be at least 6 characters.'

    if errors:
        return JsonResponse({'errors': errors}, status=400)

    # Create user
    user = User.objects.create_user(username=username, email=email, password=password, first_name=name)

    # Handle avatar file if present
    avatar_file = request.FILES.get('avatar')
    profile = UserProfile(user=user, phone=phone, student_id=student_id, department=department)
    if avatar_file:
        profile.avatar.save(avatar_file.name, avatar_file)
    profile.save()

    # Store student_id in session for face capture
    request.session['pending_face_capture'] = student_id
    
    return JsonResponse({'success': True, 'message': 'User created successfully', 'student_id': student_id, 'redirect_to_capture': True})


@csrf_exempt
def user_login(request):
    """Handle login POST. Accepts email or username in 'email' field, plus 'password'."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    identifier = request.POST.get('email', '').strip()
    password = request.POST.get('password', '')

    errors = {}
    if not identifier:
        errors['email'] = 'Email or username is required.'
    if not password:
        errors['password'] = 'Password is required.'
    if errors:
        return JsonResponse({'errors': errors}, status=400)

    # Resolve username from identifier
    user = None
    if '@' in identifier:
        try:
            user = User.objects.get(email__iexact=identifier)
        except User.DoesNotExist:
            return JsonResponse({'errors': {'email': 'No account found with this email.'}}, status=400)
    else:
        try:
            user = User.objects.get(username__iexact=identifier)
        except User.DoesNotExist:
            return JsonResponse({'errors': {'email': 'No account found with this username.'}}, status=400)

    auth_user = authenticate(username=user.username, password=password)
    if auth_user is None:
        return JsonResponse({'errors': {'password': 'Invalid password.'}}, status=400)

    # Log the user in (session)
    auth_login(request, auth_user)
    
    # Determine redirect URL based on user type
    redirect_url = '/'
    if auth_user.is_superuser or auth_user.is_staff:
        redirect_url = '/attendance-dashboard/'
    else:
        # Check if user has a student profile
        try:
            UserProfile.objects.get(user=auth_user)
            redirect_url = '/student-dashboard/'
        except UserProfile.DoesNotExist:
            redirect_url = '/student-dashboard/'  # Still redirect to student dashboard
    
    return JsonResponse({'success': True, 'message': 'Logged in successfully', 'redirect_url': redirect_url})


def user_logout(request):
    """Log out the current user. Accepts POST; redirects to index for GET."""
    if request.method == 'POST':
        auth_logout(request)
        # If AJAX, return JSON, otherwise redirect back to index
        if request.headers.get('x-requested-with') == 'XMLHttpRequest':
            return JsonResponse({'success': True, 'message': 'Logged out'})
        return redirect('index')


@login_required
@require_POST
def student_update(request, pk: int):
    """Update a student's User + UserProfile details. Accepts multipart/form-data."""
    try:
        profile = UserProfile.objects.select_related('user').get(pk=pk)
    except UserProfile.DoesNotExist:
        return JsonResponse({'error': 'Student not found'}, status=404)

    # Extract fields
    name = request.POST.get('name', '').strip()
    email = request.POST.get('email', '').strip()
    phone = request.POST.get('phone', '').strip()
    student_id = request.POST.get('student_id', '').strip()
    department = request.POST.get('department', '').strip()

    # Basic validations
    errors = {}
    if not name:
        errors['name'] = 'Name is required.'
    if not email or '@' not in email:
        errors['email'] = 'Valid email is required.'
    else:
        if User.objects.exclude(pk=profile.user.pk).filter(email__iexact=email).exists():
            errors['email'] = 'Email already in use.'
    if phone and not re.match(r'^\d{10}$', phone):
        errors['phone'] = 'Phone must be 10 digits.'
    if student_id:
        if not re.match(r'^REG\d{3,}$', student_id):
            errors['student_id'] = 'Student ID must be like REG001.'
        elif UserProfile.objects.exclude(pk=pk).filter(student_id__iexact=student_id).exists():
            errors['student_id'] = 'Student ID already exists.'

    if errors:
        return JsonResponse({'errors': errors}, status=400)

    # Update user
    profile.user.first_name = name
    profile.user.email = email
    profile.user.save(update_fields=['first_name', 'email'])

    # Update profile
    profile.phone = phone
    if student_id:
        profile.student_id = student_id
    if department:
        profile.department = department

    # Avatar optional
    avatar_file = request.FILES.get('avatar')
    if avatar_file:
        profile.avatar.save(avatar_file.name, avatar_file, save=False)
    profile.save()

    return JsonResponse({
        'success': True,
        'student': {
            'pk': profile.pk,
            'name': profile.user.first_name or profile.user.username,
            'email': profile.user.email,
            'phone': profile.phone,
            'student_id': profile.student_id,
            'department': profile.department,
            'avatar_url': profile.avatar.url if profile.avatar else '',
        }
    })


@login_required
@require_POST
def student_delete(request, pk: int):
    """Delete a student (User + Profile)."""
    try:
        profile = UserProfile.objects.select_related('user').get(pk=pk)
    except UserProfile.DoesNotExist:
        return JsonResponse({'error': 'Student not found'}, status=404)

    # Delete the user cascades to profile
    profile.user.delete()

    return JsonResponse({'success': True})


# Global variables for face capture
face_capture_status = {}
face_capture_frames = {}


def face_capture_page(request):
    """Render the face capture page."""
    student_id = request.session.get('pending_face_capture')
    
    if not student_id:
        return redirect('index')
    
    # Verify student exists
    try:
        UserProfile.objects.get(student_id=student_id)
    except UserProfile.DoesNotExist:
        return redirect('index')
    
    return render(request, 'face_capture.html', {'student_id': student_id})


@csrf_exempt
def start_face_capture(request):
    """Start capturing face images for training."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        student_id = data.get('student_id')
    except:
        return JsonResponse({'error': 'Invalid request'}, status=400)
    
    if not student_id:
        return JsonResponse({'error': 'Student ID required'}, status=400)
    
    # Verify student exists
    try:
        UserProfile.objects.get(student_id=student_id)
    except UserProfile.DoesNotExist:
        return JsonResponse({'error': 'Student not found'}, status=404)
    
    # Create dataset directory
    base_path = Path(__file__).resolve().parent.parent.parent / 'AttendanceSystem'
    dataset_path = base_path / 'dataset' / student_id
    dataset_path.mkdir(parents=True, exist_ok=True)
    
    # Initialize capture status
    face_capture_status[student_id] = {
        'active': True,
        'count': 0,
        'max_images': 50,
        'completed': False
    }
    
    # Start capture in background thread
    def capture_faces():
        try:
            cap = cv2.VideoCapture(0)
            if not cap.isOpened():
                face_capture_status[student_id]['error'] = 'Cannot open camera'
                face_capture_status[student_id]['active'] = False
                return
            
            face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            
            count = 0
            max_images = 50
            frames_without_face = 0
            
            while face_capture_status.get(student_id, {}).get('active', False) and count < max_images:
                ret, frame = cap.read()
                if not ret:
                    time.sleep(0.1)
                    continue
                
                gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                
                # Apply CLAHE for better face detection under varying lighting
                clahe = cv2.createCLAHE(clipLimit=CLAHE_CLIP_LIMIT, tileGridSize=CLAHE_TILE_SIZE)
                gray = clahe.apply(gray)
                
                faces = face_cascade.detectMultiScale(
                    gray, 
                    scaleFactor=FACE_DETECTION_SCALE_FACTOR, 
                    minNeighbors=FACE_DETECTION_MIN_NEIGHBORS, 
                    minSize=FACE_DETECTION_MIN_SIZE
                )
                
                # Draw rectangles on frame for visualization
                for (x, y, w, h) in faces:
                    cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
                
                # Store frame for streaming
                face_capture_frames[student_id] = frame.copy()
                
                if len(faces) > 0:
                    frames_without_face = 0
                    for (x, y, w, h) in faces:
                        # Take only first face
                        count += 1
                        face_img = frame[y:y+h, x:x+w]
                        
                        # Normalize lighting before resizing
                        face_img_normalized = cv2.normalize(face_img, None, 0, 255, cv2.NORM_MINMAX)
                        
                        # Resize to standard size
                        face_img = cv2.resize(face_img_normalized, (160, 160))
                        
                        # Save image
                        img_name = f"{count}.jpg"
                        img_path = dataset_path / img_name
                        cv2.imwrite(str(img_path), face_img)
                        
                        # Update status
                        face_capture_status[student_id]['count'] = count
                        
                        # Wait between captures
                        time.sleep(0.15)
                        
                        if count >= max_images:
                            break
                        break  # Only process first face
                else:
                    frames_without_face += 1
                
                # Small delay
                time.sleep(0.05)
            
            cap.release()
            face_capture_status[student_id]['active'] = False
            face_capture_status[student_id]['completed'] = True
            
        except Exception as e:
            face_capture_status[student_id]['error'] = str(e)
            face_capture_status[student_id]['active'] = False
    
    thread = threading.Thread(target=capture_faces, daemon=True)
    thread.start()
    
    return JsonResponse({'success': True, 'message': 'Capture started'})


@csrf_exempt
def capture_status(request, student_id):
    """Get capture status."""
    status = face_capture_status.get(student_id, {
        'active': False,
        'count': 0,
        'max_images': 50,
        'completed': False
    })
    return JsonResponse(status)


@csrf_exempt
def stop_face_capture(request):
    """Stop face capture."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        student_id = data.get('student_id')
    except:
        return JsonResponse({'error': 'Invalid request'}, status=400)
    
    if student_id in face_capture_status:
        face_capture_status[student_id]['active'] = False
    
    return JsonResponse({'success': True})


@csrf_exempt
def train_model(request):
    """Train the face recognition model."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        student_id = data.get('student_id')
    except:
        return JsonResponse({'error': 'Invalid request'}, status=400)
    
    if not student_id:
        return JsonResponse({'error': 'Student ID required'}, status=400)
    
    try:
        # Import trainer
        import sys
        base_path = Path(__file__).resolve().parent.parent.parent / 'AttendanceSystem'
        sys.path.insert(0, str(base_path))
        
        from train import FaceRecognitionTrainer
        
        # Create trainer instance
        trainer = FaceRecognitionTrainer(
            dataset_base_path=str(base_path / 'dataset'),
            model_base_path=str(base_path / 'models')
        )
        
        # Train the model
        result = trainer.train_student(student_id)
        # After training single student legacy model, rebuild the combined model for all students
        try:
            combined_result = trainer.train_all()
        except Exception as e:
            combined_result = {'success': False, 'error': str(e)}
        
        # Clear session
        if 'pending_face_capture' in request.session:
            del request.session['pending_face_capture']
        # Return both results
        return JsonResponse({'single_train': result, 'combined_train': combined_result})
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def video_feed(request, student_id):
    """Stream video feed with face detection."""
    def generate():
        while face_capture_status.get(student_id, {}).get('active', False):
            frame = face_capture_frames.get(student_id)
            if frame is not None:
                ret, buffer = cv2.imencode('.jpg', frame)
                frame_bytes = buffer.tobytes()
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
            time.sleep(0.033)  # ~30 fps
    
    return StreamingHttpResponse(generate(), content_type='multipart/x-mixed-replace; boundary=frame')


# Attendance System
from django.utils import timezone
from django.core.files.base import ContentFile
from datetime import datetime
import pickle
import numpy as np

# Global variables for attendance camera
attendance_camera_active = {}
attendance_camera_frames = {}


@csrf_exempt
def start_attendance_camera(request):
    """Start attendance camera with face recognition."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        class_name = data.get('class_name')
        cutoff_time_str = data.get('cutoff_time')
    except:
        return JsonResponse({'error': 'Invalid request'}, status=400)
    
    if not class_name or not cutoff_time_str:
        return JsonResponse({'error': 'Class name and cutoff time required'}, status=400)
    
    # Parse cutoff time
    try:
        cutoff_time = datetime.strptime(cutoff_time_str, '%H:%M').time()
    except:
        return JsonResponse({'error': 'Invalid time format'}, status=400)
    
    # Load face recognition model
    try:
        from keras_facenet import FaceNet
        embedder = FaceNet()
        
        # Prefer loading a single combined model if present
        base_path = Path(__file__).resolve().parent.parent.parent / 'AttendanceSystem'
        models_path = base_path / 'models'
        combined_model_file = models_path / 'face_model.pkl'
        all_embeddings = []
        all_labels = []
        combined_model = None
        if combined_model_file.exists():
            # Load combined model object
            with open(combined_model_file, 'rb') as f:
                try:
                    data = pickle.load(f)
                    # data expected to be a dict with 'knn' key
                    if isinstance(data, dict) and 'knn' in data:
                        combined_model = data['knn']
                        all_embeddings = data.get('embeddings', [])
                        all_labels = data.get('labels', [])
                except Exception:
                    # Fallback: file may be a raw model
                    f.seek(0)
                    combined_model = pickle.load(f)
        
        # If combined_model not available, fall back to old per-student scan
        if combined_model is None:
            if not models_path.exists():
                return JsonResponse({'error': 'No trained models found'}, status=404)
            for student_dir in models_path.iterdir():
                if student_dir.is_dir():
                    model_file = student_dir / 'face_model.pkl'
                    if model_file.exists():
                        with open(model_file, 'rb') as f:
                            student_model = pickle.load(f)
                            if hasattr(student_model, '_fit_X'):
                                all_embeddings.extend(student_model._fit_X)
                                all_labels.extend([student_dir.name] * len(student_model._fit_X))
            if not all_embeddings:
                return JsonResponse({'error': 'No trained faces found'}, status=404)
            from sklearn.neighbors import KNeighborsClassifier
            combined_model = KNeighborsClassifier(n_neighbors=3, metric='euclidean')
            combined_model.fit(np.array(all_embeddings), np.array(all_labels))
        
    except Exception as e:
        return JsonResponse({'error': f'Failed to load models: {str(e)}'}, status=500)
    
    # Initialize camera status
    session_id = f"{class_name}_{int(time.time())}"
    attendance_camera_active[session_id] = {
        'active': True,
        'class_name': class_name,
        'cutoff_time': cutoff_time,
        'last_recognition': {},
        'student_actions': {},  # Track last action per student (Check-In/Check-Out)
        'unknown_detections': {}  # Track unknown face detection start time by position
    }
    
    # Start camera thread
    def run_attendance_camera():
        try:
            cap = cv2.VideoCapture(0)
            if not cap.isOpened():
                attendance_camera_active[session_id]['error'] = 'Cannot open camera'
                attendance_camera_active[session_id]['active'] = False
                return
            
            face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            
            while attendance_camera_active.get(session_id, {}).get('active', False):
                ret, frame = cap.read()
                if not ret:
                    time.sleep(0.1)
                    continue
                
                # Flip camera horizontally (mirror effect)
                frame = cv2.flip(frame, 1)
                
                height, width = frame.shape[:2]
                line_x = width // 2
                
                # Draw vertical line
                cv2.line(frame, (line_x, 0), (line_x, height), (0, 0, 255), 2)
                cv2.putText(frame, "Attendance Line", (line_x - 80, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
                
                gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                
                # Apply CLAHE for better lighting normalization
                clahe = cv2.createCLAHE(clipLimit=CLAHE_CLIP_LIMIT, tileGridSize=CLAHE_TILE_SIZE)
                gray = clahe.apply(gray)
                
                faces = face_cascade.detectMultiScale(
                    gray, 
                    scaleFactor=FACE_DETECTION_SCALE_FACTOR, 
                    minNeighbors=FACE_DETECTION_MIN_NEIGHBORS, 
                )
                
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                
                for (x, y, w, h) in faces:
                    current_time = time.time()  # Get current time once per face for consistency
                    face_img = rgb_frame[y:y+h, x:x+w]
                    
                    # Normalize lighting on the face region
                    face_img_normalized = cv2.normalize(face_img, None, 0, 255, cv2.NORM_MINMAX)
                    face_img_resized = cv2.resize(face_img_normalized, (160, 160))
                    
                    # Determine which side of line the face is on
                    face_center_x = x + w // 2
                    is_right_side = face_center_x > line_x
                
                    try:
                        # Get embedding
                        embedding = embedder.embeddings([face_img_resized])[0]
                        
                        # Predict with distance
                        distances, indices = combined_model.kneighbors([embedding])
                        min_distance = distances[0][0]
                        
                        # Use configurable threshold
                        if min_distance < RECOGNITION_THRESHOLD:  # Recognized
                            student_id = combined_model.predict([embedding])[0]
                            
                            try:
                                # Check student's current attendance state in database
                                profile = UserProfile.objects.get(student_id=student_id)
                                now = timezone.now()
                                current_time_only = now.time()
                                
                                # Determine action based on which side of line
                                # Left side (face_center_x <= line_x) = Check-In
                                # Right side (face_center_x > line_x) = Check-Out
                                if is_right_side:
                                    action = 'Check-Out'
                                    status = 'On-Time'  # Check-out doesn't have late status
                                else:
                                    action = 'Check-In'
                                    status = 'Late' if current_time_only > cutoff_time else 'On-Time'
                                
                                # Get the last attendance entry for this student today
                                last_entry = Attendance.objects.filter(
                                    student=profile,
                                    date=now.date(),
                                    class_name=class_name
                                ).order_by('-timestamp').first()
                                
                                # Enforce alternating sequence: Check-In → Check-Out → Check-In → Check-Out
                                can_create = False
                                if last_entry is None:
                                    # No entries yet - only allow check-in
                                    can_create = (action == 'Check-In')
                                elif last_entry.action == 'Check-In':
                                    # Last action was check-in - only allow check-out
                                    can_create = (action == 'Check-Out')
                                elif last_entry.action == 'Check-Out':
                                    # Last action was check-out - only allow check-in
                                    can_create = (action == 'Check-In')
                                
                                # Only create entry if action follows proper sequence
                                if can_create:
                                    # Create separate entry for this action (check-in or check-out)
                                    attendance = Attendance.objects.create(
                                        student=profile,
                                        date=now.date(),
                                        class_name=class_name,
                                        timestamp=now,
                                        action=action,
                                        status=status
                                    )
                                    
                                    # Store result for display
                                    attendance_camera_active[session_id]['last_result'] = {
                                        'student_id': student_id,
                                        'name': profile.user.first_name or profile.user.username,
                                        'status': status,
                                        'time': now.strftime('%H:%M:%S'),
                                        'action': action
                                    }
                            except UserProfile.DoesNotExist:
                                pass
                            
                            # Draw green rectangle
                            cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
                            cv2.putText(frame, student_id, (x, y-10),
                                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                        else:
                            # Unknown person detected
                            cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 0, 255), 2)
                            cv2.putText(frame, "Unknown", (x, y-10),
                                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                            
                            # Track unknown face detection time (require 3 seconds continuous detection)
                            face_position_key = f"{x}_{y}_{w}_{h}"  # Approximate position key
                            unknown_detections = attendance_camera_active[session_id].get('unknown_detections', {})
                            current_time = time.time()
                            
                            # Find if this is a continuing detection (within 50px of previous)
                            continuing_detection = None
                            for key, start_time in list(unknown_detections.items()):
                                # Clean old detections (not seen in last 2 seconds)
                                if current_time - start_time > 5:
                                    del unknown_detections[key]
                                    continue
                                
                                # Check if this is same person (approximate position match)
                                old_coords = key.split('_')
                                if len(old_coords) == 4:
                                    old_x, old_y = int(old_coords[0]), int(old_coords[1])
                                    if abs(x - old_x) < 50 and abs(y - old_y) < 50:
                                        continuing_detection = key
                                        break
                            
                            if continuing_detection:
                                # Continuing detection - check if 3 seconds elapsed
                                detection_duration = current_time - unknown_detections[continuing_detection]
                                if detection_duration >= 3.0:
                                    # Unknown face confirmed after 3 seconds - save once
                                    last_save = attendance_camera_active[session_id]['last_recognition'].get('unknown_saved', 0)
                                    if current_time - last_save > 10:  # Save at most once per 10 seconds
                                        attendance_camera_active[session_id]['last_recognition']['unknown_saved'] = current_time
                                        
                                        # Save to database
                                        face_bgr = frame[y:y+h, x:x+w]
                                        ret, buffer = cv2.imencode('.jpg', face_bgr)
                                        unknown = UnknownPerson(class_name=class_name)
                                        unknown.image.save(f'unknown_{int(time.time())}.jpg', ContentFile(buffer.tobytes()))
                                        unknown.save()
                                        
                                        attendance_camera_active[session_id]['last_result'] = {
                                            'unknown': True,
                                            'message': '⚠️ Unknown person detected!'
                                        }
                                        
                                        # Clear this detection after saving
                                        del unknown_detections[continuing_detection]
                            else:
                                # New unknown detection - start tracking
                                unknown_detections[face_position_key] = current_time
                            
                            # Update the unknown_detections dict
                            attendance_camera_active[session_id]['unknown_detections'] = unknown_detections
                    
                    except Exception as e:
                        print(f"Recognition error: {e}")
                        cv2.rectangle(frame, (x, y), (x+w, y+h), (255, 0, 0), 2)
                
                # Store frame for streaming
                attendance_camera_frames[session_id] = frame.copy()
                time.sleep(0.033)
            
            cap.release()
            attendance_camera_active[session_id]['active'] = False
            
        except Exception as e:
            print(f"Camera error: {e}")
            attendance_camera_active[session_id]['error'] = str(e)
            attendance_camera_active[session_id]['active'] = False
    
    thread = threading.Thread(target=run_attendance_camera, daemon=True)
    thread.start()
    
    return JsonResponse({'success': True, 'session_id': session_id})


def attendance_video_feed(request, session_id):
    """Stream attendance camera feed."""
    def generate():
        while attendance_camera_active.get(session_id, {}).get('active', False):
            frame = attendance_camera_frames.get(session_id)
            if frame is not None:
                ret, buffer = cv2.imencode('.jpg', frame)
                frame_bytes = buffer.tobytes()
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
            time.sleep(0.033)
    
    return StreamingHttpResponse(generate(), content_type='multipart/x-mixed-replace; boundary=frame')


@csrf_exempt
def attendance_status(request, session_id):
    """Get attendance camera status."""
    status = attendance_camera_active.get(session_id, {})
    return JsonResponse(status)


@csrf_exempt
def stop_attendance_camera(request):
    """Stop attendance camera."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        session_id = data.get('session_id')
    except:
        return JsonResponse({'error': 'Invalid request'}, status=400)
    
    if session_id in attendance_camera_active:
        attendance_camera_active[session_id]['active'] = False
    
    return JsonResponse({'success': True})


@login_required
def dashboard_stats(request):
    """Get real-time dashboard statistics."""
    from django.db.models import Count, Q
    from datetime import date, timedelta
    
    today = date.today()
    
    # Total students
    total_students = UserProfile.objects.count()
    
    # Today's attendance (unique students based on Check-In actions)
    today_attendance = Attendance.objects.filter(date=today, action='Check-In').values('student').distinct().count()
    attendance_rate = round((today_attendance / total_students * 100), 1) if total_students > 0 else 0

    # Active sessions by class - compute students whose last action today is Check-In
    classes_in_session = 0

    # On-time vs Late (distinct students counted once based on their Check-In status)
    on_time_count = Attendance.objects.filter(date=today, action='Check-In', status='On-Time').values('student').distinct().count()
    late_count = Attendance.objects.filter(date=today, action='Check-In', status='Late').values('student').distinct().count()
    punctuality = round((on_time_count / today_attendance * 100), 0) if today_attendance > 0 else 0

    # Unknown faces today
    unknown_count = UnknownPerson.objects.filter(detected_at__date=today).count()

    # Weekly attendance trend (last 7 days) - count unique students who checked in each day
    weekly_data = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        count = Attendance.objects.filter(date=day, action='Check-In').values('student').distinct().count()
        weekly_data.append({
            'date': day.strftime('%a'),
            'count': count
        })

    # Class breakdown (distinct students who checked in today)
    class_data = Attendance.objects.filter(date=today, action='Check-In').values('class_name').annotate(
        count=Count('student', distinct=True),
        on_time=Count('student', filter=Q(status='On-Time', action='Check-In'), distinct=True),
        late=Count('student', filter=Q(status='Late', action='Check-In'), distinct=True)
    )

    # Top classes by attendance
    top_classes = list(class_data.order_by('-count')[:4])
    
    # Live classroom status (students currently checked in)
    from django.db.models import Max, F
    live_classes = []
    for cls in ['BCA', 'BSC', 'BCOM', 'ELECTRONICS']:
        # Get distinct students and their most recent action today in this class
        # Use subquery to get the latest timestamp per student
        latest_entries = Attendance.objects.filter(date=today, class_name=cls).values('student').annotate(
            latest_timestamp=Max('timestamp')
        )
        
        checked_in = 0
        for entry in latest_entries:
            student_id = entry['student']
            latest_timestamp = entry['latest_timestamp']
            # Get the most recent attendance entry for this student
            last_attendance = Attendance.objects.filter(
                date=today,
                class_name=cls,
                student_id=student_id,
                timestamp=latest_timestamp
            ).first()
            if last_attendance and last_attendance.action == 'Check-In':
                checked_in += 1
        
        # Assume max capacity of 60 students per class
        capacity_percent = min(round((checked_in / 60) * 100), 120)
        if checked_in == 0:
            status = 'No active session'
            status_color = 'slate'
        else:
            status = 'In session' if capacity_percent < 80 else ('Filling fast' if capacity_percent < 100 else 'Over capacity')
            status_color = 'emerald' if capacity_percent < 80 else ('amber' if capacity_percent < 100 else 'rose')
        live_classes.append({
            'class_name': cls,
            'checked_in': checked_in,
            'capacity_percent': capacity_percent,
            'status': status,
            'status_color': status_color
        })
    
    return JsonResponse({
        'total_students': total_students,
        'attendance_rate': attendance_rate,
        'classes_in_session': classes_in_session,
        'punctuality': punctuality,
        'unknown_count': unknown_count,
        'weekly_data': weekly_data,
        'class_data': list(class_data),
        'top_classes': top_classes,
        'live_classes': live_classes,
        'today_attendance': today_attendance,
        'on_time_count': on_time_count,
        'late_count': late_count,
    })


@login_required
def crowd_report(request):
    """Return a crowd detection summary for configured classrooms/zones."""
    from datetime import date
    from django.db.models import Max

    today = date.today()

    # Configure the monitored zones and their nominal capacities
    zones_config = {
        'BCA': 60,
        'BSC': 60,
        'BCOM': 60,
        'ELECTRONICS': 60,
    }

    threshold = 85  # percent at which occupancy is considered critical
    total_present = 0
    total_capacity = 0
    zones = []

    for zone_name, capacity in zones_config.items():
        # For each student in this zone today get their latest timestamp
        latest_entries = Attendance.objects.filter(date=today, class_name=zone_name).values('student').annotate(latest_timestamp=Max('timestamp'))

        checked_in = 0
        for entry in latest_entries:
            student_id = entry['student']
            latest_ts = entry['latest_timestamp']
            last_att = Attendance.objects.filter(date=today, class_name=zone_name, student_id=student_id, timestamp=latest_ts).first()
            if last_att and last_att.action == 'Check-In':
                checked_in += 1

        capacity_percent = min(round((checked_in / capacity) * 100), 120) if capacity > 0 else 0

        if capacity_percent >= threshold:
            status = 'Critical'
        elif capacity_percent >= 80:
            status = 'High'
        elif capacity_percent >= 60:
            status = 'Moderate'
        else:
            status = 'Low'

        zones.append({
            'zone': zone_name,
            'present': checked_in,
            'capacity': capacity,
            'density_percent': capacity_percent,
            'status': status
        })

        total_present += checked_in
        total_capacity += capacity

    overall_occupancy = min(round((total_present / total_capacity) * 100), 100) if total_capacity > 0 else 0

    return JsonResponse({
        'overall_occupancy': overall_occupancy,
        'threshold': threshold,
        'zones': zones,
    })


@login_required
def unknown_faces(request):
    """Get unknown faces detected."""
    
    unknown = UnknownPerson.objects.all()[:20]  # Last 20 unknown faces
    
    data = []
    for u in unknown:
        data.append({
            'id': u.id,
            'image_url': u.image.url if u.image else '',
            'detected_at': u.detected_at.strftime('%Y-%m-%d %H:%M:%S'),
            'class_name': u.class_name,
            'time_ago': get_time_ago(u.detected_at)
        })
    
    return JsonResponse({'unknown_faces': data})


@login_required
def student_dashboard(request):
    """Render a simplified dashboard for students showing personal attendance."""
    try:
        profile = UserProfile.objects.get(user=request.user)
    except UserProfile.DoesNotExist:
        return redirect('index')

    from datetime import date, timedelta
    today = date.today()

    # Recent attendance records for this student (last 30 days)
    thirty_days_ago = today - timedelta(days=30)
    records = Attendance.objects.filter(student=profile, date__gte=thirty_days_ago).order_by('-date')

    # Summary
    total_present = Attendance.objects.filter(student=profile, date__gte=thirty_days_ago).count()
    on_time = Attendance.objects.filter(student=profile, date__gte=thirty_days_ago, status='On-Time').count()
    late = Attendance.objects.filter(student=profile, date__gte=thirty_days_ago, status='Late').count()

    # Today's attendance
    today_record = Attendance.objects.filter(student=profile, date=today).first()

    context = {
        'profile': profile,
        'records': records,
        'total_present': total_present,
        'on_time': on_time,
        'late': late,
        'today_record': today_record,
    }
    return render(request, 'student_dashboard.html', context)


def get_time_ago(dt):
    """Calculate time ago from datetime."""
    from django.utils import timezone
    now = timezone.now()
    diff = now - dt
    
    if diff.days > 0:
        return f"{diff.days} day{'s' if diff.days > 1 else ''} ago"
    elif diff.seconds >= 3600:
        hours = diff.seconds // 3600
        return f"{hours} hour{'s' if hours > 1 else ''} ago"
    elif diff.seconds >= 60:
        minutes = diff.seconds // 60
        return f"{minutes} minute{'s' if minutes > 1 else ''} ago"
    else:
        return "Just now"


@login_required
def class_attendance_history(request):
    """Get attendance history for all classes (last 30 days)."""
    from django.db.models import Count, Q
    from datetime import date, timedelta
    
    today = date.today()
    thirty_days_ago = today - timedelta(days=30)
    
    classes = ['BCA', 'BSC', 'BCOM', 'ELECTRONICS']
    class_data = {}
    
    for cls in classes:
        # Get all attendance records for this class in last 30 days
        records = Attendance.objects.filter(
            class_name=cls,
            date__gte=thirty_days_ago,
            date__lte=today
        ).values('date').annotate(
            total=Count('id'),
            on_time=Count('id', filter=Q(status='On-Time')),
            late=Count('id', filter=Q(status='Late'))
        ).order_by('date')
        
        # Calculate summary statistics (unique students based on Check-In actions)
        # Count distinct students who checked in during the period
        total_attendance = Attendance.objects.filter(
            class_name=cls,
            date__gte=thirty_days_ago,
            action='Check-In'
        ).values('student').distinct().count()
        
        total_on_time = Attendance.objects.filter(
            class_name=cls,
            date__gte=thirty_days_ago,
            action='Check-In',
            status='On-Time'
        ).values('student').distinct().count()
        
        total_late = Attendance.objects.filter(
            class_name=cls,
            date__gte=thirty_days_ago,
            action='Check-In',
            status='Late'
        ).values('student').distinct().count()
        
        # Get unique students in this class (last 30 days) - same as total_attendance (distinct check-ins)
        unique_students = total_attendance
        
        on_time_percentage = round((total_on_time / total_attendance * 100), 1) if total_attendance > 0 else 0
        
        # Get daily data for last 7 days for chart
        daily_data = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            # count distinct students who checked in that day
            daily_count = Attendance.objects.filter(
                class_name=cls,
                date=day,
                action='Check-In'
            ).values('student').distinct().count()
            daily_data.append({
                'date': day.strftime('%a'),
                'count': daily_count
            })
        
        class_data[cls] = {
            'class_name': cls,
            'total_attendance': total_attendance,
            'total_on_time': total_on_time,
            'total_late': total_late,
            'unique_students': unique_students,
            'on_time_percentage': on_time_percentage,
            'daily_data': daily_data,
            'history': list(records)
        }
    
    # Sort by on_time_percentage descending
    sorted_classes = sorted(class_data.items(), key=lambda x: x[1]['on_time_percentage'], reverse=True)
    
    return JsonResponse({
        'classes': dict(sorted_classes),
        'period': f'Last 30 days (from {thirty_days_ago} to {today})'
    })
