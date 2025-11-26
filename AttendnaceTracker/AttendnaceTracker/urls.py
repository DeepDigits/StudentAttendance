"""
URL configuration for AttendnaceTracker project.

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
from api import views
from django.conf import settings
from django.contrib import admin
from django.urls import path, re_path
from django.conf.urls.static import static
# Import the new view along with existing ones
from api.views import (
    register_user,
    login_user,
    register_worker_api,
    register_contractor_api,
    register_faculty_api,
    register_student_api,
    WorkerProfileList,
    ApprovedWorkerList,
    accept_worker_request,
    reject_worker_request,
    update_worker_details,
    assign_worker_to_job,
    delete_worker_profile,
    dashboard_activity,
    # Import new worker job endpoints
    worker_jobs,
    worker_stats,
    # Import new contractor views
    ContractorProfileList,
    ApprovedContractorList,
    accept_contractor_request,
    reject_contractor_request,
    update_contractor_details,
    delete_contractor_profile,
    # Import job-related views
    get_contractors,
    create_job,
    get_jobs,
    get_user_jobs,
    delete_job,
    get_contractor_payments,  # Add the new payments view
    update_job,
    update_job_status,
    # Import job acceptance/rejection views
    accept_job,
    reject_job,    # Import worker contractors view
    worker_contractors,
    # Import contractor workers view
    contractor_workers,
    # Import face recognition views
    index,
    dashboard as face_dashboard,
    signup,
    user_login,
    user_logout,
    student_update,
    student_delete,
    face_capture_page,
    start_face_capture,
    capture_status,
    stop_face_capture,
    train_model,
    video_feed,
    start_attendance_camera,
    attendance_video_feed,
    attendance_status,
    stop_attendance_camera,
    face_dashboard_stats,
    crowd_report,
    unknown_faces,
    student_dashboard,
    class_attendance_history,
)

# Import the original dashboard_stats separately to avoid conflict


# Import the contractor dashboard specific views
from api.contractor_views import (
    contractor_stats,
    contractor_jobs,
    create_job_with_worker,
)

# Import payment-related views
from api.payment_views import (
    create_payment_record,
    update_payment_status,
    get_worker_jobs,
)

# Import chat views
from api import chat_views

# Import complaint views
from api import complaint_views

# Import help center views
from api import help_center_views

# Import faculty views
from api import faculty_views

# Import student views
from api import student_views
from api import notification_views

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Face Recognition and Attendance URLs (from AttendanceSystem)
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
    
    # Existing AttendanceTracker API URLs
    path('api/register/', register_user, name='register'),
    path('api/register/worker/', register_worker_api, name='register_worker'),
    path('api/register/contractor/', register_contractor_api, name='register_contractor'),
    path('api/register/faculty/', register_faculty_api, name='register_faculty'),
    path('api/register/student/', register_student_api, name='register_student'),
    path('api/login/', login_user, name='login'),
    # Worker URLs
    path('api/workerRequests/', WorkerProfileList, name='worker_requests_list'),
    path('api/workers/approved/', ApprovedWorkerList, name='approved_worker_list'),
    path('api/workers/<int:pk>/update/', update_worker_details, name='update_worker_details'), # New URL for updating
    path('api/workers/<int:pk>/delete/', delete_worker_profile, name='delete_worker_profile'), # New URL for deleting
    path('api/workerRequests/<int:pk>/accept/', accept_worker_request, name='accept_worker_request'),
    path('api/workerRequests/<int:pk>/reject/', reject_worker_request, name='reject_worker_request'),
    # Contractor URLs
    path('api/contractorRequests/', ContractorProfileList, name='contractor_requests_list'), # New
    path('api/contractors/approved/', ApprovedContractorList, name='approved_contractor_list'), # New
    path('api/contractors/<int:pk>/update/', update_contractor_details, name='update_contractor_details'), # New
    path('api/contractors/<int:pk>/delete/', delete_contractor_profile, name='delete_contractor_profile'), # New
    path('api/contractorRequests/<int:pk>/accept/', accept_contractor_request, name='accept_contractor_request'), # New
    path('api/contractorRequests/<int:pk>/reject/', reject_contractor_request, name='reject_contractor_request'), # New
    
    # Faculty URLs
    path('api/faculty/pending/', faculty_views.pending_faculty_list, name='pending_faculty_list'),
    path('api/faculty/approved/', faculty_views.approved_faculty_list, name='approved_faculty_list'),
    path('api/faculty/approve/<int:pk>/', faculty_views.approve_faculty, name='approve_faculty'),
    path('api/faculty/reject/<int:pk>/', faculty_views.reject_faculty, name='reject_faculty'),
    
    # Student URLs
    # Student attendance data endpoints (MUST come before approve/reject patterns to avoid conflicts)
    path('api/student-stats/<int:student_id>/', student_views.get_student_stats, name='get_student_stats'),
    path('api/student-logs/<int:student_id>/', student_views.get_student_attendance_logs, name='get_student_attendance_logs'),
    path('api/student-activity/<int:student_id>/', student_views.get_student_recent_activity, name='get_student_recent_activity'),
    path('api/student-profile/<int:student_id>/', student_views.get_student_profile, name='get_student_profile'),
    
    # Notification URLs
    path('api/notifications/<int:user_id>/', notification_views.get_user_notifications, name='get_user_notifications'),
    path('api/notifications/unread-count/<int:user_id>/', notification_views.get_unread_count, name='get_unread_count'),
    path('api/notifications/mark-read/<int:notification_id>/', notification_views.mark_notification_read, name='mark_notification_read'),
    path('api/notifications/mark-all-read/<int:user_id>/', notification_views.mark_all_notifications_read, name='mark_all_notifications_read'),
    path('api/notifications/delete/<int:notification_id>/', notification_views.delete_notification, name='delete_notification'),
    path('api/notifications/create-reminder/<int:user_id>/', notification_views.create_class_reminder, name='create_class_reminder'),
    
    # Other student endpoints
    path('api/students/pending/', student_views.pending_students_list, name='pending_students_list'),
    path('api/students/approved/', student_views.approved_students_list, name='approved_students_list'),
    path('api/students/approve/<int:pk>/', student_views.approve_student, name='approve_student'),
    path('api/students/reject/<int:pk>/', student_views.reject_student, name='reject_student'),
    
    # Dashboard URL
    # path('api/dashboard/stats/', dashboard_stats, name='dashboard_stats'),  # New URL for dashboard statistics
    path('api/dashboard/activity/', dashboard_activity, name='dashboard_activity'),  # New URL for dashboard activity
    # Job URLs
    path('api/contractors/list/', get_contractors, name='get_contractors'),    
    path('api/jobs/create/', create_job, name='create_job'),
    path('api/jobs/', get_jobs, name='get_jobs'),
    path('api/jobs/user/<int:user_id>/', views.get_user_jobs, name='get_user_jobs'),    
    path('api/jobs/user-posted/<int:user_id>/', views.get_user_posted_jobs, name='get_user_jobs'),    
    path('api/jobs/<int:job_id>/update/', update_job, name='update_job'),    
    path('api/jobs/<int:job_id>/delete/', delete_job, name='delete_job'),  # New URL for deleting jobs
    path('api/jobs/update/<int:job_id>/', update_job, name='update_job'),  # New URL for updating jobs
    path('api/jobs/<int:job_id>/update_job_status/', update_job_status, name='update_job_status'),  # New URL for updating job status
    
    # Contractor dashboard specific endpoints
    path('api/contractor/<int:contractor_id>/stats/', contractor_stats, name='contractor_stats'),
    path('api/contractor/<int:contractor_id>/jobs/', contractor_jobs, name='contractor_jobs'),
    path('api/jobs/create-with-worker/', create_job_with_worker, name='create_job_with_worker'),
      # New endpoint for assigning a worker to a job
    path('api/jobs/<int:job_id>/assign-worker/', assign_worker_to_job, name='assign_worker_to_job'),
    path('api/jobs/<int:job_id>/update-status/', update_job_status, name='update_job_status'),  # New URL for updating job status    # Payment-related endpoints
    path('api/payments/create/', create_payment_record, name='create_payment_record'),    path('api/payments/<int:payment_id>/update/', update_payment_status, name='update_payment_status'),    path('api/workers/<int:worker_id>/jobs/', worker_jobs, name='worker_jobs'),
    path('api/workers/<int:worker_id>/stats/', worker_stats, name='worker_stats'),
    path('api/workers/<int:worker_id>/contractors/', worker_contractors, name='worker_contractors'),
    path('api/contractors/<int:contractor_id>/workers/', contractor_workers, name='contractor_workers'),
    path('api/workers/<int:worker_id>/payments/', views.worker_payments, name='worker_payments'),
    path('csrf/', views.get_csrf_token, name='get_csrf_token'),  # CSRF token endpoint
    # Job acceptance/rejection endpoints
    path('api/jobs/<int:job_id>/accept/', accept_job, name='accept_job'),
    path('api/jobs/<int:job_id>/reject/', reject_job, name='reject_job'),    # Chat endpoints
    path('api/chats/<str:worker_id>/<str:contractor_id>/messages/', chat_views.get_chat_messages, name='chat_messages'),
    path('api/chats/send/', chat_views.send_message, name='send_message'),
    path('api/chats/<str:worker_id>/<str:contractor_id>/read/', chat_views.mark_messages_read, name='mark_messages_read'),    # Complaint endpoints
    path('api/test/', complaint_views.test_endpoint, name='test_endpoint'),
    path('api/complaints/submit', complaint_views.submit_complaint, name='submit_complaint'),
    path('api/complaints/submit/', complaint_views.submit_complaint, name='submit_complaint_slash'),
    path('api/complaints/worker/<int:worker_id>/', complaint_views.get_worker_complaints, name='get_worker_complaints'),    path('api/complaints/types/', complaint_views.get_complaint_types, name='get_complaint_types'),
    path('api/complaints/', complaint_views.get_all_complaints, name='get_all_complaints'),  # New endpoint for getting all complaints
    path('api/complaints/<int:complaint_id>/update-status/', complaint_views.update_complaint_status, name='update_complaint_status'),  # New endpoint for updating complaint status
    # User job management endpoints
    path('api/jobs/user/<int:job_id>/edit/', views.edit_user_job, name='edit_user_job'),
    path('api/jobs/user/<int:job_id>/delete/', views.delete_user_job, name='delete_user_job'),

    path('api/users/<int:user_id>/stats/', views.get_user_stats, name='get_user_stats'),
    
    # Add new endpoint for contractor payments
    path('api/contractor/<int:contractor_id>/payments/', views.get_contractor_payments, name='contractor_payments'),    # Feedback endpoints
    path('api/users/<int:user_id>/assigned-workers/', views.get_user_assigned_workers, name='get_user_assigned_workers'),
    path('api/feedback/submit/', views.submit_worker_feedback, name='submit_worker_feedback'),
    path('api/workers/<int:worker_id>/feedback/', views.get_worker_feedback, name='get_worker_feedback'),    # Contractor feedback endpoints
    path('api/contractor-feedback/submit/', views.submit_contractor_feedback, name='submit_contractor_feedback'),
    path('api/contractors/<int:contractor_id>/feedback/', views.get_contractor_feedback, name='get_contractor_feedback'),
    path('api/contractor-feedback/check/<int:contractor_id>/<int:job_id>/<int:worker_id>/', views.check_contractor_rating_exists, name='check_contractor_rating_exists'),
    path('api/workers/<int:worker_id>/completed-jobs/', views.get_worker_completed_jobs_with_contractors, name='get_worker_completed_jobs'),
    
    # Help Center endpoints
    path('api/divisions/', help_center_views.get_divisions, name='get_divisions'),
    path('api/divisions/create/', help_center_views.create_division, name='create_division'),
    path('api/divisions/<int:division_id>/update/', help_center_views.update_division, name='update_division'),
    path('api/divisions/<int:division_id>/delete/', help_center_views.delete_division, name='delete_division'),
    path('api/help-centers/', help_center_views.get_help_centers, name='get_help_centers'),
    path('api/help-centers/create/', help_center_views.create_help_center, name='create_help_center'),
    path('api/help-centers/<int:help_center_id>/', help_center_views.help_center_detail, name='help_center_detail'),

]

# Add media URL pattern for development server
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
