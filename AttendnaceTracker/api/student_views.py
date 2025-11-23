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
