from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import FacultyProfile
from django.contrib.auth.models import User

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
