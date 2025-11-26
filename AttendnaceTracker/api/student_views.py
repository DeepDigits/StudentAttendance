from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import StudentProfile

@api_view(['GET'])
def pending_students_list(request):
    """
    Fetches student profiles with 'Pending' approval status.
    """
    pending_students = StudentProfile.objects.filter(approval_status='Pending')

    data = []
    for student in pending_students:
        profile_data = {
            'id': student.id,
            'first_name': student.user.first_name if student.user else '',
            'last_name': student.user.last_name if student.user else '',
            'email': student.user.email if student.user else '',
            'phone': student.phone,
            'roll_number': student.roll_number,
            'department': student.department,
            'year_of_study': student.year_of_study,
            'section': student.section,
            'profile_pic_url': request.build_absolute_uri(student.profile_pic.url) if student.profile_pic else None,
            'approval_status': student.approval_status,
            'created_at': student.user.date_joined.isoformat() if student.user else None,
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['GET'])
def approved_students_list(request):
    """
    Fetches student profiles with 'Approved' approval status.
    """
    approved_students = StudentProfile.objects.filter(approval_status='Approved')

    data = []
    for student in approved_students:
        profile_data = {
            'id': student.id,
            'first_name': student.user.first_name if student.user else '',
            'last_name': student.user.last_name if student.user else '',
            'email': student.user.email if student.user else '',
            'phone': student.phone,
            'roll_number': student.roll_number,
            'department': student.department,
            'year_of_study': student.year_of_study,
            'section': student.section,
            'profile_pic_url': request.build_absolute_uri(student.profile_pic.url) if student.profile_pic else None,
            'approval_status': student.approval_status,
            'created_at': student.user.date_joined.isoformat() if student.user else None,
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['POST'])
def approve_student(request, pk):
    """
    Approves a student request by updating their approval status.
    """
    try:
        student_profile = StudentProfile.objects.get(pk=pk)
        
        # Check if already approved to avoid redundant updates
        if student_profile.approval_status == 'Approved':
            return Response({'message': 'Student is already approved.'}, status=status.HTTP_200_OK)
            
        student_profile.approval_status = 'Approved'
        student_profile.save()
        return Response({'message': 'Student request accepted successfully.'}, status=status.HTTP_200_OK)
    except StudentProfile.DoesNotExist:
        return Response({'error': 'Student profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def reject_student(request, pk):
    """
    Rejects a student request by updating their approval status and storing the reason.
    Expects {'reason': '...'} in the request body (optional).
    """
    try:
        student_profile = StudentProfile.objects.get(pk=pk)
        reason = request.data.get('reason', 'No reason provided')

        # Check if already rejected
        if student_profile.approval_status == 'Rejected':
            return Response({'message': 'Student is already rejected.'}, status=status.HTTP_200_OK)

        student_profile.approval_status = 'Rejected'
        student_profile.rejection_reason = reason
        student_profile.save()
        return Response({'message': 'Student request rejected successfully.'}, status=status.HTTP_200_OK)
    except StudentProfile.DoesNotExist:
        return Response({'error': 'Student profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_student_stats(request, student_id):
    """
    Get attendance statistics for a specific student.
    Returns present days, absent days, total classes, and attendance rate.
    """
    from .models import UserProfile, Attendance
    from datetime import date, timedelta
    from django.db.models import Count, Q
    
    try:
        # Get the UserProfile (face recognition profile) - student_id is passed as int from URL
        # Looking up by user_id since Flutter passes the Django User's ID
        profile = UserProfile.objects.get(user_id=student_id)
        
        # Calculate stats for the current month
        today = date.today()
        first_day_of_month = date(today.year, today.month, 1)
        
        # Get attendance records for current month
        monthly_attendance = Attendance.objects.filter(
            student=profile,
            date__gte=first_day_of_month,
            date__lte=today,
            action='Check-In'  # Only count check-ins
        )
        
        # Count present days (unique dates with check-in)
        present_days = monthly_attendance.values('date').distinct().count()
        
        # Calculate total working days in the month so far (excluding weekends for simplicity)
        total_days = (today - first_day_of_month).days + 1
        # Estimate working days (rough estimate: 5/7 of days)
        estimated_working_days = int(total_days * 5 / 7)
        
        # Absent days = working days - present days
        absent_days = max(0, estimated_working_days - present_days)
        
        # Total classes attended
        total_classes = monthly_attendance.count()
        
        # Attendance rate
        attendance_rate = round((present_days / estimated_working_days * 100), 1) if estimated_working_days > 0 else 0
        
        # Weekly stats (this week)
        week_start = today - timedelta(days=today.weekday())
        weekly_present = Attendance.objects.filter(
            student=profile,
            date__gte=week_start,
            date__lte=today,
            action='Check-In'
        ).values('date').distinct().count()
        
        # Calculate weekly working days and absent days
        days_in_week = (today - week_start).days + 1
        weekly_working_days = min(days_in_week, 5)  # Max 5 working days in a week
        weekly_absent = max(0, weekly_working_days - weekly_present)
        
        # Weekly classes count
        weekly_classes = Attendance.objects.filter(
            student=profile,
            date__gte=week_start,
            date__lte=today,
            action='Check-In'
        ).count()
        
        data = {
            'present_days': present_days,
            'absent_days': absent_days,
            'total_classes': total_classes,
            'attendance_rate': f'{attendance_rate}%',
            'weekly_present': weekly_present,
            'weekly_absent': weekly_absent,
            'weekly_classes': weekly_classes,
            'this_week': weekly_present,
            'this_month': present_days,
        }
        
        return Response(data, status=status.HTTP_200_OK)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'Student profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_student_attendance_logs(request, student_id):
    print(student_id)
    """
    Get attendance log records for a specific student.
    Returns a list of attendance entries with date, status, check-in/out times, etc.
    """
    from .models import UserProfile, Attendance
    from django.utils import timezone
    
    try:
        # Get the UserProfile - student_id is passed as int from URL
        # Looking up by user_id since Flutter passes the Django User's ID
        profile = UserProfile.objects.get(user_id=student_id)
        
        # Get all attendance records, ordered by date (most recent first)
        attendance_records = Attendance.objects.filter(
            student=profile
        ).order_by('-date', '-timestamp')[:50]  # Limit to last 50 records
        print(attendance_records)
        # Group by date and action to create daily summaries
        daily_logs = {}
        for record in attendance_records:
            date_key = record.date.strftime('%Y-%m-%d')
            
            if date_key not in daily_logs:
                # Do not expose faculty/professor names in API responses
                daily_logs[date_key] = {
                    'date': record.date.isoformat(),
                    'status': 'Absent',  # Default
                    'checkIn': '--',
                    'checkOut': '--',
                    'subject': record.class_name,
                    'faculty': '',
                    'confidence': 0.0,
                }
            
            # Update based on action
            if record.action == 'Check-In':
                daily_logs[date_key]['status'] = 'Present' if record.status == 'On-Time' else 'Late'
                daily_logs[date_key]['checkIn'] = record.timestamp.strftime('%I:%M %p')
                daily_logs[date_key]['confidence'] = 98.5  # You can calculate actual confidence if stored
            elif record.action == 'Check-Out':
                daily_logs[date_key]['checkOut'] = record.timestamp.strftime('%I:%M %p')
        
        # Convert to list
        logs_list = list(daily_logs.values())
        
        return Response(logs_list, status=status.HTTP_200_OK)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'Student profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_student_recent_activity(request, student_id):
    """
    Get recent activity for a specific student.
    Returns a list of recent actions like attendance marked, reminders, etc.
    """
    from .models import UserProfile, Attendance
    from django.utils import timezone
    from datetime import timedelta
    
    try:
        # Get the UserProfile - student_id is passed as int from URL
        # Looking up by user_id since Flutter passes the Django User's ID
        profile = UserProfile.objects.get(user_id=student_id)
        
        # Get recent attendance records (last 7 days)
        seven_days_ago = timezone.now() - timedelta(days=7)
        recent_records = Attendance.objects.filter(
            student=profile,
            timestamp__gte=seven_days_ago
        ).order_by('-timestamp')[:10]
        
        activities = []
        
        for record in recent_records:
            # Calculate time ago
            time_diff = timezone.now() - record.timestamp
            if time_diff.days > 0:
                time_ago = f'{time_diff.days} day{"s" if time_diff.days > 1 else ""} ago'
            elif time_diff.seconds >= 3600:
                hours = time_diff.seconds // 3600
                time_ago = f'{hours} hour{"s" if hours > 1 else ""} ago'
            elif time_diff.seconds >= 60:
                minutes = time_diff.seconds // 60
                time_ago = f'{minutes} minute{"s" if minutes > 1 else ""} ago'
            else:
                time_ago = 'Just now'
            
            # Create activity based on record type
            if record.action == 'Check-In':
                activity = {
                    'title': 'Attendance Marked',
                    'description': f'{record.class_name} - {record.status}',
                    'time': time_ago,
                    'icon': 'checkmark_circle',
                    'iconColor': '#2ECC71' if record.status == 'On-Time' else '#F39C12',
                    'type': 'success',
                }
            else:  # Check-Out
                activity = {
                    'title': 'Class Completed',
                    'description': f'{record.class_name}',
                    'time': time_ago,
                    'icon': 'log_out',
                    'iconColor': '#3498DB',
                    'type': 'info',
                }
            
            activities.append(activity)
        
        return Response(activities, status=status.HTTP_200_OK)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'Student profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_student_profile(request, student_id):
    """
    Get student profile information including avatar/profile picture.
    """
    from .models import UserProfile
    from django.contrib.auth.models import User
    
    try:
        # Get the user
        user = User.objects.get(id=student_id)
        
        # Try to get the UserProfile (face recognition profile)
        profile = None
        avatar_url = None
        department = ''
        student_id_number = ''
        phone = ''
        section = ''
        year_of_study = ''
        approval_status = ''
        
        if hasattr(user, 'profile'):
            profile = user.profile
            if profile.avatar:
                avatar_url = request.build_absolute_uri(profile.avatar.url)
            department = profile.department or ''
            student_id_number = profile.student_id or ''
            phone = profile.phone or ''
        
        # Also check StudentProfile if exists (has more detailed info)
        if hasattr(user, 'student_profile'):
            student_profile = user.student_profile
            if not avatar_url and student_profile.profile_pic:
                avatar_url = request.build_absolute_uri(student_profile.profile_pic.url)
            if not department:
                department = student_profile.department or ''
            if not student_id_number:
                student_id_number = student_profile.roll_number or ''
            if not phone:
                phone = student_profile.phone or ''
            section = student_profile.section or ''
            year_of_study = student_profile.year_of_study or ''
            approval_status = student_profile.approval_status or ''
        
        data = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'fullName': f"{user.first_name} {user.last_name}".strip() or user.username,
            'firstName': user.first_name or '',
            'lastName': user.last_name or '',
            'profilePicUrl': avatar_url,
            'department': department,
            'studentId': student_id_number,
            'phone': phone,
            'section': section,
            'yearOfStudy': year_of_study,
            'approvalStatus': approval_status,
            'dateJoined': user.date_joined.isoformat() if user.date_joined else None,
            'lastLogin': user.last_login.isoformat() if user.last_login else None,
            'isActive': user.is_active,
        }
        
        return Response(data, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
