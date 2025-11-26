from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import FacultyProfile, StudentProfile, Attendance, Notification, UserProfile
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import datetime

@api_view(['GET'])
def get_all_faculty(request):
    """
    Fetches all faculty profiles for dashboard display.
    """
    all_faculty = FacultyProfile.objects.select_related('user').all().order_by('-user__date_joined')

    data = []
    for faculty in all_faculty:
        profile_data = {
            'id': faculty.id,
            'first_name': faculty.user.first_name if faculty.user else '',
            'last_name': faculty.user.last_name if faculty.user else '',
            'email': faculty.user.email if faculty.user else '',
            'phone': faculty.phone,
            'employee_id': faculty.employee_id,
            'department': faculty.department,
            'qualifications': faculty.qualifications,
            'profile_pic_url': request.build_absolute_uri(faculty.profile_pic.url) if faculty.profile_pic else None,
            'approval_status': faculty.approval_status,
            'created_at': faculty.user.date_joined.isoformat() if faculty.user else None,
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['GET'])
def get_faculty_detail(request, pk):
    """
    Fetches a single faculty profile by pk.
    """
    try:
        faculty = FacultyProfile.objects.select_related('user').get(pk=pk)
        data = {
            'id': faculty.id,
            'first_name': faculty.user.first_name if faculty.user else '',
            'last_name': faculty.user.last_name if faculty.user else '',
            'email': faculty.user.email if faculty.user else '',
            'phone': faculty.phone,
            'employee_id': faculty.employee_id,
            'department': faculty.department,
            'qualifications': faculty.qualifications,
            'profile_pic_url': request.build_absolute_uri(faculty.profile_pic.url) if faculty.profile_pic else None,
            'approval_status': faculty.approval_status,
            'created_at': faculty.user.date_joined.isoformat() if faculty.user else None,
        }
        return Response(data, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
def update_faculty(request, pk):
    """
    Updates a faculty profile.
    Accepts fields: first_name, last_name, email, phone, employee_id, department, qualifications
    """
    try:
        faculty = FacultyProfile.objects.select_related('user').get(pk=pk)
        user = faculty.user

        # Update user fields
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
        if 'email' in request.data:
            user.email = request.data['email']
        user.save()

        # Update faculty profile fields
        if 'phone' in request.data:
            faculty.phone = request.data['phone']
        if 'employee_id' in request.data:
            faculty.employee_id = request.data['employee_id']
        if 'department' in request.data:
            faculty.department = request.data['department']
        if 'qualifications' in request.data:
            faculty.qualifications = request.data['qualifications']
        faculty.save()

        return Response({
            'message': 'Faculty updated successfully.',
            'faculty': {
                'id': faculty.id,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'name': f"{user.first_name} {user.last_name}".strip() or user.username,
                'email': user.email,
                'phone': faculty.phone,
                'employee_id': faculty.employee_id,
                'department': faculty.department,
                'qualifications': faculty.qualifications,
                'approval_status': faculty.approval_status,
            }
        }, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
def delete_faculty(request, pk):
    """
    Deletes a faculty profile and their user account.
    """
    try:
        faculty = FacultyProfile.objects.select_related('user').get(pk=pk)
        user = faculty.user
        
        # Delete the faculty profile (cascade will handle it if set, but explicit is better)
        faculty.delete()
        
        # Also delete the user account
        if user:
            user.delete()
        
        return Response({'message': 'Faculty deleted successfully.'}, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def pending_faculty_list(request):
    """
    Fetches faculty profiles with 'Pending' approval status.
    """
    pending_faculty = FacultyProfile.objects.filter(approval_status='Pending')

    data = []
    for faculty in pending_faculty:
        profile_data = {
            'id': faculty.id,
            'first_name': faculty.user.first_name if faculty.user else '',
            'last_name': faculty.user.last_name if faculty.user else '',
            'email': faculty.user.email if faculty.user else '',
            'phone': faculty.phone,
            'employee_id': faculty.employee_id,
            'department': faculty.department,
            'qualifications': faculty.qualifications,
            'profile_pic_url': request.build_absolute_uri(faculty.profile_pic.url) if faculty.profile_pic else None,
            'approval_status': faculty.approval_status,
            'created_at': faculty.user.date_joined.isoformat() if faculty.user else None,
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['GET'])
def approved_faculty_list(request):
    """
    Fetches faculty profiles with 'Approved' approval status.
    """
    approved_faculty = FacultyProfile.objects.filter(approval_status='Approved')

    data = []
    for faculty in approved_faculty:
        profile_data = {
            'id': faculty.id,
            'first_name': faculty.user.first_name if faculty.user else '',
            'last_name': faculty.user.last_name if faculty.user else '',
            'email': faculty.user.email if faculty.user else '',
            'phone': faculty.phone,
            'employee_id': faculty.employee_id,
            'department': faculty.department,
            'qualifications': faculty.qualifications,
            'profile_pic_url': request.build_absolute_uri(faculty.profile_pic.url) if faculty.profile_pic else None,
            'approval_status': faculty.approval_status,
            'created_at': faculty.user.date_joined.isoformat() if faculty.user else None,
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['POST'])
def approve_faculty(request, pk):
    """
    Approves a faculty request by updating their approval status.
    """
    try:
        faculty_profile = FacultyProfile.objects.get(pk=pk)
        
        # Check if already approved to avoid redundant updates
        if faculty_profile.approval_status == 'Approved':
            return Response({'message': 'Faculty is already approved.'}, status=status.HTTP_200_OK)
            
        faculty_profile.approval_status = 'Approved'
        faculty_profile.save()
        return Response({'message': 'Faculty request accepted successfully.'}, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def reject_faculty(request, pk):
    """
    Rejects a faculty request by updating their approval status and storing the reason.
    Expects {'reason': '...'} in the request body (optional).
    """
    try:
        faculty_profile = FacultyProfile.objects.get(pk=pk)
        reason = request.data.get('reason', 'No reason provided')

        # Check if already rejected
        if faculty_profile.approval_status == 'Rejected':
            return Response({'message': 'Faculty is already rejected.'}, status=status.HTTP_200_OK)

        faculty_profile.approval_status = 'Rejected'
        faculty_profile.rejection_reason = reason
        faculty_profile.save()
        return Response({'message': 'Faculty request rejected successfully.'}, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ====================== FACULTY DASHBOARD APIs ======================

@api_view(['GET'])
def get_faculty_students(request, pk):
    """
    Fetches all students in the same department as the faculty.
    Uses UserProfile model which has the actual student data.
    pk: Faculty profile ID
    """
    try:
        faculty = FacultyProfile.objects.get(pk=pk)
        department = faculty.department
        
        # Get students from UserProfile model filtered by department
        students = UserProfile.objects.filter(
            department__iexact=department
        ).select_related('user')
        
        data = []
        for student in students:
            student_data = {
                'id': student.id,
                'user_id': student.user.id if student.user else None,
                'first_name': student.user.first_name if student.user else '',
                'last_name': student.user.last_name if student.user else '',
                'email': student.user.email if student.user else '',
                'roll_number': student.student_id,  # student_id in UserProfile
                'department': student.department,
                'year_of_study': 'N/A',  # Not in UserProfile
                'section': 'N/A',  # Not in UserProfile
                'phone': student.phone or 'N/A',
                'profile_pic': request.build_absolute_uri(student.avatar.url) if student.avatar else None,
            }
            data.append(student_data)
        
        return Response(data, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_department_students(request):
    """
    Fetches students filtered by department query parameter.
    Uses UserProfile model which has the actual student data.
    Query params: department
    """
    department = request.GET.get('department', '')
    print(" Department:", department)
    
    if not department:
        return Response({'error': 'Department parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Get students from UserProfile model filtered by department
        students = UserProfile.objects.filter(
            department__iexact=department
        ).select_related('user')
        
        data = []
        for student in students:
            student_data = {
                'id': student.id,
                'user_id': student.user.id if student.user else None,
                'first_name': student.user.first_name if student.user else '',
                'last_name': student.user.last_name if student.user else '',
                'email': student.user.email if student.user else '',
                'roll_number': student.student_id,  # student_id in UserProfile
                'department': student.department,
                'year_of_study': 'N/A',  # Not in UserProfile
                'section': 'N/A',  # Not in UserProfile
                'phone': student.phone or 'N/A',
                'profile_pic': request.build_absolute_uri(student.avatar.url) if student.avatar else None,
            }
            data.append(student_data)
        
        return Response(data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_department_attendance(request):
    """
    Fetches attendance records for students in a department on a specific date.
    Query params: department, date (YYYY-MM-DD), student_id (optional)
    """
    department = request.GET.get('department', '')
    date_str = request.GET.get('date', '')
    student_id = request.GET.get('student_id', None)
    print(" Department:", department)
    print(" Date:", date_str)
    print(" Student ID:", student_id)
    
    if not department:
        return Response({'error': 'Department parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Parse date or use today
        if date_str:
            try:
                target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                target_date = timezone.now().date()
        else:
            target_date = timezone.now().date()
        
        # Get students in the department from UserProfile (this is what Attendance links to)
        students = UserProfile.objects.filter(
            department__iexact=department
        ).select_related('user')
        
        # If specific student is requested
        if student_id:
            students = students.filter(id=student_id)
        
        data = []
        for student in students:
            student_name = f"{student.user.first_name} {student.user.last_name}".strip() if student.user else 'Unknown'
            if not student_name or student_name == '':
                student_name = student.user.username if student.user else 'Unknown'
            
            attendance_record = {
                'student_id': student.id,
                'student_name': student_name,
                'roll_number': student.student_id,  # UserProfile uses student_id as roll number
                'email': student.user.email if student.user else '',
                'profile_pic': request.build_absolute_uri(student.avatar.url) if student.avatar else None,
                'status': 'absent',  # Default
                'check_in_time': None,
                'check_out_time': None,
            }
            
            # Check attendance for this student on the target date
            attendance = Attendance.objects.filter(
                student=student,
                date=target_date
            ).order_by('-timestamp').first()
            
            if attendance:
                if attendance.status in ['On-Time', 'present']:
                    attendance_record['status'] = 'present'
                elif attendance.status == 'Late':
                    attendance_record['status'] = 'late'
                else:
                    attendance_record['status'] = attendance.status.lower()
                
                # Get check-in time
                if attendance.action == 'Check-In' and attendance.timestamp:
                    attendance_record['check_in_time'] = attendance.timestamp.strftime('%I:%M %p')
                if attendance.check_in_time:
                    attendance_record['check_in_time'] = attendance.check_in_time.strftime('%I:%M %p')
                
                # Get check-out time
                if attendance.check_out_time:
                    attendance_record['check_out_time'] = attendance.check_out_time.strftime('%I:%M %p')
                
                # Also check for a separate check-out record
                checkout = Attendance.objects.filter(
                    student=student,
                    date=target_date,
                    action='Check-Out'
                ).order_by('-timestamp').first()
                if checkout and checkout.timestamp:
                    attendance_record['check_out_time'] = checkout.timestamp.strftime('%I:%M %p')
            
            data.append(attendance_record)
        
        return Response(data, status=status.HTTP_200_OK)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def send_notification_to_students(request):
    """
    Sends a notification to selected students.
    Request body: {
        'faculty_id': id,
        'title': str,
        'message': str,
        'student_ids': [id1, id2, ...]
    }
    """
    faculty_id = request.data.get('faculty_id')
    title = request.data.get('title', '').strip()
    message = request.data.get('message', '').strip()
    student_ids = request.data.get('student_ids', [])
    
    if not title:
        return Response({'error': 'Title is required.'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not message:
        return Response({'error': 'Message is required.'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not student_ids or len(student_ids) == 0:
        return Response({'error': 'At least one student must be selected.'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Get faculty info for sender name
        faculty = None
        faculty_name = 'Faculty'
        if faculty_id:
            try:
                faculty = FacultyProfile.objects.get(pk=faculty_id)
                faculty_name = f"{faculty.user.first_name} {faculty.user.last_name}".strip() or faculty.user.username
            except FacultyProfile.DoesNotExist:
                pass
        
        # Get students and create notifications
        students = UserProfile.objects.filter(id__in=student_ids).select_related('user')
        notifications_created = 0
        
        for student in students:
            if student.user:
                Notification.objects.create(
                    user=student.user,
                    title=title,
                    description=f"From {faculty_name}: {message}",
                    notification_type='info',
                    icon='mail',
                    icon_color='#3498DB',
                )
                notifications_created += 1
        
        return Response({
            'message': f'Notification sent to {notifications_created} student(s).',
            'recipients_count': notifications_created,
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_faculty_sent_notifications(request, pk):
    """
    Fetches notifications sent by a faculty (to students in their department).
    This is a placeholder - in a full implementation, you'd track which faculty sent which notification.
    For now, we return recent notifications to students in the faculty's department.
    pk: Faculty profile ID
    """
    try:
        faculty = FacultyProfile.objects.get(pk=pk)
        department = faculty.department
        
        # Get students in the department
        students = UserProfile.objects.filter(
            department__iexact=department,
            # approval_status='Approved'
        ).select_related('user')
        
        student_user_ids = [s.user.id for s in students if s.user]
        
        # Get recent notifications sent to these students (info type with 'From' in description)
        notifications = Notification.objects.filter(
            user_id__in=student_user_ids,
            notification_type='info',
            description__startswith='From'
        ).order_by('-created_at')[:50]
        
        data = []
        for notif in notifications:
            # Find recipient student name
            recipient_name = 'Unknown'
            for student in students:
                if student.user and student.user.id == notif.user_id:
                    recipient_name = f"{student.user.first_name} {student.user.last_name}".strip() or student.user.username
                    break
            
            notif_data = {
                'id': notif.id,
                'title': notif.title,
                'message': notif.description.replace(f'From {faculty.user.first_name} {faculty.user.last_name}: ', '').replace(f'From {faculty.user.username}: ', ''),
                'created_at': notif.created_at.isoformat(),
                'recipients_count': 1,
                'recipients': [{'name': recipient_name}],
            }
            data.append(notif_data)
        
        # Group notifications by title and created_at (within 1 minute) to combine recipients
        grouped = {}
        for notif in data:
            key = f"{notif['title']}_{notif['created_at'][:16]}"  # Group by title and minute
            if key not in grouped:
                grouped[key] = notif
            else:
                grouped[key]['recipients_count'] += 1
                grouped[key]['recipients'].extend(notif['recipients'])
        
        return Response(list(grouped.values()), status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_faculty_dashboard_stats(request, pk):
    """
    Fetches dashboard statistics for a faculty member.
    Returns: total_students, present_today, absent_today, attendance_rate, recent_activity
    Uses UserProfile model for student data.
    pk: Faculty profile ID
    """
    try:
        faculty = FacultyProfile.objects.get(pk=pk)
        print(faculty)
        department = faculty.department
        print(department)
        today = timezone.now().date()
        
        # Get students from UserProfile model filtered by department
        students = UserProfile.objects.filter(
            department__iexact=department
        ).select_related('user')
        print(students)
        total_students = students.count()
        
        # Count attendance for today
        present_today = 0
        absent_today = 0
        
        for student in students:
            # Check if there's attendance for today
            attendance = Attendance.objects.filter(
                student=student,
                date=today
            ).first()
            
            if attendance and attendance.status in ['On-Time', 'present', 'Present', 'Late']:
                present_today += 1
            else:
                absent_today += 1
        
        # Calculate attendance rate
        attendance_rate = 0
        if total_students > 0:
            attendance_rate = round((present_today / total_students) * 100, 1)
        
        # Get recent activity (last 10 attendance records for students in this department)
        student_ids = [s.id for s in students]
        recent_attendances = Attendance.objects.filter(
            student_id__in=student_ids
        ).select_related('student', 'student__user').order_by('-timestamp')[:10]
        
        recent_activity = []
        for att in recent_attendances:
            student_name = ''
            if att.student and att.student.user:
                student_name = f"{att.student.user.first_name} {att.student.user.last_name}".strip()
                if not student_name:
                    student_name = att.student.user.username
            
            recent_activity.append({
                'student_name': student_name or 'Unknown Student',
                'action': f"{att.action} - {att.status}",
                'time': att.timestamp.strftime('%I:%M %p') if att.timestamp else '',
                'date': att.date.strftime('%b %d') if att.date else '',
                'roll_number': att.student.student_id if att.student else '',
            })
        
        print(f"attendance_rate: {attendance_rate}, total_students: {total_students}")
        return Response({
            'total_students': total_students,
            'present_today': present_today,
            'absent_today': absent_today,
            'attendance_rate': attendance_rate,
            'recent_activity': recent_activity,
        }, status=status.HTTP_200_OK)
    except FacultyProfile.DoesNotExist:
        return Response({'error': 'Faculty profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)