import json
from django.db import IntegrityError
from django.contrib.auth import authenticate
from django.http import JsonResponse
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework import status
from django.views.decorators.csrf import csrf_exempt
from .models import *  # Import all models including Payment

# @csrf_exempt
@api_view(['POST'])
def create_payment_record(request):
    print("Creating payment record...")
    """
    Creates a payment record in the database.
    """
    
        # Get data from request
    data = json.loads(request.body)
    worker_id = data.get('worker_id')
    contractor_id = data.get('contractor_id')
    amount = data.get('amount')
    razorpay_payment_id = data.get('razorpay_payment_id', None)
    razorpay_order_id = data.get('razorpay_order_id', None)
    razorpay_signature = data.get('razorpay_signature', None)
    status_value = data.get('status', Payment.INITIATED)
    print(f"Received data: {data}")
    # Validate required fields
    # if not all([worker_id, contractor_id, amount]):
    #     return Response(
    #         {'error': 'Worker ID, contractor ID, and amount are required'},
    #         status=status.HTTP_400_BAD_REQUEST
    #     )
    
    # Get worker and contractor objects
    # try:
    worker = WorkerProfile.objects.get(id=worker_id)
    contractor = ContractorProfile.objects.get(user=User.objects.get(id=contractor_id).id)
    # except (WorkerProfile.DoesNotExist, ContractorProfile.DoesNotExist):
    #     return JsonResponse(
    #         {'error': 'Worker or contractor not found'},
    #         status=status.HTTP_404_NOT_FOUND
    #     )
    
    # Create payment record
    payment = Payment.objects.create(
        worker=worker,
        contractor=contractor,
        amount=amount,
        razorpay_payment_id=razorpay_payment_id,
        razorpay_order_id=razorpay_order_id,
        razorpay_signature=razorpay_signature,
        status=status_value
    )
    
    # Return success response with payment ID
    return JsonResponse({
        'message': 'Payment record created successfully',
        'payment_id': payment.id
    }, status=status.HTTP_201_CREATED)
        
    # except Exception as e:
    #     return JsonResponse(
    #         {'error': str(e)},
    #         status=status.HTTP_500_INTERNAL_SERVER_ERROR
    #     )

@api_view(['PUT'])
@csrf_exempt
def update_payment_status(request, payment_id):
    """
    Updates a payment record's status and details.
    """
    try:
        # Find the payment record
        try:
            payment = Payment.objects.get(id=payment_id)
        except Payment.DoesNotExist:
            return Response(
                {'error': 'Payment record not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get data from request
        data = request.data
        
        # Update fields if provided
        if 'razorpay_payment_id' in data:
            payment.razorpay_payment_id = data['razorpay_payment_id']
        if 'razorpay_order_id' in data:
            payment.razorpay_order_id = data['razorpay_order_id']
        if 'razorpay_signature' in data:
            payment.razorpay_signature = data['razorpay_signature']
        if 'status' in data:
            payment.status = data['status']
        
        # Save changes
        payment.save()
        
        # Return success response
        return Response({
            'message': 'Payment record updated successfully',
            'status': payment.status
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_worker_jobs(request, worker_id):
    """
    Returns all jobs assigned to a specific worker.
    """
    try:
        # Check if worker exists
        try:
            worker = WorkerProfile.objects.get(id=worker_id)
        except WorkerProfile.DoesNotExist:
            return Response(
                {'error': 'Worker not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get jobs assigned to the worker
        jobs = Job.objects.filter(worker=worker, is_active=True)
        
        # Prepare response data
        jobs_data = []
        for job in jobs:
            jobs_data.append({
                'id': job.id,
                'title': job.title,
                'description': job.description,
                'address': job.address,
                'status': job.status,
                'job_type': job.job_type,
                'work_environment': job.work_environment,
                'contractor_name': job.contractor.user.get_full_name() or job.contractor.user.username if job.contractor else 'Unknown',
                'job_posted_date': job.job_posted_date.strftime('%d %b %Y') if job.job_posted_date else None
            })
        
        return Response(jobs_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
