from django.contrib import admin
from .models import *  # Import your models here

from .models import Job  # Import the Job model

# Register your models here.
admin.site.register(WorkerProfile)
admin.site.register(ContractorProfile)  # Register ContractorProfile if needed
admin.site.register(FacultyProfile)  # Register FacultyProfile
admin.site.register(StudentProfile)  # Register StudentProfile
admin.site.register(Job)  # Register Job model for admin interface
admin.site.register(Payment)  # Register payment model for admin interface
admin.site.register(ChatMessage)  # Register ChatMessage model for admin interface
admin.site.register(Complaint)  # Register Complaint model for admin interface
admin.site.register(WorkerFeedback)
admin.site.register(Division)  # Register Division model for admin interface
admin.site.register(HelpCenter)  # Register HelpCenter model for admin interface