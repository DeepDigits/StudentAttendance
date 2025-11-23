from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from .models import ContractorProfile, Job, WorkerProfile
import json

@api_view(['GET'])
def contractor_stats(request, contractor_id):
    """
    Return statistics for a contractor dashboard.
    """
    try:
        # Try to get the contractor profile first
        user = User.objects.get(id=contractor_id)
        contractor = ContractorProfile.objects.get(user=user)
        
        # Count active jobs
        active_jobs_count = Job.objects.filter(contractor=contractor, is_active=True).count()
        
        # Count completed jobs
        completed_jobs_count = Job.objects.filter(contractor=contractor, is_active=False).count()
        
        # Count workers hired
        # This would typically be based on job assignments or a separate relationship
        # For now, just count the number of different workers across jobs
        worker_ids = Job.objects.filter(contractor=contractor).values_list('worker_id', flat=True).distinct()
        workers_hired_count = len([wid for wid in worker_ids if wid is not None])
        
        # Calculate growth (dummy values for now)
        # In a real app, you would compare current stats with previous period
        active_jobs_growth = "+20%" if active_jobs_count > 0 else "0%"
        workers_hired_growth = "+15%" if workers_hired_count > 0 else "0%"
        completed_jobs_growth = "+30%" if completed_jobs_count > 0 else "0%"
        
        stats = [
            {
                "title": "Active Jobs",
                "count": active_jobs_count,
                "icon": "business_center_outlined",
                "color": "#4A6FE6",
                "growth": active_jobs_growth
            },
            {
                "title": "Workers Hired",
                "count": workers_hired_count,
                "icon": "people_outline",
                "color": "#E67E22",
                "growth": workers_hired_growth
            },
            {
                "title": "Completed Jobs",
                "count": completed_jobs_count,
                "icon": "check_circle_outline",
                "color": "#2ECC71",
                "growth": completed_jobs_growth
            },
            {
                "title": "Total Jobs",
                "count": active_jobs_count + completed_jobs_count,
                "icon": "work_outline",
                "color": "#9B59B6",
                "growth": "+25%"
            }
        ]
        
        return Response(stats, status=status.HTTP_200_OK)
    
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except ContractorProfile.DoesNotExist:
        return Response({"error": "Contractor profile not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def contractor_jobs(request, contractor_id):
    """
    Return a list of jobs associated with a contractor.
    """
    # try:
    user = User.objects.get(id=contractor_id)
    contractor = ContractorProfile.objects.get(user=user)
        # Get only active jobs for this contractor
    jobs = Job.objects.filter(contractor=contractor).order_by('-job_posted_date')
    print(jobs)
    # Format jobs as a list of dictionaries
    jobs_list = []
    for job in jobs:
        # Get the worker assigned to this job if available
        worker_data = None
        if hasattr(job, 'worker') and job.worker:
            worker = job.worker
            worker_data = {
                "id": worker.id,
                "name": f"{worker.user.first_name} {worker.user.last_name}",
                "email": worker.user.email
            }
        job_data = {
            "id": job.id,
            "title": job.title,
            "description": job.description,
            "address": job.address,
            "job_type": job.job_type,
            "work_environment": job.work_environment,
            "job_posted_date": job.job_posted_date,
            "is_active": job.is_active,
            "status": job.status,
            "worker": worker_data
        }
        jobs_list.append(job_data)
    
    return Response(jobs_list, status=status.HTTP_200_OK)
    
    # except User.DoesNotExist:
    #     return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    # except ContractorProfile.DoesNotExist:
    #     return Response({"error": "Contractor profile not found"}, status=status.HTTP_404_NOT_FOUND)
    # except Exception as e:
    #     return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def create_job_with_worker(request):
    """
    Create a job posting with a worker assignment.
    """
    try:
        data = json.loads(request.body)
          # Validate required fields
        required_fields = ['title', 'description', 'address', 'job_type', 
                           'work_environment', 'contractor_id', 'worker_id', 'user_id']
        for field in required_fields:
            if field not in data:
                return Response({"error": f"Missing required field: {field}"}, 
                                status=status.HTTP_400_BAD_REQUEST)
          # Get contractor and worker
        contractor_user = User.objects.get(id=data['contractor_id'])
        contractor = ContractorProfile.objects.get(user=contractor_user)
        
        # Get worker by worker profile ID instead of user ID
        try:
            # First try to get worker directly by ID (if worker_id is a WorkerProfile ID)
            worker = WorkerProfile.objects.get(id=data['worker_id'])
        except WorkerProfile.DoesNotExist:
            # If that fails, try to get worker by user ID (if worker_id is a User ID)
            try:
                worker_user = User.objects.get(id=data['worker_id'])
                worker = WorkerProfile.objects.get(user=worker_user)
            except (User.DoesNotExist, WorkerProfile.DoesNotExist):
                return Response({"error": "Worker not found"}, status=status.HTTP_404_NOT_FOUND)
        
        # Create the job
        job = Job.objects.create(
            title=data['title'],
            description=data['description'],
            address=data['address'],
            job_type=data['job_type'],
            work_environment=data['work_environment'],
            contractor=contractor,
            user=contractor_user,
            worker=worker
        )
        
        return Response({
            "message": "Job created successfully",
            "job_id": job.id
        }, status=status.HTTP_201_CREATED)
    
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except ContractorProfile.DoesNotExist:
        return Response({"error": "Contractor profile not found"}, status=status.HTTP_404_NOT_FOUND)
    except WorkerProfile.DoesNotExist:
        return Response({"error": "Worker profile not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
