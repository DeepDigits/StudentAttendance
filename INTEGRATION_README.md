# AttendanceSystem and AttendanceTracker Integration

## Overview
This document describes the integration of face recognition and attendance features from the **AttendanceSystem** Django project into the **AttendanceTracker** Django project.

## Changes Made

### 1. Models Integration (`AttendnaceTracker/api/models.py`)

Added three new models from AttendanceSystem while preserving all existing models:

#### a. UserProfile (Face Recognition)
- `user`: OneToOneField to User (related_name='profile')
- `phone`: CharField(max_length=15)
- `student_id`: CharField(max_length=20, unique=True) - Format: REG001, REG002, etc.
- `department`: CharField with choices (BCA, BSc, BCom, Electronics)
- `avatar`: ImageField for profile pictures

**Note**: This is separate from the existing `StudentProfile` model which has `related_name='student_profile'`.

#### b. Attendance
- `student`: ForeignKey to UserProfile
- `date`: DateField
- `class_name`: CharField with choices (BCA, BSC, BCOM, ELECTRONICS)
- `timestamp`: DateTimeField
- `action`: CharField choices (Check-In, Check-Out)
- `status`: CharField choices (On-Time, Late)
- Legacy fields: `check_in_time`, `check_out_time`

#### c. UnknownPerson
- `image`: ImageField for unknown faces detected
- `detected_at`: DateTimeField
- `class_name`: CharField

### 2. Views Integration

Created new file: `AttendnaceTracker/api/face_recognition_views.py`

This file contains all face recognition and attendance-related views:

**Authentication Views:**
- `index()` - Landing page
- `signup()` - Student registration with face capture
- `user_login()` - User authentication
- `user_logout()` - Logout functionality

**Dashboard Views:**
- `dashboard()` - Admin dashboard for attendance management
- `student_dashboard()` - Student personal attendance dashboard
- `dashboard_stats()` - Real-time statistics (renamed to `face_dashboard_stats` in imports)
- `class_attendance_history()` - Historical class attendance data

**Face Capture Views:**
- `face_capture_page()` - Face registration interface
- `start_face_capture()` - Initialize camera and capture faces
- `stop_face_capture()` - Stop face capture session
- `capture_status()` - Poll capture progress
- `train_model()` - Train face recognition model
- `video_feed()` - Stream video during capture

**Attendance Camera Views:**
- `start_attendance_camera()` - Start attendance tracking with face recognition
- `stop_attendance_camera()` - Stop attendance session
- `attendance_status()` - Get attendance session status
- `attendance_video_feed()` - Stream attendance camera feed

**Student Management:**
- `student_update()` - Update student profile
- `student_delete()` - Delete student

**Reporting:**
- `crowd_report()` - Classroom occupancy report
- `unknown_faces()` - List of unrecognized faces

### 3. Templates Integration

Copied all HTML templates from `AttendanceSystem/App/templates/` to `AttendnaceTracker/api/templates/`:
- `index.html` - Landing page with modern UI
- `dashboard.html` - Admin attendance dashboard
- `face_capture.html` - Face registration interface
- `student_dashboard.html` - Student personal dashboard

### 4. URL Configuration (`AttendnaceTracker/AttendnaceTracker/urls.py`)

Added face recognition URL patterns before existing API URLs:

```python
# Face Recognition and Attendance URLs
path('', index, name='index'),
path('attendance-dashboard/', face_dashboard, name='face_dashboard'),
path('student-dashboard/', student_dashboard, name='student_dashboard'),
path('signup/', signup, name='signup'),
path('login/', user_login, name='user_login'),
path('logout/', user_logout, name='logout'),
path('students/<int:pk>/update/', student_update, name='student_update'),
path('students/<int:pk>/delete/', student_delete, name='student_delete'),
path('face-capture/', face_capture_page, name='face_capture'),
path('api/start-capture/', start_face_capture, name='start_capture'),
path('api/stop-capture/', stop_face_capture, name='stop_capture'),
path('api/capture-status/<str:student_id>/', capture_status, name='capture_status'),
path('api/train-model/', train_model, name='train_model'),
path('api/video-feed/<str:student_id>/', video_feed, name='video_feed'),
path('api/attendance/start/', start_attendance_camera, name='start_attendance'),
path('api/attendance/stop/', stop_attendance_camera, name='stop_attendance'),
path('api/attendance/status/<str:session_id>/', attendance_status, name='attendance_status'),
path('api/attendance/video-feed/<str:session_id>/', attendance_video_feed, name='attendance_video_feed'),
path('api/face-dashboard/stats/', face_dashboard_stats, name='face_dashboard_stats'),
path('api/crowd-report/', crowd_report, name='crowd_report'),
path('api/unknown-faces/', unknown_faces, name='unknown_faces'),
path('api/class-history/', class_attendance_history, name='class_history'),
```

## Important Notes

