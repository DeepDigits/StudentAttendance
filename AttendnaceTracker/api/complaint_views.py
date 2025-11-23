from django.http import JsonResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from .models import Complaint, WorkerProfile, ContractorProfile
from .serializers import ComplaintSerializer
import json
from django.contrib.auth.models import User

@api_view(['POST'])
def submit_complaint(request):
    """
    Submit a new complaint
    """
    try:
        # Get data from request
        data = request.data if hasattr(request, 'data') else json.loads(request.body)
        print("Received data:", data)
        
        # Get worker and contractor profiles
        worker_id = data.get('complainant_worker_id')
        contractor_id = data.get('complained_against_contractor_id')
        
        if not worker_id or not contractor_id:
            return Response(
                {'error': 'Worker ID and Contractor ID are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get the worker and contractor profiles
        try:
            wu = User.objects.get(id=worker_id)
            worker_profile = WorkerProfile.objects.get(user=wu)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        try:
            contractor_profile = ContractorProfile.objects.get(id=contractor_id)
        except ContractorProfile.DoesNotExist:
            return Response(
                {'error': 'Contractor not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Create complaint data
        complaint_data = {
            'title': data.get('title'),
            'description': data.get('description'),
            'complaint_type': data.get('complaint_type', 'Other'),
            'complainant_worker': worker_profile.id,
            'complained_against_contractor': contractor_profile.id
        }
        
        # Validate and save complaint
        serializer = ComplaintSerializer(data=complaint_data)
        if serializer.is_valid():
            complaint = serializer.save()
            print("Complaint saved successfully:", complaint.id)
            return Response(
                {
                    'message': 'Complaint submitted successfully',
                    'complaint_id': complaint.id,
                    'data': serializer.data
                }, 
                status=status.HTTP_201_CREATED
            )
        else:
            print("Serializer errors:", serializer.errors)
            return Response(
                {'error': 'Invalid data', 'details': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
    except Exception as e:
        print("Exception occurred:", str(e))
        return Response(
            {'error': f'An error occurred: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_worker_complaints(request, worker_id):
    print(worker_id)
    """
    Get all complaints filed by a specific worker
    """
    user = User.objects.filter(id=worker_id).first()
    worker_profile = get_object_or_404(WorkerProfile, user=user)
    print(worker_profile)
    complaints = Complaint.objects.filter(complainant_worker=worker_profile)
    serializer = ComplaintSerializer(complaints, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)
    # except Exception as e:
    #     return Response(
    #         {'error': f'An error occurred: {str(e)}'}, 
    #         status=status.HTTP_500_INTERNAL_SERVER_ERROR
    #     )

@api_view(['GET'])
def get_complaint_types(request):
    """
    Get all available complaint types
    """
    try:
        complaint_types = [
            {'value': choice[0], 'label': choice[1]} 
            for choice in Complaint.TYPE_CHOICES
        ]
        return Response(complaint_types, status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {'error': f'An error occurred: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def test_endpoint(request):
    """
    Simple test endpoint to verify server is working
    """
    return Response({'message': 'Django server is working correctly'}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_all_complaints(request):
    """
    Returns a list of all complaints for admin dashboard
    """
    try:
        complaints = Complaint.objects.all().order_by('-created_at')
        data = []
        for complaint in complaints:
            # Get worker and contractor names
            worker_name = f"{complaint.complainant_worker.user.first_name} {complaint.complainant_worker.user.last_name}".strip()
            contractor_name = f"{complaint.complained_against_contractor.user.first_name} {complaint.complained_against_contractor.user.last_name}".strip()
            
            # Format created_at date
            created_at = complaint.created_at.strftime('%Y-%m-%d %H:%M:%S') if complaint.created_at else None
              # Get profile picture URLs
            worker_profile_pic = None
            contractor_profile_pic = None
            
            if complaint.complainant_worker.profile_pic:
                worker_profile_pic = request.build_absolute_uri(complaint.complainant_worker.profile_pic.url)
            
            if complaint.complained_against_contractor.profile_pic:
                contractor_profile_pic = request.build_absolute_uri(complaint.complained_against_contractor.profile_pic.url)
            
            data.append({
                'id': complaint.id,
                'subject': complaint.title,
                'description': complaint.description,
                'status': complaint.status,
                'complaint_type': complaint.complaint_type,
                'priority': 'high' if complaint.complaint_type in ['Harassment', 'Safety Concern'] else 'medium',
                'worker_name': worker_name,
                'worker_email': complaint.complainant_worker.user.email,
                'worker_phone': complaint.complainant_worker.phone or 'N/A',
                'worker_id': complaint.complainant_worker.id,
                'worker_profile_pic': worker_profile_pic,
                'contractor_name': contractor_name,
                'contractor_email': complaint.complained_against_contractor.user.email,
                'contractor_phone': complaint.complained_against_contractor.phone or 'N/A',
                'contractor_id': complaint.complained_against_contractor.id,
                'contractor_profile_pic': contractor_profile_pic,
                'created_at': created_at,
                'updated_at': complaint.updated_at.strftime('%Y-%m-%d %H:%M:%S') if complaint.updated_at else None,
            })
        
        return Response(data, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"Error fetching complaints: {str(e)}")
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
def update_complaint_status(request, complaint_id):
    """
    Updates the status of a complaint - for admin use
    """
    try:
        complaint = Complaint.objects.get(id=complaint_id)
        
        # Get data from request
        data = request.data
        
        if 'status' not in data:
            return Response(
                {'error': 'Status field is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate that the status is one of the valid choices
        valid_statuses = [choice[0] for choice in Complaint.STATUS_CHOICES]
        if data['status'] not in valid_statuses:
            return Response(
                {'error': f'Invalid status value. Valid options: {valid_statuses}'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Update the complaint status
        old_status = complaint.status
        complaint.status = data['status']
        
        # Optionally update admin response if provided
        if 'admin_response' in data:
            complaint.admin_response = data['admin_response']
        
        complaint.save()
        
        return Response({
            'message': 'Complaint status updated successfully',
            'complaint_id': complaint.id,
            'old_status': old_status,
            'new_status': complaint.status
        }, status=status.HTTP_200_OK)
        
    except Complaint.DoesNotExist:
        return Response(
            {'error': 'Complaint not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
