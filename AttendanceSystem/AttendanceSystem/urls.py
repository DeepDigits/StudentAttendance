"""
URL configuration for AttendanceSystem project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from App import views as app_views
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('', app_views.index, name='index'),
    path('dashboard/', app_views.dashboard, name='dashboard'),
    path('student-dashboard/', app_views.student_dashboard, name='student_dashboard'),
    path('signup/', app_views.signup, name='signup'),
    path('login/', app_views.user_login, name='login'),
    path('logout/', app_views.user_logout, name='logout'),
    path('students/<int:pk>/update/', app_views.student_update, name='student_update'),
    path('students/<int:pk>/delete/', app_views.student_delete, name='student_delete'),
    path('face-capture/', app_views.face_capture_page, name='face_capture'),
    path('api/start-capture/', app_views.start_face_capture, name='start_capture'),
    path('api/stop-capture/', app_views.stop_face_capture, name='stop_capture'),
    path('api/capture-status/<str:student_id>/', app_views.capture_status, name='capture_status'),
    path('api/train-model/', app_views.train_model, name='train_model'),
    path('api/video-feed/<str:student_id>/', app_views.video_feed, name='video_feed'),
    path('api/attendance/start/', app_views.start_attendance_camera, name='start_attendance'),
    path('api/attendance/stop/', app_views.stop_attendance_camera, name='stop_attendance'),
    path('api/attendance/status/<str:session_id>/', app_views.attendance_status, name='attendance_status'),
    path('api/attendance/video-feed/<str:session_id>/', app_views.attendance_video_feed, name='attendance_video_feed'),
    path('api/dashboard/stats/', app_views.dashboard_stats, name='dashboard_stats'),
    path('api/crowd-report/', app_views.crowd_report, name='crowd_report'),
    path('api/unknown-faces/', app_views.unknown_faces, name='unknown_faces'),
    path('api/class-history/', app_views.class_attendance_history, name='class_history'),
    path('admin/', admin.site.urls),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