### Model Separation
- **UserProfile** (related_name='profile') - Used for face recognition attendance
- **StudentProfile** (related_name='student_profile') - Used for student management and approval workflow

These are intentionally kept separate to maintain different workflows.

### Dependencies Required
The face recognition features require these Python packages:
```bash
pip install opencv-python
pip install keras-facenet
pip install scikit-learn
pip install numpy
pip install Pillow
```

### File Structure Dependencies
The face recognition views expect the following structure from AttendanceSystem:
```
AttendanceSystem/
├── recognition_config.py  # Face recognition configuration
├── train.py              # Face recognition model trainer
├── dataset/              # Student face images folder
│   └── REG001/          # Student ID folders
│       └── 1.jpg        # Face images
├── models/              # Trained models folder
│   └── face_model.pkl   # Combined face recognition model
└── media/
    ├── avatars/         # Student profile pictures
    └── unknown_faces/   # Unknown faces detected
```

### Configuration Files Needed
Copy these files from AttendanceSystem to the project root or update paths in `face_recognition_views.py`:
- `recognition_config.py` - Face detection and recognition thresholds
- `train.py` - Face recognition model training script
- `facenet_keras.h5` - Pre-trained FaceNet model

### Database Migrations
After integration, run:
```bash
python manage.py makemigrations
python manage.py migrate
```

### Media Files Configuration
Ensure `settings.py` has:
```python
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
```

## Features Preserved

### From AttendanceTracker (All Preserved):
✅ Worker profile management
✅ Contractor profile management  
✅ Faculty profile management
✅ Student profile management (approval workflow)
✅ Job posting and assignment
✅ Payment tracking
✅ Chat system
✅ Complaint system
✅ Help center management
✅ Feedback system
✅ All existing API endpoints

### From AttendanceSystem (All Added):
✅ Face recognition attendance
✅ Real-time camera-based check-in/check-out
✅ Automated attendance tracking
✅ Unknown person detection
✅ Classroom occupancy monitoring
✅ Student attendance dashboards
✅ Admin attendance dashboards
✅ Attendance analytics and reports
✅ Face capture and model training

## Usage

### For Administrators:
1. Navigate to `/` for the landing page
2. Navigate to `/attendance-dashboard/` for attendance management
3. Use face recognition camera for automated attendance
4. View real-time statistics and reports

### For Students:
1. Sign up at `/signup/` and complete face registration
2. View personal attendance at `/student-dashboard/`
3. Track attendance history and punctuality

### For Face Recognition Setup:
1. Student signs up and provides details
2. Student is redirected to face capture page
3. System captures 50 face images
4. Model is automatically trained
5. Student can now use face recognition for attendance

## API Endpoints Summary

### Face Recognition (New)
- `POST /api/start-capture/` - Start face capture
- `POST /api/stop-capture/` - Stop face capture
- `GET /api/capture-status/<student_id>/` - Get capture status
- `POST /api/train-model/` - Train face recognition model
- `GET /api/video-feed/<student_id>/` - Video stream for capture
- `POST /api/attendance/start/` - Start attendance camera
- `POST /api/attendance/stop/` - Stop attendance camera
- `GET /api/attendance/status/<session_id>/` - Attendance status
- `GET /api/attendance/video-feed/<session_id>/` - Attendance video stream
- `GET /api/face-dashboard/stats/` - Dashboard statistics
- `GET /api/crowd-report/` - Classroom occupancy report
- `GET /api/unknown-faces/` - List unknown faces
- `GET /api/class-history/` - Class attendance history

### Worker/Contractor/Job Management (Preserved)
- All existing API endpoints remain unchanged
- Dashboard stats endpoint: `GET /api/dashboard/stats/`

## Conflict Resolutions

1. **dashboard_stats function**: 
   - Existing function preserved at `/api/dashboard/stats/`
   - New function available at `/api/face-dashboard/stats/`
   
2. **Dashboard URLs**:
   - Worker/Contractor dashboard: Keep existing routes
   - Face recognition dashboard: `/attendance-dashboard/`

## Next Steps

1. Install required Python packages
2. Copy configuration files from AttendanceSystem
3. Run database migrations
4. Configure media file settings
5. Test face registration flow
6. Test attendance camera functionality
7. Verify all existing features still work

## Testing Checklist

- [ ] Face registration workflow
- [ ] Face recognition attendance
- [ ] Student dashboard
- [ ] Admin dashboard
- [ ] Unknown person detection
- [ ] Classroom occupancy reporting
- [ ] Existing worker management features
- [ ] Existing contractor management features
- [ ] Existing job posting features
- [ ] Existing payment features
- [ ] All API endpoints responding correctly

## Conclusion

The integration successfully combines the face recognition attendance system from AttendanceSystem with the comprehensive workforce management system in AttendanceTracker, without removing any existing functionality. Both systems now coexist in a single unified platform.
