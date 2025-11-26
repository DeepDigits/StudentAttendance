from django.db import IntegrityError
from django.contrib.auth import authenticate
from django.http import JsonResponse
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.models import User
from datetime import datetime
from .models import * # Make sure WorkerProfile is imported
from .models import WorkerFeedback, ContractorFeedback

# Import all face recognition views
from .face_recognition_views import (
    index, dashboard, signup, user_login, user_logout,
    student_update, student_delete, face_capture_page,
    start_face_capture, capture_status, stop_face_capture,
    train_model, video_feed, start_attendance_camera,
    attendance_video_feed, attendance_status, stop_attendance_camera,
    dashboard_stats as face_dashboard_stats, crowd_report, unknown_faces,
    student_dashboard, class_attendance_history
)

def get_csrf_token(request):
    """
    Returns the CSRF token for the current session.
    """
    csrf_token = request.META.get('CSRF_COOKIE')
    return JsonResponse({'csrfToken': csrf_token})

@api_view(['POST'])
def register_user(request):
    try:
        data = request.data
        user = User.objects.create_user(
            username=data['email'],
            email=data['email'],
            password=data['password'],
            first_name=data['fullName']
        )
        return Response({'message': 'User created successfully'}, status=status.HTTP_201_CREATED)
    except IntegrityError:
        return Response(
            {'error': 'An account with this email already exists'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def register_worker_api(request):
    """
    Registers a new worker user along with their profile details.
    Expects multipart/form-data.
    """
    try:
        # Access form data using request.POST
        first_name = request.POST.get('first_name')
        last_name = request.POST.get('last_name')
        email = request.POST.get('email')
        password = request.POST.get('password')
        phone = request.POST.get('phone')
        adhaar = request.POST.get('adhaar')
        address = request.POST.get('address')
        district = request.POST.get('district')
        skills = request.POST.get('skills', '') # Use default empty string
        experience = request.POST.get('experience', '') # Use default empty string
        hourly_rate_str = request.POST.get('hourly_rate')

        # Access uploaded file using request.FILES
        profile_pic_file = request.FILES.get('profile_pic') # Matches the key used in Flutter MultipartFile

        # Basic validation for required text fields
        required_fields = [first_name, last_name, email, password, phone, adhaar, address, district, hourly_rate_str]
        if not all(required_fields):
            return Response({'error': 'Missing required fields'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if user/worker already exists
        if User.objects.filter(email=email).exists() or User.objects.filter(username=email).exists():
            return Response({'error': 'Email already registered'}, status=status.HTTP_400_BAD_REQUEST)
        if WorkerProfile.objects.filter(phone=phone).exists():
             return Response({'error': 'Phone number already registered'}, status=status.HTTP_400_BAD_REQUEST)
        if WorkerProfile.objects.filter(adhaar=adhaar).exists():
             return Response({'error': 'Aadhaar number already registered'}, status=status.HTTP_400_BAD_REQUEST)

        # Create base user
        user = User.objects.create_user(username=email, email=email, password=password)
        user.first_name = first_name
        user.last_name = last_name
        user.save()

        # Create worker profile
        try:
            rate = float(hourly_rate_str) if hourly_rate_str else None
        except ValueError:
            user.delete() # Simple rollback if rate conversion fails
            return Response({'error': 'Invalid hourly rate format'}, status=status.HTTP_400_BAD_REQUEST)

        worker = WorkerProfile.objects.create(
            user=user,
            phone=phone,
            adhaar=adhaar,
            address=address,
            district=district,
            skills=skills,
            experience=experience,
            hourly_rate=rate,
            profile_pic=profile_pic_file # Assign the uploaded file directly
        )

        return Response({'message': 'Worker registered successfully'}, status=status.HTTP_201_CREATED)

    except IntegrityError as e:
         # This might catch unique constraint violations if not caught earlier
         # Attempt to clean up the created user if the profile creation failed
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
            user.delete()
        return Response(
            {'error': f'Database integrity error: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        # Attempt to clean up the created user if something else went wrong
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
             user.delete()
        return Response({'error': f'An unexpected error occurred: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser]) # Handle multipart form data
def register_contractor_api(request):
    """
    Registers a new contractor user along with their profile details.
    Expects multipart/form-data.
    """
    try:
        # Access form data using request.POST
        name = request.POST.get('name')
        email = request.POST.get('email')
        password = request.POST.get('password')
        address = request.POST.get('address')
        district = request.POST.get('district')
        city = request.POST.get('city')
        division = request.POST.get('division')
        pincode = request.POST.get('pincode')
        phone = request.POST.get('phone')
        license_no = request.POST.get('license_no')

        # Access uploaded file using request.FILES
        profile_pic_file = request.FILES.get('profile_pic')

        # Basic validation for required text fields
        required_fields = [name, email, password, address, district, city, division, pincode, phone, license_no]
        if not all(required_fields):
            # You could be more specific about which field is missing
            missing = [f for f, v in zip(['name', 'email', 'password', 'address', 'district', 'city', 'division', 'pincode', 'phone', 'license_no'], required_fields) if not v]
            return Response({'error': f'Missing required fields: {", ".join(missing)}'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if user/contractor already exists
        if User.objects.filter(email=email).exists() or User.objects.filter(username=email).exists():
            return Response({'error': 'Email already registered'}, status=status.HTTP_400_BAD_REQUEST)
        if ContractorProfile.objects.filter(phone=phone).exists():
             return Response({'error': 'Phone number already registered'}, status=status.HTTP_400_BAD_REQUEST)
        if ContractorProfile.objects.filter(license_no=license_no).exists():
             return Response({'error': 'License number already registered'}, status=status.HTTP_400_BAD_REQUEST)

        # Create base user
        # Use email as username for consistency
        user = User.objects.create_user(username=email, email=email, password=password)
        # Split name into first and potentially last name if needed, or store full name in first_name
        user.first_name = name # Store full name in first_name field
        user.save()

        # Create contractor profile
        contractor = ContractorProfile.objects.create(
            user=user,
            address=address,
            district=district,
            city=city,
            division=division,
            pincode=pincode,
            phone=phone,
            license_no=license_no,
            profile_pic=profile_pic_file # Assign the uploaded file directly
        )

        return Response({'message': 'Contractor registered successfully'}, status=status.HTTP_201_CREATED)

    except IntegrityError as e:
         # Attempt to clean up the created user if the profile creation failed
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
            user.delete()
        # Provide more specific error based on constraint violation if possible
        error_msg = f'Database integrity error: {str(e)}'
        if 'phone' in str(e): error_msg = 'Phone number already registered.'
        if 'license_no' in str(e): error_msg = 'License number already registered.'
        return Response(
            {'error': error_msg},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        # Attempt to clean up the created user if something else went wrong
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
             user.delete()
        print(f"Unexpected error during contractor registration: {str(e)}") # Log error
        return Response({'error': f'An unexpected error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def register_faculty_api(request):
    """
    Registers a new faculty user along with their profile details.
    Expects multipart/form-data.
    """
    try:
        # Access form data using request.POST
        name = request.POST.get('name')
        email = request.POST.get('email')
        password = request.POST.get('password')
        employee_id = request.POST.get('employee_id')
        department = request.POST.get('department')
        phone = request.POST.get('phone')
        qualifications = request.POST.get('qualifications')

        # Access uploaded file using request.FILES
        profile_pic_file = request.FILES.get('profile_pic')

        # Basic validation for required text fields
        required_fields = [name, email, password, employee_id, department, phone, qualifications]
        if not all(required_fields):
            missing = [f for f, v in zip(['name', 'email', 'password', 'employee_id', 'department', 'phone', 'qualifications'], required_fields) if not v]
            return Response({'error': f'Missing required fields: {", ".join(missing)}'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if user/faculty already exists
        if User.objects.filter(email=email).exists() or User.objects.filter(username=email).exists():
            return Response({'error': 'Email already registered'}, status=status.HTTP_400_BAD_REQUEST)
        if FacultyProfile.objects.filter(phone=phone).exists():
            return Response({'error': 'Phone number already registered'}, status=status.HTTP_400_BAD_REQUEST)
        if FacultyProfile.objects.filter(employee_id=employee_id).exists():
            return Response({'error': 'Employee ID already registered'}, status=status.HTTP_400_BAD_REQUEST)

        # Create base user
        user = User.objects.create_user(username=email, email=email, password=password)
        user.first_name = name
        user.save()

        # Create faculty profile
        faculty = FacultyProfile.objects.create(
            user=user,
            employee_id=employee_id,
            department=department,
            phone=phone,
            qualifications=qualifications,
            profile_pic=profile_pic_file
        )

        return Response({'message': 'Faculty registered successfully'}, status=status.HTTP_201_CREATED)

    except IntegrityError as e:
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
            user.delete()
        error_msg = f'Database integrity error: {str(e)}'
        if 'phone' in str(e): error_msg = 'Phone number already registered.'
        if 'employee_id' in str(e): error_msg = 'Employee ID already registered.'
        return Response({'error': error_msg}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
            user.delete()
        print(f"Unexpected error during faculty registration: {str(e)}")
        return Response({'error': f'An unexpected error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def register_student_api(request):
    """
    Registers a new student user along with their profile details.
    Expects JSON data with student information.
    """
    try:
        # Access JSON data
        data = request.data
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        email = data.get('email')
        password = data.get('password')
        roll_number = data.get('roll_number')
        department = data.get('department')
        year_of_study = data.get('year_of_study')
        section = data.get('section')
        phone = data.get('phone')

        # Basic validation for required fields
        required_fields = {
            'first_name': first_name,
            'last_name': last_name,
            'email': email,
            'password': password,
            'roll_number': roll_number,
            'department': department,
            'year_of_study': year_of_study
        }
        
        missing_fields = [field for field, value in required_fields.items() if not value]
        if missing_fields:
            return Response(
                {'error': f'Missing required fields: {", ".join(missing_fields)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user/student already exists
        if User.objects.filter(email=email).exists() or User.objects.filter(username=email).exists():
            return Response({'error': 'Email already registered'}, status=status.HTTP_400_BAD_REQUEST)
        
        if StudentProfile.objects.filter(roll_number=roll_number).exists():
            return Response({'error': 'Roll number already registered'}, status=status.HTTP_400_BAD_REQUEST)
        
        if phone and StudentProfile.objects.filter(phone=phone).exists():
            return Response({'error': 'Phone number already registered'}, status=status.HTTP_400_BAD_REQUEST)

        # Create base user
        user = User.objects.create_user(username=email, email=email, password=password)
        user.first_name = first_name
        user.last_name = last_name
        user.save()

        # Create student profile with Pending status
        student = StudentProfile.objects.create(
            user=user,
            roll_number=roll_number,
            department=department,
            year_of_study=year_of_study,
            section=section,
            phone=phone,
            approval_status='Pending'  # Set to pending by default
        )

        return Response(
            {'message': 'Student registered successfully. Your account is pending approval.'}, 
            status=status.HTTP_201_CREATED
        )

    except IntegrityError as e:
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
            user.delete()
        error_msg = f'Database integrity error: {str(e)}'
        if 'phone' in str(e):
            error_msg = 'Phone number already registered.'
        if 'roll_number' in str(e):
            error_msg = 'Roll number already registered.'
        return Response({'error': error_msg}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        if 'user' in locals() and User.objects.filter(pk=user.pk).exists():
            user.delete()
        print(f"Unexpected error during student registration: {str(e)}")
        return Response(
            {'error': f'An unexpected error occurred: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def login_user(request):
    try:
        data = request.data
        user = authenticate(username=data['email'], password=data['password'])
        print(f"Attempting login for: {data.get('email')}") # Log email
        
        if user is not None:
            print(f"Authentication successful for user: {user.username}") # Log success
            user_type = 'user' # Default type
            profile_id = None
            department = None
            
            if user.is_superuser:
                user_type = 'admin'
                print(f"User {user.username} identified as admin.") # Log admin
            elif hasattr(user, 'faculty_profile'):
                user_type = 'faculty'
                profile_id = user.faculty_profile.id
                department = user.faculty_profile.department
                print(f"User {user.username} identified as faculty.") # Log faculty
            elif hasattr(user, 'student_profile'):
                user_type = 'student'
                profile_id = user.student_profile.id
                department = user.student_profile.department
                print(f"User {user.username} identified as student.") # Log student
            elif hasattr(user, 'worker_profile'):
                user_type = 'worker'
                profile_id = user.worker_profile.id
                print(f"User {user.username} identified as worker.") # Log worker
            elif hasattr(user, 'contractor_profile'):
                user_type = 'contractor'
                profile_id = user.contractor_profile.id
                print(f"User {user.username} identified as contractor.") # Log contractor
            else:
                print(f"User {user.username} identified as regular user.") # Log regular user
                
            return Response({
                'message': 'Login successful',
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'fullName': user.first_name or user.username, # Use username as fallback
                    'isAdmin': user.is_superuser, # Keep isAdmin for potential direct checks
                    'userType': user_type, # Add the determined user type
                    'profileId': profile_id, # Profile ID for faculty/student
                    'department': department, # Department for faculty/student
                }
            }, status=status.HTTP_200_OK)
        else:
            print(f"Authentication failed for: {data.get('email')}") # Log failure
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
            
    except Exception as e:
        print(f"Error during login for {data.get('email', 'unknown')}: {str(e)}") # Log exception
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

# --- Worker Views ---
@api_view(['GET'])
def WorkerProfileList(request):
    """
    Fetches worker profiles with 'Pending' approval status.
    """
    # Fetch only pending workers
    pending_workers = WorkerProfile.objects.filter(approval_status='Pending')

    # Manually construct the response data
    data = []
    for worker in pending_workers:
        profile_data = {
            'id': worker.id,
            'first_name': worker.user.first_name if worker.user else '',
            'last_name': worker.user.last_name if worker.user else '',
            'email': worker.user.email if worker.user else '',
            'phone': worker.phone,
            'address': worker.address,
            'adhaar': worker.adhaar,
            # Construct full URL for profile picture
            'profile_pic_url': request.build_absolute_uri(worker.profile_pic.url) if worker.profile_pic else None,
            'approval_status': worker.approval_status,
            'created_at': worker.user.date_joined if worker.user else None, # Assuming you want user creation time
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['GET'])
def ApprovedWorkerList(request):
    """
    Fetches worker profiles with 'Approved' approval status.
    """
    # Fetch only approved workers
    approved_workers = WorkerProfile.objects.filter(approval_status='Approved')

    # Manually construct the response data (similar to WorkerProfileList)
    data = []
    for worker in approved_workers:
        profile_data = {
            'id': worker.id,
            'first_name': worker.user.first_name if worker.user else '',
            'last_name': worker.user.last_name if worker.user else '',
            'email': worker.user.email if worker.user else '',
            'phone': worker.phone,
            'address': worker.address,
            'adhaar': worker.adhaar,
            'profile_pic_url': request.build_absolute_uri(worker.profile_pic.url) if worker.profile_pic else None,
            'approval_status': worker.approval_status,
            'created_at': worker.user.date_joined if worker.user else None,
            # Add other fields relevant for the 'Worker Details' tab if needed
            'district': worker.district,
            'skills': worker.skills,
            'experience': worker.experience,
            'hourly_rate': worker.hourly_rate,
        }
        data.append(profile_data)

    return Response(data, status=status.HTTP_200_OK)


@api_view(['POST'])
def accept_worker_request(request, pk):
    """
    Accepts a worker request by updating their approval status.
    """
    try:
        worker_profile = WorkerProfile.objects.get(pk=pk)
        # Check if already approved to avoid redundant updates
        if worker_profile.approval_status == 'Approved':
             return Response({'message': 'Worker is already approved.'}, status=status.HTTP_200_OK)
             
        worker_profile.approval_status = 'Approved'
        worker_profile.save()
        return Response({'message': 'Worker request accepted successfully.'}, status=status.HTTP_200_OK)
    except WorkerProfile.DoesNotExist:
        return Response({'error': 'Worker profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def reject_worker_request(request, pk):
    """
    Rejects a worker request by updating their approval status and storing the reason.
    Expects {'reason': '...'} in the request body.
    """
    try:
        worker_profile = WorkerProfile.objects.get(pk=pk)
        reason = request.data.get('reason')

        if not reason:
            return Response({'error': 'Rejection reason is required.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if already rejected or approved
        if worker_profile.approval_status == 'Rejected':
             return Response({'message': 'Worker is already rejected.'}, status=status.HTTP_200_OK)
        # Optionally prevent rejecting an already approved worker
        # if worker_profile.approval_status == 'Approved':
        #     return Response({'error': 'Cannot reject an already approved worker.'}, status=status.HTTP_400_BAD_REQUEST)

        worker_profile.approval_status = 'Rejected'
        worker_profile.rejection_reason = reason
        worker_profile.save()
        return Response({'message': 'Worker request rejected successfully.'}, status=status.HTTP_200_OK)
    except WorkerProfile.DoesNotExist:
        return Response({'error': 'Worker profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT', 'PATCH']) # Allow PUT or PATCH for updates
def update_worker_details(request, pk):
    """
    Updates details for an existing worker profile.
    Expects JSON data in the request body.
    """
    try:
        worker_profile = WorkerProfile.objects.get(pk=pk)
        user = worker_profile.user
        data = request.data # Assuming JSON data

        # Update User fields (first_name, last_name, email)
        # Be careful allowing email changes, might need username sync or validation
        if 'first_name' in data:
            user.first_name = data['first_name']
        if 'last_name' in data:
            user.last_name = data['last_name']
        # if 'email' in data and user.email != data['email']:
            # Add validation if email change is allowed (check uniqueness)
            # user.email = data['email']
            # user.username = data['email'] # Keep username synced if using email as username

        # Update WorkerProfile fields
        if 'phone' in data:
            # Add validation if phone needs to remain unique
            worker_profile.phone = data['phone']
        if 'address' in data:
            worker_profile.address = data['address']
        # Add other editable fields as needed (district, skills, experience, hourly_rate)
        # Example:
        # if 'district' in data:
        #     worker_profile.district = data['district']
        # if 'hourly_rate' in data:
        #     try:
        #         worker_profile.hourly_rate = float(data['hourly_rate'])
        #     except (ValueError, TypeError):
        #         return Response({'error': 'Invalid hourly rate format'}, status=status.HTTP_400_BAD_REQUEST)

        user.save()
        worker_profile.save()

        return Response({'message': 'Worker details updated successfully.'}, status=status.HTTP_200_OK)

    except WorkerProfile.DoesNotExist:
        return Response({'error': 'Worker profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except IntegrityError as e: # Catch potential unique constraint violations (e.g., if phone is unique)
         return Response({'error': f'Update failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': f'An unexpected error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
def delete_worker_profile(request, pk):
    """
    Deletes a worker profile and their associated user account.
    """
    try:
        worker_profile = WorkerProfile.objects.get(pk=pk)
        user = worker_profile.user

        # Delete the worker profile first
        worker_profile.delete()

        # Then delete the associated user account
        if user:
            user.delete()

        return Response({'message': 'Worker profile and user account deleted successfully.'}, status=status.HTTP_200_OK) # Or 204 No Content

    except WorkerProfile.DoesNotExist:
        return Response({'error': 'Worker profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        # Log the error for debugging
        print(f"Error deleting worker profile {pk}: {str(e)}")
        return Response({'error': f'An error occurred during deletion: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# --- Contractor Views ---

@api_view(['GET'])
def ContractorProfileList(request):
    """
    Fetches contractor profiles with 'Pending' approval status.
    """
    pending_contractors = ContractorProfile.objects.filter(approval_status='Pending')
    data = []
    for contractor in pending_contractors:
        profile_data = {
            'id': contractor.id,
            'name': contractor.user.first_name if contractor.user else contractor.user.username, # Use user's name
            'email': contractor.user.email if contractor.user else '',
            'phone': contractor.phone,
            'address': contractor.address,
            'district': contractor.district,
            'city': contractor.city,
            'division': contractor.division,
            'pincode': contractor.pincode,
            'license_no': contractor.license_no,
            'profile_pic_url': request.build_absolute_uri(contractor.profile_pic.url) if contractor.profile_pic else None,
            'approval_status': contractor.approval_status,
            'created_at': contractor.user.date_joined if contractor.user else None,
        }
        data.append(profile_data)
    return Response(data, status=status.HTTP_200_OK)

@api_view(['GET'])
def ApprovedContractorList(request):
    """
    Fetches contractor profiles with 'Approved' approval status.
    """
    approved_contractors = ContractorProfile.objects.filter(approval_status='Approved')
    data = []
    for contractor in approved_contractors:
        profile_data = {
            'id': contractor.id,
            'name': contractor.user.first_name if contractor.user else contractor.user.username,
            'email': contractor.user.email if contractor.user else '',
            'phone': contractor.phone,
            'address': contractor.address,
            'district': contractor.district,
            'city': contractor.city,
            'division': contractor.division,
            'pincode': contractor.pincode,
            'license_no': contractor.license_no,
            'profile_pic_url': request.build_absolute_uri(contractor.profile_pic.url) if contractor.profile_pic else None,
            'approval_status': contractor.approval_status,
            'created_at': contractor.user.date_joined if contractor.user else None,
        }
        data.append(profile_data)
    return Response(data, status=status.HTTP_200_OK)

@api_view(['POST'])
def accept_contractor_request(request, pk):
    """
    Accepts a contractor request by updating their approval status.
    """
    try:
        contractor_profile = ContractorProfile.objects.get(pk=pk)
        if contractor_profile.approval_status == 'Approved':
             return Response({'message': 'Contractor is already approved.'}, status=status.HTTP_200_OK)
             
        contractor_profile.approval_status = 'Approved'
        contractor_profile.save()
        return Response({'message': 'Contractor request accepted successfully.'}, status=status.HTTP_200_OK)
    except ContractorProfile.DoesNotExist:
        return Response({'error': 'Contractor profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def reject_contractor_request(request, pk):
    """
    Rejects a contractor request by updating their approval status and storing the reason.
    Expects {'reason': '...'} in the request body.
    """
    try:
        contractor_profile = ContractorProfile.objects.get(pk=pk)
        reason = request.data.get('reason')
        if not reason:
            return Response({'error': 'Rejection reason is required.'}, status=status.HTTP_400_BAD_REQUEST)

        if contractor_profile.approval_status == 'Rejected':
             return Response({'message': 'Contractor is already rejected.'}, status=status.HTTP_200_OK)

        contractor_profile.approval_status = 'Rejected'
        contractor_profile.rejection_reason = reason
        contractor_profile.save()
        return Response({'message': 'Contractor request rejected successfully.'}, status=status.HTTP_200_OK)
    except ContractorProfile.DoesNotExist:
        return Response({'error': 'Contractor profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT', 'PATCH'])
def update_contractor_details(request, pk):
    """
    Updates details for an existing contractor profile.
    Expects JSON data in the request body.
    """
    try:
        contractor_profile = ContractorProfile.objects.get(pk=pk)
        user = contractor_profile.user
        data = request.data

        # Update User fields (name, email)
        if 'name' in data:
            user.first_name = data['name'] # Assuming name is stored in first_name
        # if 'email' in data and user.email != data['email']:
            # Add validation if email change is allowed
            # user.email = data['email']
            # user.username = data['email']

        # Update ContractorProfile fields
        if 'phone' in data: contractor_profile.phone = data['phone']
        if 'address' in data: contractor_profile.address = data['address']
        if 'district' in data: contractor_profile.district = data['district']
        if 'city' in data: contractor_profile.city = data['city']
        if 'division' in data: contractor_profile.division = data['division']
        if 'pincode' in data: contractor_profile.pincode = data['pincode']
        if 'license_no' in data: contractor_profile.license_no = data['license_no']
        # Add profile_pic update logic if needed (would require MultiPartParser)

        user.save()
        contractor_profile.save()
        return Response({'message': 'Contractor details updated successfully.'}, status=status.HTTP_200_OK)

    except ContractorProfile.DoesNotExist:
        return Response({'error': 'Contractor profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except IntegrityError as e:
         return Response({'error': f'Update failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': f'An unexpected error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
def delete_contractor_profile(request, pk):
    """
    Deletes a contractor profile and their associated user account.
    """
    try:
        contractor_profile = ContractorProfile.objects.get(pk=pk)
        user = contractor_profile.user
        contractor_profile.delete()
        if user:
            user.delete()
        return Response({'message': 'Contractor profile and user account deleted successfully.'}, status=status.HTTP_200_OK)
    except ContractorProfile.DoesNotExist:
        return Response({'error': 'Contractor profile not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"Error deleting contractor profile {pk}: {str(e)}")
        return Response({'error': f'An error occurred during deletion: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# --- Worker Jobs Endpoints ---
@api_view(['GET'])
def worker_jobs(request, worker_id):
    """
    Returns all jobs assigned to a specific worker.
    Optionally filters by status with query param: ?status=In%20Progress
    """
    try:
        # Find the worker profile
        try:
            worker_profile = WorkerProfile.objects.get(user_id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response({'error': 'Worker profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get status filter from query params if provided
        status_filter = request.query_params.get('status', None)
        
        # Get jobs assigned to this worker
        jobs_query = Job.objects.filter(worker=worker_profile)
        if status_filter:
            jobs_query = jobs_query.filter(status=status_filter)
            
        # Order by recent first
        jobs = jobs_query.order_by('-job_posted_date')
        
        # Prepare the response data
        jobs_data = []
        for job in jobs:
            contractor_name = job.contractor.user.get_full_name() if job.contractor else "Unknown"
            jobs_data.append({
                'id': job.id,
                'title': job.title,
                'description': job.description,
                'address': job.address,
                'job_type': job.job_type,
                'work_environment': job.work_environment,
                'status': job.status,
                'contractor_name': contractor_name,
                'posted_date': job.job_posted_date.strftime('%Y-%m-%d %H:%M') if job.job_posted_date else None,
                'is_active': job.is_active,
            })
            
        return Response(jobs_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def worker_contractors(request, worker_id):
    print(worker_id)
    """
    Returns unique contractors who have assigned active jobs to this worker.
    """
    try:
        # Find the worker profile
        try:
            worker_profile = WorkerProfile.objects.get(user_id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response({'error': 'Worker profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get active jobs for this worker
        active_jobs = Job.objects.filter(
            worker=worker_profile, 
            status__in=['active', 'In Progress']
        ).select_related('contractor__user')
        print(active_jobs)        # Extract unique contractors
        unique_contractors = {}
        
        for job in active_jobs:
            if job.contractor and job.contractor.user.id not in unique_contractors:
                contractor = job.contractor
                user = contractor.user
                
                # Create contractor data - using user.id for chat consistency
                unique_contractors[user.id] = {
                    'id': user.id,  # Use User ID instead of ContractorProfile ID
                    'name': user.get_full_name(),
                    'email': user.email,
                    'last_message': job.title or 'New job available',
                    'profile_pic': None,
                    'job_title': job.title,
                    'timestamp': job.job_posted_date if job.job_posted_date else datetime.now().isoformat(),
                }
        
        # Convert to list for response
        contractors_list = list(unique_contractors.values())
        
        # Sort by timestamp for most recent first
        contractors_list.sort(key=lambda x: x['timestamp'], reverse=True)
        
        return Response(contractors_list, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching contractors for worker {worker_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def worker_stats(request, worker_id):
    """
    Returns statistics for a worker's dashboard
    """
    try:
        # Find the worker profile
        try:
            worker_profile = WorkerProfile.objects.get(user_id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response({'error': 'Worker profile not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Get all jobs assigned to this worker
        all_jobs = Job.objects.filter(worker=worker_profile)
        
        # Count jobs by status
        active_jobs_count = all_jobs.filter(status='In Progress').count()
        completed_jobs_count = all_jobs.filter(status='Completed').count()
        cancelled_jobs_count = all_jobs.filter(status='Cancelled').count()
        
        # Calculate earnings (assuming we have payment records)
        total_earnings = Payment.objects.filter(
            worker=worker_profile,
            status='completed'
        ).aggregate(models.Sum('amount'))['amount__sum'] or 0
        
        # Average rating (if we implement a rating system)
        # avg_rating = Rating.objects.filter(worker=worker_profile).aggregate(models.Avg('score'))['score__avg'] or 0
        
        # Prepare stats in the format expected by the frontend
        stats = [
            {
                'title': 'Active Jobs',
                'count': str(active_jobs_count),
                'subtitle': 'Total Jobs',
                'value': str(all_jobs.count()),
                'from': 'Assigned',
                'to': 'Completed',
                'time': timezone.now().strftime('%I:%M %p'),
                'price': f'₹{float(total_earnings):.2f}',
                'date': 'This Week',
                'downloads': '3.2m',
                'rating': '4.7',
                'icon': 'briefcase_outline',
                'color': "#59379F", # Google Red
                'badge_text': 'Business Basic',
                'free': True
            },
            {
                'title': 'Earnings',
                'count': f'₹{float(total_earnings):.2f}',
                'subtitle': 'This Month',
                'value': f'{float(total_earnings):.2f}',
                'from': 'Weekly',
                'to': 'Monthly',
                'time': timezone.now().strftime('%I:%M %p'),
                'price': f'{float(total_earnings):.2f}',
                'date': 'This Month',
                'downloads': '4.1m',
                'rating': '4.6',
                'icon': 'cash_outline',
                'color': "#309950", # Google Yellow
                'badge_text': 'Premium Pay',
                'free': True
            },
            {
                'title': 'Completed Jobs',
                'count': str(completed_jobs_count),
                'subtitle': 'Success Rate',
                'value': f'{completed_jobs_count}/{all_jobs.count() or 1}',
                'from': 'Previous',
                'to': 'Current',
                'time': timezone.now().strftime('%I:%M %p'),
                'price': '★4.8',
                'date': 'All Time',
                'downloads': '2.8m',
                'rating': '4.8',
                'icon': 'checkmark_circle_outline',
                'color': '#0F9D58', # Google Green
                'badge_text': 'Excellent',
                'free': True
            },
        ]
        
        return Response(stats, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# --- Dashboard View ---
@api_view(['GET'])
def dashboard_activity(request):
    """
    Returns recent activity/complaints for the admin dashboard
    If no complaints exist, returns dummy data
    """
    try:
        from .models import Complaint
        complaints = Complaint.objects.all().order_by('-created_at')[:5]
        
        data = []
        
        if complaints.exists():
            # Use real complaints if they exist
            for complaint in complaints:
                worker_name = f"{complaint.complainant_worker.user.first_name} {complaint.complainant_worker.user.last_name}".strip()
                
                data.append({
                    'id': complaint.id,
                    'title': complaint.title,
                    'description': complaint.description,
                    'status': complaint.status,
                    'complaint_type': complaint.complaint_type,
                    'created_at': complaint.created_at.isoformat() if complaint.created_at else None,
                    'worker_name': worker_name,
                })
        else:
            # Return dummy activity data
            from datetime import datetime, timedelta
            now = datetime.now()
            
            data = [
                {
                    'id': 1,
                    'title': 'New Faculty Registration',
                    'description': 'Dr. Akshay Kumar registered as faculty member',
                    'status': 'Pending',
                    'complaint_type': 'Registration',
                    'created_at': (now - timedelta(hours=2)).isoformat(),
                    'worker_name': 'Dr. Akshay Kumar',
                },
                {
                    'id': 2,
                    'title': 'Student Enrollment Request',
                    'description': 'John Doe requested enrollment in Computer Science department',
                    'status': 'Pending',
                    'complaint_type': 'Enrollment',
                    'created_at': (now - timedelta(hours=5)).isoformat(),
                    'worker_name': 'John Doe',
                },
                {
                    'id': 3,
                    'title': 'Attendance Report Generated',
                    'description': 'Monthly attendance report for September has been generated',
                    'status': 'Completed',
                    'complaint_type': 'Report',
                    'created_at': (now - timedelta(hours=8)).isoformat(),
                    'worker_name': 'System',
                },
                {
                    'id': 4,
                    'title': 'Faculty Approved',
                    'description': 'Prof. Sarah Johnson has been approved for teaching',
                    'status': 'Approved',
                    'complaint_type': 'Approval',
                    'created_at': (now - timedelta(days=1)).isoformat(),
                    'worker_name': 'Prof. Sarah Johnson',
                },
                {
                    'id': 5,
                    'title': 'Attendance Alert',
                    'description': 'Student attendance below 75% threshold',
                    'status': 'Alert',
                    'complaint_type': 'Attendance',
                    'created_at': (now - timedelta(days=1, hours=3)).isoformat(),
                    'worker_name': 'Jane Smith',
                },
            ]
        
        return Response(data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching dashboard activity: {str(e)}")
        # Return dummy data even on error
        from datetime import datetime, timedelta
        now = datetime.now()
        
        dummy_data = [
            {
                'id': 1,
                'title': 'New Faculty Registration',
                'description': 'Dr. Akshay Kumar registered as faculty member',
                'status': 'Pending',
                'complaint_type': 'Registration',
                'created_at': (now - timedelta(hours=2)).isoformat(),
                'worker_name': 'Dr. Akshay Kumar',
            },
            {
                'id': 2,
                'title': 'Student Enrollment Request',
                'description': 'John Doe requested enrollment in Computer Science department',
                'status': 'Pending',
                'complaint_type': 'Enrollment',
                'created_at': (now - timedelta(hours=5)).isoformat(),
                'worker_name': 'John Doe',
            },
        ]
        
        return Response(dummy_data, status=status.HTTP_200_OK)


@api_view(['GET'])
def dashboard_stats(request):
    """
    Returns statistics for the admin dashboard
    """
    try:
        # Count approved faculty
        approved_faculty_count = FacultyProfile.objects.filter(approval_status='Approved').count()
        
        # Count approved students
        approved_students_count = StudentProfile.objects.filter(approval_status='Approved').count()
        
        # Count pending faculty requests
        pending_faculty_count = FacultyProfile.objects.filter(approval_status='Pending').count()
        
        # Count pending student requests
        pending_students_count = StudentProfile.objects.filter(approval_status='Pending').count()
        
        stats = [
            {
                'title': 'Approved Faculty',
                'count': approved_faculty_count,
                'icon': 'person_outline',
                'color': '#4A6FE6',  # Blue
                'growth': '+12%'
            },
            {
                'title': 'Approved Students',
                'count': approved_students_count,
                'icon': 'school_outline',
                'color': '#2ECC71',  # Green
                'growth': '+24%'
            },
            {
                'title': 'Pending Faculty',
                'count': pending_faculty_count,
                'icon': 'pending_actions_outlined',
                'color': '#F39C12',  # Orange
                'growth': '+8%'
            },
            {
                'title': 'Pending Students',
                'count': pending_students_count,
                'icon': 'work_outline',
                'color': '#E74C3C',  # Red
                'growth': '+15%'
            },
        ]
        print(f"Dashboard stats: {stats}")
        return Response(stats, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching dashboard stats: {str(e)}")
        return Response(
            {'error': f'Failed to fetch dashboard statistics: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# API view to get all active contractors (for job posting dropdown)
@api_view(['GET'])
def get_contractors(request):
    """
    Returns a list of approved contractors for populating dropdown menus.
    """
    try:
        # Only fetch approved contractors
        contractors = ContractorProfile.objects.filter(approval_status='Approved')
        
        contractor_list = []
        for contractor in contractors:
            contractor_list.append({
                'id': contractor.id,
                'name': contractor.user.first_name,  # Using the name stored in first_name
                'email': contractor.user.email,
                'phone': contractor.phone,
                'city': contractor.city
            })
        
        return Response(contractor_list, status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {'error': f'An error occurred while fetching contractors: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# API view to create a new job
@api_view(['POST'])
def create_job(request):
    """
    Creates a new job posting.
    """
    try:
        data = request.data
        
        # Validate required fields
        required_fields = ['title', 'description', 'address', 'job_type', 'work_environment', 'contractor_id', 'user_id']
        for field in required_fields:
            if field not in data:
                return Response(
                    {'error': f'Missing required field: {field}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Check if contractor exists
        try:
            contractor = ContractorProfile.objects.get(id=data['contractor_id'])
        except ContractorProfile.DoesNotExist:
            return Response(
                {'error': 'Contractor not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if user exists
        try:
            user = User.objects.get(id=data['user_id'])
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Create the job
        job = Job.objects.create(
            title=data['title'],
            description=data['description'],
            address=data['address'],
            job_type=data['job_type'],
            work_environment=data['work_environment'],
            contractor=contractor,
            user=user
            # job_posted_date will be auto-set to current time by the model default
        )
        
        return Response(
            {
                'message': 'Job created successfully',
                'job_id': job.id,
                'job_posted_date': job.job_posted_date
            }, 
            status=status.HTTP_201_CREATED
        )
    
    except Exception as e:
        return Response(
            {'error': f'An error occurred while creating the job: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# API view to get all jobs
@api_view(['GET'])
def get_jobs(request):
    """
    Returns a list of all active jobs.
    """
    try:
        # Filter for active jobs only
        jobs = Job.objects.filter(is_active=True).order_by('-job_posted_date')
        
        job_list = []
        for job in jobs:
            job_list.append({
                'id': job.id,
                'title': job.title,
                'description': job.description,
                'address': job.address,
                'job_type': job.job_type,
                'work_environment': job.work_environment,
                'contractor': {
                    'id': job.contractor.id,
                    'name': job.contractor.user.first_name,
                    'email': job.contractor.user.email
                },
                'user_id': job.user.id,
                'job_posted_date': job.job_posted_date,
            })
        
        return Response(job_list, status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {'error': f'An error occurred while fetching jobs: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# API view to delete a job
@api_view(['DELETE'])
def delete_job(request, job_id):
    """
    Deletes a job posting. Only the user who created the job can delete it.
    """
    try:
        job = Job.objects.get(id=job_id)
        # Verify that the job exists and is active
        if not job.is_active:
            return Response(
                {'error': 'Job not found or already deleted'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Instead of actually deleting, just mark as inactive
        job.is_active = False
        job.save()
        
        return Response(
            {'message': 'Job deleted successfully'},
            status=status.HTTP_200_OK
        )
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'An error occurred while deleting the job: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# API view to get jobs by user ID
@api_view(['GET'])
def get_user_jobs(request, user_id):
    """
    Returns a list of active jobs posted by a specific user.
    """
    try:
        # Check if user exists
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Filter for jobs by this user (including inactive for user's own view)
        jobs = Job.objects.filter(user=user).order_by('-job_posted_date')
        
        job_list = []
        for job in jobs:
            # Prepare worker data if assigned
            worker_data = None
            if job.worker:
                worker_data = {
                    'id': job.worker.id,
                    'first_name': job.worker.user.first_name or '',
                    'last_name': job.worker.user.last_name or '',
                    'email': job.worker.user.email or '',
                    'phone': job.worker.phone or '',
                    'profile_pic_url': request.build_absolute_uri(job.worker.profile_pic.url) if job.worker.profile_pic else None,
                }
            
            # Prepare contractor data
            contractor_data = None
            if job.contractor:
                contractor_data = {
                    'id': job.contractor.id,
                    'name': job.contractor.user.first_name or job.contractor.user.username,
                    'email': job.contractor.user.email or '',
                    'phone': job.contractor.phone or '',
                    'profile_pic_url': request.build_absolute_uri(job.contractor.profile_pic.url) if job.contractor.profile_pic else None,
                }
            
            job_list.append({
                'id': job.id,
                'title': job.title or '',
                'description': job.description or '',
                'address': job.address or '',
                'job_type': job.job_type or '',
                'work_environment': job.work_environment or '',
                'status': job.status or 'Pending',
                'is_active': job.is_active,
                'contractor': contractor_data,
                'worker': worker_data,
                'job_posted_date': job.job_posted_date.isoformat() if job.job_posted_date else None,
            })
        
        return Response(job_list, status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {'error': f'An error occurred while fetching user jobs: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# API view to update a job
@api_view(['PUT'])
@csrf_exempt
def update_job(request, job_id):
    """
    Updates a job posting. Only the user who created the job can update it.
    """
    try:
        job = Job.objects.get(id=job_id)
        
        # Verify that the job exists and is active
        # if not job.is_active:
        #     return Response(
        #         {'error': 'Job not found or already deleted'},
        #         status=status.HTTP_404_NOT_FOUND
        #     )
        
        # Get the data from the request
        data = request.data
          # Update job fields if they are provided in the request
        if 'title' in data:
            job.title = data['title']
        if 'description' in data:
            job.description = data['description']
        if 'address' in data:
            job.address = data['address']
        if 'job_type' in data:
            job.job_type = data['job_type']
        if 'work_environment' in data:
            job.work_environment = data['work_environment']
        if 'status' in data:
            job.status = data['status']
        if 'contractor_id' in data:
            try:
                contractor = ContractorProfile.objects.get(id=data['contractor_id'])
                job.contractor = contractor
            except ContractorProfile.DoesNotExist:
                return Response(
                    {'error': 'Contractor not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        
        # Handle worker reassignment
        if 'worker_id' in data:
            # If worker_id is null, remove the worker assignment
            if data['worker_id'] is None:
                job.worker = None
            else:
                try:
                    worker = WorkerProfile.objects.get(id=data['worker_id'])
                    job.worker = worker
                except WorkerProfile.DoesNotExist:
                    return Response(
                        {'error': 'Worker not found'},
                        status=status.HTTP_404_NOT_FOUND
                    )
        
        job.save()
        
        # Prepare worker data for response if assigned
        worker_data = None
        if job.worker:
            worker_data = {
                'id': job.worker.id,
                'first_name': job.worker.user.first_name,
                'last_name': job.worker.user.last_name,
                'email': job.worker.user.email
            }
        
        return Response(
            {
                'message': 'Job updated successfully',
                'job': {
                    'id': job.id,
                    'title': job.title,
                    'description': job.description,
                    'address': job.address,
                    'job_type': job.job_type,
                    'work_environment': job.work_environment,
                    'contractor': {
                        'id': job.contractor.id,
                        'name': job.contractor.user.first_name,
                        'email': job.contractor.user.email
                    },
                    'worker': worker_data,
                    'job_posted_date': job.job_posted_date
                }
            },
            status=status.HTTP_200_OK
        )
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'An error occurred while updating the job: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# API view to assign worker to job
@api_view(['PUT'])
def assign_worker_to_job(request, job_id):
    """
    Assigns a worker to an existing job.
    """
    try:
        data = request.data
        
        # Check if worker_id is provided
        if 'worker_id' not in data:
            return Response(
                {'error': 'Worker ID is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if job exists
        try:
            job = Job.objects.get(id=job_id)
        except Job.DoesNotExist:
            return Response(
                {'error': 'Job not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if worker exists
        try:
            worker = WorkerProfile.objects.get(id=data['worker_id'])
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Assign worker to job
        job.worker = worker
        job.save()
        
        return Response(
            {
                'message': 'Worker assigned successfully',
                'job_id': job.id,
                'worker_id': worker.id,
                'worker_name': f"{worker.user.first_name} {worker.user.last_name}"
            }, 
            status=status.HTTP_200_OK
        )
    
    except Exception as e:
        return Response(
            {'error': f'An error occurred while assigning worker to job: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# API view to update job status
# @api_view(['PATCH'])
@api_view(['PUT'])
# @csrf_exempt
def update_job_status(request, job_id):
    """
    Updates only the status of a job posting.
    """
    try:
        job = Job.objects.get(id=job_id)
        
        # Verify that the job exists and is active
        # if not job.is_active:
        #     return Response(
        #         {'error': 'Job not found or already deleted'},
        #         status=status.HTTP_404_NOT_FOUND
        #     )
        
        # Get the status from the request
        data = request.data
        
        if 'status' not in data:
            return Response(
                {'error': 'Status field is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate that the status is one of the valid choices
        if data['status'] not in [choice[0] for choice in Job.STATUS_CHOICES]:
            return Response(
                {'error': 'Invalid status value'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Update the job status
        job.status = data['status']
        job.save()
        
        # Return the updated job
        response_data = {
            'id': job.id,
            'title': job.title,
            'status': job.status,
            'updated': True
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@csrf_exempt
def accept_job(request, job_id):
    """
    Accept a job. Only workers can accept jobs.
    """
    try:
        # Get the job
        job = Job.objects.get(id=job_id)
        worker_id = job.worker.id
        
        # Validate worker exists
        try:
            worker = WorkerProfile.objects.get(id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Check if job is already accepted or rejected
        if job.status != 'Pending':
            return Response(
                {'error': f'Job is already {job.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Update job status and assign worker
        job.status = 'In Progress'
        job.worker = worker
        job.save()
        
        return Response({
            'message': 'Job accepted successfully',
            'job_id': job.id,
            'status': job.status
        }, status=status.HTTP_200_OK)
            
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@csrf_exempt
def reject_job(request, job_id):
    """
    Reject a job. Only workers can reject jobs.
    """
    try:
        # Get the job
        job = Job.objects.get(id=job_id)
        worker_id = job.worker.id
        
        # Validate worker exists
        try:
            worker = WorkerProfile.objects.get(id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Check if job is already accepted or rejected
        if job.status != 'Pending':
            return Response(
                {'error': f'Job is already {job.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Update job status
        job.status = 'Cancelled'
        job.save()
        
        return Response({
            'message': 'Job rejected successfully',
            'job_id': job.id,
            'status': job.status
        }, status=status.HTTP_200_OK)
            
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def contractor_workers(request, contractor_id):
    """
    Returns unique workers who are assigned to active jobs by this contractor
    OR have had chat conversations with this contractor.
    """
    try:
        # Find the contractor profile
        try:
            contractor_profile = ContractorProfile.objects.get(user_id=contractor_id)
        except ContractorProfile.DoesNotExist:
            return Response({'error': 'Contractor profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get active jobs for this contractor that have assigned workers
        active_jobs = Job.objects.filter(
            contractor=contractor_profile, 
            status__in=['active', 'In Progress'],
            worker__isnull=False  # Only include jobs with assigned workers
        ).select_related('worker__user')
        
        print(f"Found {active_jobs.count()} active jobs with workers for contractor {contractor_id}")
        
        # Extract unique workers from jobs
        unique_workers = {}
        
        for job in active_jobs:
            if job.worker and job.worker.user.id not in unique_workers:
                worker = job.worker
                user = worker.user
                
                # Create worker data - using user.id for chat consistency
                unique_workers[user.id] = {
                    'id': user.id,  # Use User ID instead of WorkerProfile ID
                    'name': user.get_full_name(),
                    'email': user.email,
                    'last_message': job.title or 'Working on job',
                    'profile_pic': None,
                    'job_title': job.title,
                    'timestamp': job.job_posted_date if job.job_posted_date else datetime.now().isoformat(),
                }
        
        # ALSO include workers who have had chat conversations with this contractor
        from .models import ChatMessage
        from django.db.models import Q
        
        # Find all users who have exchanged messages with this contractor
        chat_messages = ChatMessage.objects.filter(
            Q(sender_id=str(contractor_id)) | Q(receiver_id=str(contractor_id))
        ).values_list('sender_id', 'receiver_id').distinct()
        
        # Extract unique worker user IDs from chat messages
        chat_user_ids = set()
        for sender_id, receiver_id in chat_messages:
            if sender_id != str(contractor_id):
                chat_user_ids.add(sender_id)
            if receiver_id != str(contractor_id):
                chat_user_ids.add(receiver_id)
        
        print(f"Found {len(chat_user_ids)} users with chat history with contractor {contractor_id}")
        
        # Add workers from chat history who aren't already in the list
        for user_id_str in chat_user_ids:
            try:
                user_id = int(user_id_str)
                if user_id not in unique_workers:
                    # Check if this user is a worker
                    try:
                        worker_profile = WorkerProfile.objects.get(user_id=user_id)
                        user = worker_profile.user
                        
                        # Get the most recent message between contractor and this worker
                        recent_message = ChatMessage.objects.filter(
                            Q(sender_id=str(contractor_id), receiver_id=str(user_id)) |
                            Q(sender_id=str(user_id), receiver_id=str(contractor_id))
                        ).order_by('-timestamp').first()
                        
                        last_message = recent_message.message[:50] + "..." if recent_message and len(recent_message.message) > 50 else (recent_message.message if recent_message else "No recent message")
                        
                        unique_workers[user.id] = {
                            'id': user.id,  # Use User ID for chat consistency
                            'name': user.get_full_name(),
                            'email': user.email,
                            'last_message': last_message,
                            'profile_pic': None,
                            'job_title': 'Chat Conversation',
                            'timestamp': recent_message.timestamp.isoformat() if recent_message else datetime.now().isoformat(),
                        }
                    except WorkerProfile.DoesNotExist:
                        # This user exists in chat but is not a worker, skip
                        continue
            except (ValueError, TypeError):
                # Invalid user ID format, skip
                continue
        
        # Convert to list for response
        workers_list = list(unique_workers.values())
        
        # Sort by timestamp for most recent first
        workers_list.sort(key=lambda x: x['timestamp'], reverse=True)
        
        print(f"Returning {len(workers_list)} unique workers")
        return Response(workers_list, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching workers for contractor {contractor_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_user_posted_jobs(request, user_id):
    """
    Returns a list of jobs posted by a specific user (jobs they created).
    """
    try:
        # Check if user exists
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Filter for active jobs posted by this user
        jobs = Job.objects.filter(user=user).order_by('-job_posted_date')
        print(f"Found {jobs.count()} jobs posted by user {user_id}")
        job_list = []
        for job in jobs:
            # Prepare worker data if assigned
            worker_data = None
            if job.worker:
                worker_data = {
                    'id': job.worker.id,
                    'first_name': job.worker.user.first_name or '',
                    'last_name': job.worker.user.last_name or '',
                    'email': job.worker.user.email or ''
                }
            
            job_list.append({
                'id': job.id,
                'title': job.title or '',
                'description': job.description or '',
                'address': job.address or '',
                'job_type': job.job_type or '',
                'work_environment': job.work_environment or '',
                'status': job.status or 'Pending',
                'contractor': {
                    'id': job.contractor.id if job.contractor else None,
                    'name': job.contractor.user.first_name if job.contractor else '',
                    'email': job.contractor.user.email if job.contractor else ''
                } if job.contractor else None,
                'worker': worker_data,
                'job_posted_date': job.job_posted_date.isoformat() if job.job_posted_date else None,
                # Add fields for the dashboard cards
                'icon': 'briefcase_outline',
                'iconBgColor': '#4A6FE6',
                'secondary': f"{job.contractor.user.first_name if job.contractor else 'No Contractor'} • {job.address[:20]}{'...' if len(job.address) > 20 else ''}",
                'tertiary': f"Status: {job.status}",
            })
        
        return Response(job_list, status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {'error': f'An error occurred while fetching user posted jobs: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['PUT'])
def edit_user_job(request, job_id):
    """
    Allows a user to edit their own job posting.
    """
    try:
        job = Job.objects.get(id=job_id)
        data = request.data
        
        # Verify the user owns this job
        if str(job.user.id) != str(data.get('user_id')):
            return Response(
                {'error': 'You can only edit your own jobs'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update job fields
        if 'title' in data:
            job.title = data['title']
        if 'description' in data:
            job.description = data['description']
        if 'address' in data:
            job.address = data['address']
        if 'job_type' in data:
            job.job_type = data['job_type']
        if 'work_environment' in data:
            job.work_environment = data['work_environment']
        if 'contractor_id' in data:
            try:
                contractor = ContractorProfile.objects.get(id=data['contractor_id'])
                job.contractor = contractor
            except ContractorProfile.DoesNotExist:
                return Response(
                    {'error': 'Contractor not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        
        job.save()
        
        return Response({
            'message': 'Job updated successfully',
            'job': {
                'id': job.id,
                'title': job.title,
                'description': job.description,
                'address': job.address,
                'job_type': job.job_type,
                'work_environment': job.work_environment,
                'status': job.status,
                'contractor': {
                    'id': job.contractor.id if job.contractor else None,
                    'name': job.contractor.user.first_name if job.contractor else '',
                    'email': job.contractor.user.email if job.contractor else ''
                } if job.contractor else None,
            }
        }, status=status.HTTP_200_OK)
        
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'An error occurred while updating the job: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['DELETE'])
def delete_user_job(request, job_id):
    """
    Allows a user to delete their own job posting.
    """
    try:
        job = Job.objects.get(id=job_id)
        user_id = request.query_params.get('user_id')
        
        # Verify the user owns this job
        if str(job.user.id) != str(user_id):
            return Response(
                {'error': 'You can only delete your own jobs'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Check if job has assigned worker
        if job.worker and job.status == 'In Progress':
            return Response(
                {'error': 'Cannot delete job that is currently in progress'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Soft delete - mark as inactive instead of hard delete
        job.is_active = False
        job.save()
        
        return Response({
            'message': 'Job deleted successfully'
        }, status=status.HTTP_200_OK)
        
    except Job.DoesNotExist:
        return Response(
            {'error': 'Job not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'An error occurred while deleting the job: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )



@api_view(['GET'])
def get_user_stats(request, user_id):
    """
    Returns statistics for a user's dashboard
    """
    try:
        # Check if user exists
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get total jobs posted by this user
        total_jobs_posted = Job.objects.filter(user=user).count()
        
        # Get number of assigned jobs (jobs with workers assigned)
        assigned_jobs_count = Job.objects.filter(user=user, worker__isnull=False).count()
        
        # Get total contractors count (approved contractors)
        total_contractors = ContractorProfile.objects.filter(approval_status='Approved').count()
        
        # Get total workers count (approved workers)
        total_workers = WorkerProfile.objects.filter(approval_status='Approved').count()
        
        # Get workers currently working on this user's jobs
        active_workers_count = Job.objects.filter(
            user=user, 
            worker__isnull=False, 
            status='In Progress'
        ).values('worker').distinct().count()
        
        # Prepare stats for the frontend
        stats = [
            {
                'title': 'Jobs Posted',
                'count': str(total_jobs_posted),
                'icon': 'briefcase_outline',
                'color': '#4A6FE6',
                'growth': '+0'  # You can calculate growth based on time periods
            },
            {
                'title': 'Assigned Jobs',
                'count': str(assigned_jobs_count),
                'icon': 'checkmark_circle_outline',
                'color': '#E67E22',
                'growth': '+0'
            },
            {
                'title': 'Total Contractors',
                'count': str(total_contractors),
                'icon': 'business_outline',
                'color': '#2ECC71',
                'growth': '+0'
            },
            {
                'title': 'Total Workers',
                'count': str(total_workers),
                'icon': 'people_outline',
                'color': '#9B59B6',
                'growth': '+0',
                'active_workers': str(active_workers_count)  # Add active workers count
            },
        ]
        
        return Response(stats, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching user stats for user {user_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def worker_payments(request, worker_id):
    """
    Returns payment history and summary for a specific worker.
    """
    try:
        # Find the worker profile
        try:
            worker_profile = WorkerProfile.objects.get(user_id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response({'error': 'Worker profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get all payments for this worker
        payments = Payment.objects.filter(worker=worker_profile).order_by('-payment_date')
        
        # Calculate payment statistics
        total_earnings = payments.filter(status='completed').aggregate(
            models.Sum('amount')
        )['amount__sum'] or 0
        
        pending_amount = payments.filter(status='initiated').aggregate(
            models.Sum('amount')
        )['amount__sum'] or 0
        
        completed_payments_count = payments.filter(status='completed').count()
        
        # Prepare payment history
        payment_history = []
        for payment in payments:
            payment_history.append({
                'id': payment.id,
                'amount': float(payment.amount),
                'status': payment.status,
                'payment_date': payment.payment_date.isoformat() if payment.payment_date else None,
                'contractor_name': payment.contractor.user.get_full_name() or payment.contractor.user.username if payment.contractor else 'Unknown',
                'razorpay_payment_id': payment.razorpay_payment_id,
                'formatted_date': payment.payment_date.strftime('%d %b %Y, %I:%M %p') if payment.payment_date else 'N/A',
            })
        
        # Prepare response data
        response_data = {
            'summary': {
                'total_earnings': float(total_earnings),
                'pending_amount': float(pending_amount),
                'completed_payments': completed_payments_count,
                'total_payments': payments.count(),
            },
            'payments': payment_history
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching payments for worker {worker_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_contractor_payments(request, contractor_id):
    """
    Get all payment transactions made by a contractor
    """
    try:
        # Convert the ID to int for comparison
        contractor_id = int(contractor_id)
        
        # Query payments related to this contractor
        payments = Payment.objects.filter(contractor_id=contractor_id).select_related('worker')
        
        # Serialize payment data
        payment_data = []
        for payment in payments:
            worker_name = f"{payment.worker.first_name} {payment.worker.last_name}" if payment.worker else "Unknown Worker"
            
            payment_data.append({
                'id': payment.id,
                'worker_id': payment.worker_id,
                'worker_name': worker_name,
                'amount': float(payment.amount),
                'payment_date': payment.payment_date.strftime('%Y-%m-%d %H:%M:%S'),
                'status': payment.status,
                'razorpay_payment_id': payment.razorpay_payment_id,
                'razorpay_order_id': payment.razorpay_order_id
            })
        
        return Response(payment_data, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"Error retrieving payments: {str(e)}")
        return Response(
            {'error': f'Could not retrieve payments: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_user_assigned_workers(request, user_id):
    """
    Returns workers assigned to jobs posted by this user (for feedback purposes).
    """
    try:
        # Check if user exists
        try:
            user = User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get jobs posted by this user that have assigned workers
        jobs_with_workers = Job.objects.filter(
            user=user,
            worker__isnull=False,
            status__in=['In Progress', 'Completed']  # Only jobs that are active or completed
        ).select_related('worker__user').distinct()
        
        # Extract unique workers with their job information
        workers_data = []
        processed_workers = set()  # To avoid duplicates
        
        for job in jobs_with_workers:
            worker_id = job.worker.id
            if worker_id not in processed_workers:
                # Check if feedback already exists for this job-worker combination
                existing_feedback = WorkerFeedback.objects.filter(
                    job=job,
                    worker=job.worker,
                    user=user
                ).first()
                
                worker_data = {
                    'id': job.worker.id,
                    'name': f"{job.worker.user.first_name} {job.worker.user.last_name}".strip() or job.worker.user.username,
                    'email': job.worker.user.email,
                    'phone': job.worker.phone,
                    'profile_pic_url': request.build_absolute_uri(job.worker.profile_pic.url) if job.worker.profile_pic else None,
                    'job_id': job.id,
                    'job_title': job.title,
                    'job_status': job.status,
                    'skills': job.worker.skills,
                    'experience': job.worker.experience,
                    'has_feedback': existing_feedback is not None,
                    'feedback_rating': existing_feedback.rating if existing_feedback else None,
                }
                workers_data.append(worker_data)
                processed_workers.add(worker_id)
        
        return Response(workers_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching assigned workers for user {user_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def submit_worker_feedback(request):
    """
    Submit feedback for a worker on a specific job.
    """
    try:
        data = request.data
        
        # Validate required fields
        required_fields = ['job_id', 'worker_id', 'user_id', 'rating', 'feedback_text']
        for field in required_fields:
            if field not in data:
                return Response(
                    {'error': f'Missing required field: {field}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Validate objects exist
        try:
            job = Job.objects.get(pk=data['job_id'])
        except Job.DoesNotExist:
            return Response(
                {'error': 'Job not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        try:
            worker = WorkerProfile.objects.get(pk=data['worker_id'])
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        try:
            user = User.objects.get(pk=data['user_id'])
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Verify the user posted this job
        if job.user != user:
            return Response(
                {'error': 'You can only provide feedback for jobs you posted'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Verify the worker is assigned to this job
        if job.worker != worker:
            return Response(
                {'error': 'This worker is not assigned to the specified job'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if feedback already exists
        existing_feedback = WorkerFeedback.objects.filter(
            job=job,
            worker=worker,
            user=user
        ).first()
        
        if existing_feedback:
            # Update existing feedback
            existing_feedback.rating = data['rating']
            existing_feedback.feedback_text = data['feedback_text']
            existing_feedback.work_quality = data.get('work_quality')
            existing_feedback.punctuality = data.get('punctuality')
            existing_feedback.communication = data.get('communication')
            existing_feedback.professionalism = data.get('professionalism')
            existing_feedback.would_hire_again = data.get('would_hire_again', True)
            existing_feedback.save()
            
            return Response(
                {'message': 'Feedback updated successfully'},
                status=status.HTTP_200_OK
            )
        else:
            # Create new feedback
            feedback = WorkerFeedback.objects.create(
                job=job,
                worker=worker,
                user=user,
                rating=data['rating'],
                feedback_text=data['feedback_text'],
                work_quality=data.get('work_quality'),
                punctuality=data.get('punctuality'),
                communication=data.get('communication'),
                professionalism=data.get('professionalism'),
                would_hire_again=data.get('would_hire_again', True)
            )
            
            return Response(
                {
                    'message': 'Feedback submitted successfully',
                    'feedback_id': feedback.id
                },
                status=status.HTTP_201_CREATED
            )
    
    except Exception as e:
        print(f"Error submitting worker feedback: {str(e)}")
        return Response(
            {'error': f'An error occurred while submitting feedback: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_worker_feedback(request, worker_id):
    """
    Get all feedback for a specific worker.
    """
    try:
        # Check if worker exists
        try:
            worker = WorkerProfile.objects.get(pk=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get all feedback for this worker
        feedback_list = WorkerFeedback.objects.filter(worker=worker).select_related('user', 'job')
        
        # Calculate average ratings
        if feedback_list.exists():
            total_feedback = feedback_list.count()
            avg_rating = feedback_list.aggregate(models.Avg('rating'))['rating__avg']
            avg_work_quality = feedback_list.filter(work_quality__isnull=False).aggregate(models.Avg('work_quality'))['work_quality__avg']
            avg_punctuality = feedback_list.filter(punctuality__isnull=False).aggregate(models.Avg('punctuality'))['punctuality__avg']
            avg_communication = feedback_list.filter(communication__isnull=False).aggregate(models.Avg('communication'))['communication__avg']
            avg_professionalism = feedback_list.filter(professionalism__isnull=False).aggregate(models.Avg('professionalism'))['professionalism__avg']
            would_hire_again_count = feedback_list.filter(would_hire_again=True).count()
        else:
            total_feedback = 0
            avg_rating = 0
            avg_work_quality = 0
            avg_punctuality = 0
            avg_communication = 0
            avg_professionalism = 0
            would_hire_again_count = 0
        
        # Prepare feedback data
        feedback_data = []
        for feedback in feedback_list:
            feedback_data.append({
                'id': feedback.id,
                'job_title': feedback.job.title,
                'user_name': feedback.user.get_full_name() or feedback.user.username,
                'rating': feedback.rating,
                'feedback_text': feedback.feedback_text,
                'work_quality': feedback.work_quality,
                'punctuality': feedback.punctuality,
                'communication': feedback.communication,
                'professionalism': feedback.professionalism,
                'would_hire_again': feedback.would_hire_again,
                'created_at': feedback.created_at.strftime('%Y-%m-%d %H:%M'),
            })
        
        response_data = {
            'worker': {
                'id': worker.id,
                'name': f"{worker.user.first_name} {worker.user.last_name}".strip() or worker.user.username,
                'profile_pic_url': request.build_absolute_uri(worker.profile_pic.url) if worker.profile_pic else None,
            },
            'summary': {
                'total_feedback': total_feedback,
                'average_rating': round(avg_rating, 2) if avg_rating else 0,
                'average_work_quality': round(avg_work_quality, 2) if avg_work_quality else 0,
                'average_punctuality': round(avg_punctuality, 2) if avg_punctuality else 0,
                'average_communication': round(avg_communication, 2) if avg_communication else 0,
                'average_professionalism': round(avg_professionalism, 2) if avg_professionalism else 0,
                'would_hire_again_percentage': round((would_hire_again_count / total_feedback * 100), 1) if total_feedback > 0 else 0,
            },
            'feedback': feedback_data
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching worker feedback for worker {worker_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Contractor feedback endpoints
@api_view(['POST'])
def submit_contractor_feedback(request):
    """
    Submit feedback for a contractor on a specific job.
    """
    try:
        data = request.data
        
        # Validate required fields
        
        
        # Validate objects exist
        try:
            job = Job.objects.get(pk=data['job_id'])
        except Job.DoesNotExist:
            return Response(
                {'error': 'Job not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        print(job)
        
        try:
            contractor = ContractorProfile.objects.get(user=job.contractor.user)
        except ContractorProfile.DoesNotExist:
            return Response(
                {'error': 'Contractor not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        print(contractor)
        try:
            worker = WorkerProfile.objects.get(user=job.worker.user)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Verify the worker is assigned to this job
        if job.worker != worker:
            return Response(
                {'error': 'You can only provide feedback for jobs assigned to you'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Verify the contractor is associated with this job
        if job.contractor != contractor:
            return Response(
                {'error': 'This contractor is not associated with the specified job'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if feedback already exists
        existing_feedback = ContractorFeedback.objects.filter(
            job=job,
            contractor=contractor,
            worker=worker
        ).first()
        
        if existing_feedback:
            # Update existing feedback
            existing_feedback.rating = data['rating']
            existing_feedback.feedback_text = data['feedback_text']
            existing_feedback.professionalism = data.get('professionalism')
            existing_feedback.communication = data.get('communication')
            existing_feedback.payment_timeliness = data.get('payment_timeliness')
            existing_feedback.job_clarity = data.get('job_clarity')
            existing_feedback.would_work_again = data.get('would_work_again', True)
            existing_feedback.save()
            
            return Response(
                {'message': 'Feedback updated successfully'},
                status=status.HTTP_200_OK
            )
        else:
            # Create new feedback
            feedback = ContractorFeedback.objects.create(
                job=job,
                contractor=contractor,
                worker=worker,
                rating=data['rating'],
                feedback_text=data['feedback_text'],
                professionalism=data.get('professionalism'),
                communication=data.get('communication'),
                payment_timeliness=data.get('payment_timeliness'),
                job_clarity=data.get('job_clarity'),
                would_work_again=data.get('would_work_again', True)
            )
            
            return Response(
                {
                    'message': 'Feedback submitted successfully',
                    'feedback_id': feedback.id
                },
                status=status.HTTP_201_CREATED
            )
    
    except Exception as e:
        print(f"Error submitting contractor feedback: {str(e)}")
        return Response(
            {'error': f'An error occurred while submitting feedback: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_contractor_feedback(request, contractor_id):
    """
    Get all feedback for a specific contractor.
    """
    try:
        # Check if contractor exists
        try:
            contractor = ContractorProfile.objects.get(pk=contractor_id)
        except ContractorProfile.DoesNotExist:
            return Response(
                {'error': 'Contractor not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get all feedback for this contractor
        feedback_list = ContractorFeedback.objects.filter(contractor=contractor).select_related('worker__user', 'job')
        
        # Calculate average ratings
        if feedback_list.exists():
            total_feedback = feedback_list.count()
            avg_rating = feedback_list.aggregate(models.Avg('rating'))['rating__avg']
            avg_professionalism = feedback_list.filter(professionalism__isnull=False).aggregate(models.Avg('professionalism'))['professionalism__avg']
            avg_communication = feedback_list.filter(communication__isnull=False).aggregate(models.Avg('communication'))['communication__avg']
            avg_payment_timeliness = feedback_list.filter(payment_timeliness__isnull=False).aggregate(models.Avg('payment_timeliness'))['payment_timeliness__avg']
            avg_job_clarity = feedback_list.filter(job_clarity__isnull=False).aggregate(models.Avg('job_clarity'))['job_clarity__avg']
            would_work_again_count = feedback_list.filter(would_work_again=True).count()
        else:
            total_feedback = 0
            avg_rating = 0
            avg_professionalism = 0
            avg_communication = 0
            avg_payment_timeliness = 0
            avg_job_clarity = 0
            would_work_again_count = 0
          # Prepare feedback data
        feedback_data = []
        for feedback in feedback_list:
            feedback_data.append({
                'id': feedback.id,
                'job_id': feedback.job.id,  # Add job_id
                'job_title': feedback.job.title,
                'worker_id': feedback.worker.id,  # Add worker_id
                'worker_name': feedback.worker.user.get_full_name() or feedback.worker.user.username,
                'contractor_id': feedback.contractor.id,  # Add contractor_id
                'rating': feedback.rating,
                'feedback_text': feedback.feedback_text,
                'professionalism': feedback.professionalism,
                'communication': feedback.communication,
                'payment_timeliness': feedback.payment_timeliness,
                'job_clarity': feedback.job_clarity,
                'would_work_again': feedback.would_work_again,
                'created_at': feedback.created_at.strftime('%Y-%m-%d %H:%M'),
            })
        
        response_data = {
            'contractor': {
                'id': contractor.id,
                'name': f"{contractor.user.first_name} {contractor.user.last_name}".strip() or contractor.user.username,
                'profile_pic_url': request.build_absolute_uri(contractor.profile_pic.url) if contractor.profile_pic else None,
            },
            'summary': {
                'total_feedback': total_feedback,
                'average_rating': round(avg_rating, 2) if avg_rating else 0,
                'average_professionalism': round(avg_professionalism, 2) if avg_professionalism else 0,
                'average_communication': round(avg_communication, 2) if avg_communication else 0,
                'average_payment_timeliness': round(avg_payment_timeliness, 2) if avg_payment_timeliness else 0,
                'average_job_clarity': round(avg_job_clarity, 2) if avg_job_clarity else 0,
                'would_work_again_percentage': round((would_work_again_count / total_feedback * 100), 1) if total_feedback > 0 else 0,
            },
            'feedback': feedback_data
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching contractor feedback for contractor {contractor_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_worker_completed_jobs_with_contractors(request, worker_id):
    """
    Returns completed jobs for a worker with contractor information (for feedback purposes).
    """
    try:
        # Check if worker exists
        try:
            worker = WorkerProfile.objects.get(user_id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get completed jobs assigned to this worker
        completed_jobs = Job.objects.filter(
            worker=worker,
            status='Completed'
        ).select_related('contractor__user').distinct()
        
        # Extract job and contractor information
        jobs_data = []
        
        for job in completed_jobs:
            # Check if feedback already exists for this job-contractor combination
            existing_feedback = ContractorFeedback.objects.filter(
                job=job,
                contractor=job.contractor,
                worker=worker
            ).first()
            
            job_data = {
                'id': job.id,
                'title': job.title,
                'description': job.description,
                'contractor_id': job.contractor.id,
                'contractor_name': f"{job.contractor.user.first_name} {job.contractor.user.last_name}".strip() or job.contractor.user.username,
                'contractor_email': job.contractor.user.email,
                'contractor_phone': job.contractor.phone,
                'contractor_profile_pic_url': request.build_absolute_uri(job.contractor.profile_pic.url) if job.contractor.profile_pic else None,
                'completion_date': job.updated_at.strftime('%Y-%m-%d') if job.updated_at else None,
                'has_feedback': existing_feedback is not None,
                'feedback_rating': existing_feedback.rating if existing_feedback else None,
            }
            jobs_data.append(job_data)
        
        return Response(jobs_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error fetching completed jobs for worker {worker_id}: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def check_contractor_rating_exists(request, contractor_id, job_id, worker_id):
    """
    Check if a rating already exists for a specific contractor-job-worker combination.
    """
    try:
        # Validate that all entities exist
        try:
            contractor = ContractorProfile.objects.get(pk=contractor_id)
            job = Job.objects.get(pk=job_id)
            worker = WorkerProfile.objects.get(pk=worker_id)
        except (ContractorProfile.DoesNotExist, Job.DoesNotExist, WorkerProfile.DoesNotExist):
            return Response(
                {'exists': False, 'error': 'One or more entities not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if feedback exists
        existing_feedback = ContractorFeedback.objects.filter(
            job=job,
            contractor=contractor,
            worker=worker
        ).first()
        
        if existing_feedback:
            return Response({
                'exists': True,
                'rating_data': {
                    'id': existing_feedback.id,
                    'job_id': existing_feedback.job.id,
                    'contractor_id': existing_feedback.contractor.id,
                    'worker_id': existing_feedback.worker.id,
                    'rating': existing_feedback.rating,
                    'feedback_text': existing_feedback.feedback_text,
                    'professionalism': existing_feedback.professionalism,
                    'communication': existing_feedback.communication,
                    'payment_timeliness': existing_feedback.payment_timeliness,
                    'job_clarity': existing_feedback.job_clarity,
                    'would_work_again': existing_feedback.would_work_again,
                    'created_at': existing_feedback.created_at.strftime('%Y-%m-%d %H:%M'),
                }
            })
        else:
            return Response({'exists': False})
            
    except Exception as e:
        return Response(
            {'exists': False, 'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

