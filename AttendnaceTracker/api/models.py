from django.db import models
from django.contrib.auth.models import User # Import Django's built-in User model
from django.utils import timezone # Import timezone if needed for date fields

# Model to store additional Worker details, linked to the standard User model
class WorkerProfile(models.Model):
    # Approval Status Choices
    PENDING = 'Pending'
    APPROVED = 'Approved'
    REJECTED = 'Rejected'
    APPROVAL_STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='worker_profile')
    phone = models.CharField(max_length=15, unique=True)
    adhaar = models.CharField(max_length=12, unique=True)
    address = models.TextField()
    district = models.CharField(max_length=100)
    skills = models.TextField(blank=True, null=True) # Optional
    experience = models.TextField(blank=True, null=True) # Optional
    hourly_rate = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    profile_pic = models.ImageField(upload_to='profile_pics/', blank=True, null=True) # Optional, requires Pillow and media settings
    # Approval fields
    approval_status = models.CharField(
        max_length=10,
        choices=APPROVAL_STATUS_CHOICES,
        default=PENDING,
    )
    rejection_reason = models.TextField(blank=True, null=True) # Reason if status is REJECTED

    def __str__(self):
        # Display user's full name or username if names are blank
        display_name = self.user.get_full_name() or self.user.username
        return f"{display_name} (Worker Profile)"

# Model to store additional Contractor details, linked to the standard User model
class ContractorProfile(models.Model):
    # Approval Status Choices (can reuse from WorkerProfile or define separately)
    PENDING = 'Pending'
    APPROVED = 'Approved'
    REJECTED = 'Rejected'
    APPROVAL_STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='contractor_profile')
    # Name, Email, Password are in the User model
    address = models.TextField()
    district = models.CharField(max_length=100) # Consider choices if predefined
    city = models.CharField(max_length=100)
    division = models.CharField(max_length=100) # Consider choices if predefined
    pincode = models.CharField(max_length=6)
    phone = models.CharField(max_length=15, unique=True) # Make phone unique
    license_no = models.CharField(max_length=100, unique=True) # Make license unique
    profile_pic = models.ImageField(upload_to='contractor_pics/', blank=True, null=True) # Optional
    # Approval fields
    approval_status = models.CharField(
        max_length=10,
        choices=APPROVAL_STATUS_CHOICES,
        default=PENDING,
    )
    rejection_reason = models.TextField(blank=True, null=True) # Reason if status is REJECTED

    # Add any other fields specific to contractors if needed
    # date_joined = models.DateTimeField(default=timezone.now) # Can be inferred from User model

    def __str__(self):
        # Display user's full name or username if names are blank
        display_name = self.user.get_full_name() or self.user.username
        return f"{display_name} (Contractor Profile)"

# Model to store Faculty details, linked to the standard User model
class FacultyProfile(models.Model):
    # Approval Status Choices
    PENDING = 'Pending'
    APPROVED = 'Approved'
    REJECTED = 'Rejected'
    APPROVAL_STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='faculty_profile')
    employee_id = models.CharField(max_length=50, unique=True)
    department = models.CharField(max_length=100)
    phone = models.CharField(max_length=15, unique=True)
    qualifications = models.TextField()
    profile_pic = models.ImageField(upload_to='faculty_pics/', blank=True, null=True)
    # Approval fields
    approval_status = models.CharField(
        max_length=10,
        choices=APPROVAL_STATUS_CHOICES,
        default=PENDING,
    )
    rejection_reason = models.TextField(blank=True, null=True)

    def __str__(self):
        display_name = self.user.get_full_name() or self.user.username
        return f"{display_name} (Faculty Profile)"

# Model to store Student details (merged with UserProfile from AttendanceSystem)
class StudentProfile(models.Model):
    # Approval Status Choices
    PENDING = 'Pending'
    APPROVED = 'Approved'
    REJECTED = 'Rejected'
    APPROVAL_STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    roll_number = models.CharField(max_length=50, unique=True, null=True, blank=True)
    department = models.CharField(max_length=100, null=True, blank=True)
    year_of_study = models.CharField(max_length=20, null=True, blank=True)  # Changed to CharField for flexibility (e.g., "1st Year", "2nd Year")
    section = models.CharField(max_length=10, null=True, blank=True)  # Added section field
    phone = models.CharField(max_length=15, null=True, blank=True)  # Added phone field
    profile_pic = models.ImageField(upload_to='student_pics/', blank=True, null=True)
    # Approval fields
    approval_status = models.CharField(
        max_length=10,
        choices=APPROVAL_STATUS_CHOICES,
        default=PENDING,
    )
    rejection_reason = models.TextField(blank=True, null=True)

    def __str__(self):
        display_name = self.user.get_full_name() or self.user.username
        return f"{display_name} (Student Profile)"


# Model for face recognition (from AttendanceSystem)
class UserProfile(models.Model):
    """Profile information linked to Django's User for face recognition attendance."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone = models.CharField(max_length=15, blank=True)
    student_id = models.CharField(max_length=20, unique=True)
    department = models.CharField(max_length=50, choices=[
        ('BCA', 'BCA'),
        ('BSc', 'BSc'),
        ('BCom', 'BCom'),
        ('Electronics', 'Electronics'),
    ], blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} Profile"


class Attendance(models.Model):
    """Store attendance records for students."""
    STATUS_CHOICES = [
        ('On-Time', 'On-Time'),
        ('Late', 'Late'),
    ]
    
    ACTION_CHOICES = [
        ('Check-In', 'Check-In'),
        ('Check-Out', 'Check-Out'),
    ]
    
    student = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='attendances')
    date = models.DateField(default=timezone.now)
    class_name = models.CharField(max_length=50, choices=[
        ('BCA', 'BCA'),
        ('BSC', 'BSC'),
        ('BCOM', 'BCOM'),
        ('ELECTRONICS', 'ELECTRONICS'),
    ])
    timestamp = models.DateTimeField(default=timezone.now)
    action = models.CharField(max_length=20, choices=ACTION_CHOICES, default='Check-In')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='On-Time')
    
    # Legacy fields - kept for backward compatibility
    check_in_time = models.DateTimeField(null=True, blank=True)
    check_out_time = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-date', '-timestamp']
    
    def __str__(self):
        return f"{self.student.student_id} - {self.action} - {self.date} - {self.class_name}"


class UnknownPerson(models.Model):
    """Store unknown faces detected during attendance."""
    image = models.ImageField(upload_to='unknown_faces/')
    detected_at = models.DateTimeField(auto_now_add=True)
    class_name = models.CharField(max_length=50, blank=True)
    
    class Meta:
        ordering = ['-detected_at']
    
    def __str__(self):
        return f"Unknown person at {self.detected_at}"

# Model for job posting
class Job(models.Model):
    # Job type choices
    FULL_TIME = 'Full Time'
    PART_TIME = 'Part Time'
    SEASONAL = 'Seasonal'
    JOB_TYPE_CHOICES = [
        (FULL_TIME, 'Full Time'),
        (PART_TIME, 'Part Time'),
        (SEASONAL, 'Seasonal'),
    ]
    
    # Work environment choices
    INDOOR = 'Indoor'
    OUTDOOR = 'Outdoor'
    FACTORY = 'Factory'
    WORK_ENVIRONMENT_CHOICES = [
        (INDOOR, 'Indoor'),
        (OUTDOOR, 'Outdoor'),
        (FACTORY, 'Factory'),
    ]
    
    # Job status choices
    PENDING = 'Pending'
    IN_PROGRESS = 'In Progress'
    COMPLETED = 'Completed'
    CANCELLED = 'Cancelled'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (IN_PROGRESS, 'In Progress'),
        (COMPLETED, 'Completed'),
        (CANCELLED, 'Cancelled'),    ]
    
    title = models.CharField(max_length=255)
    description = models.TextField()
    address = models.CharField(max_length=255)
    job_type = models.CharField(max_length=20, choices=JOB_TYPE_CHOICES, default=FULL_TIME)
    work_environment = models.CharField(max_length=20, choices=WORK_ENVIRONMENT_CHOICES, default=INDOOR)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    contractor = models.ForeignKey(ContractorProfile, on_delete=models.CASCADE, related_name='jobs', null=True) # ForeignKey to ContractorProfile
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posted_jobs',null=True) # Optional, if you want to track who posted the job
    worker = models.ForeignKey(WorkerProfile, on_delete=models.SET_NULL, related_name='assigned_jobs', null=True, blank=True) # Worker assigned to this job
    is_active = models.BooleanField(default=True)
    job_posted_date = models.DateTimeField(auto_now_add=True,null=True) # Automatically set the date when the job is created
    
    def __str__(self):
        return f"{self.title} - {self.contractor.user.get_full_name() or self.contractor.user.username}"
    

# Model for payment records
class Payment(models.Model):
    # Payment status choices
    INITIATED = 'initiated'
    COMPLETED = 'completed'
    FAILED = 'failed'
    STATUS_CHOICES = [
        (INITIATED, 'Initiated'),
        (COMPLETED, 'Completed'),
        (FAILED, 'Failed'),
    ]
    
    worker = models.ForeignKey(WorkerProfile, on_delete=models.CASCADE, related_name='payments')
    contractor = models.ForeignKey(ContractorProfile, on_delete=models.CASCADE, related_name='payments_made')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateTimeField(auto_now_add=True)
    razorpay_payment_id = models.CharField(max_length=100, null=True, blank=True)
    razorpay_order_id = models.CharField(max_length=100, null=True, blank=True)
    razorpay_signature = models.CharField(max_length=100, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=INITIATED)
    
    def __str__(self):
        return f"Payment of ₹{self.amount} to {self.worker.user.get_full_name()} by {self.contractor.user.get_full_name()}"

# Model for chat messages
class ChatMessage(models.Model):
    sender_id = models.CharField(max_length=100, db_index=True)
    receiver_id = models.CharField(max_length=100, db_index=True)
    message = models.TextField(blank=False)
    timestamp = models.DateTimeField(default=timezone.now, db_index=True)
    is_read = models.BooleanField(default=False, db_index=True)
    attachment_url = models.URLField(blank=True, null=True)

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['sender_id', 'receiver_id', 'timestamp']),
            models.Index(fields=['receiver_id', 'is_read']),
        ]

    def __str__(self):
        return f"{self.sender_id} -> {self.receiver_id}: {self.message[:50]}"

# Model for complaint submission
class Complaint(models.Model):
    # Complaint status choices
    PENDING = 'Pending'
    IN_REVIEW = 'In Review'
    RESOLVED = 'Resolved'
    REJECTED = 'Rejected'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (IN_REVIEW, 'In Review'),
        (RESOLVED, 'Resolved'),
        (REJECTED, 'Rejected'),
    ]
    
    # Complaint type choices
    HARASSMENT = 'Harassment'
    PAYMENT_ISSUE = 'Payment Issue'
    SAFETY_CONCERN = 'Safety Concern'
    FRAUD = 'Fraud'
    INAPPROPRIATE_BEHAVIOR = 'Inappropriate Behavior'
    OTHER = 'Other'
    TYPE_CHOICES = [
        (HARASSMENT, 'Harassment'),
        (PAYMENT_ISSUE, 'Payment Issue'),
        (SAFETY_CONCERN, 'Safety Concern'),
        (FRAUD, 'Fraud'),
        (INAPPROPRIATE_BEHAVIOR, 'Inappropriate Behavior'),
        (OTHER, 'Other'),
    ]
    complainant_worker = models.ForeignKey(WorkerProfile, on_delete=models.CASCADE, related_name='complaints_filed')
    complained_against_contractor = models.ForeignKey(ContractorProfile, on_delete=models.CASCADE, related_name='complaints_received')
    title = models.CharField(max_length=255)
    description = models.TextField()
    complaint_type = models.CharField(max_length=30, choices=TYPE_CHOICES, default=OTHER)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    admin_response = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Complaint by {self.complainant_worker.user.get_full_name()} against {self.complained_against_contractor.user.get_full_name()}: {self.title}"

# Model for worker feedback
class WorkerFeedback(models.Model):
    # Rating choices
    RATING_CHOICES = [
        (1, '1 - Poor'),
        (2, '2 - Fair'),
        (3, '3 - Good'),
        (4, '4 - Very Good'),
        (5, '5 - Excellent'),
    ]
    
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='feedback')
    worker = models.ForeignKey(WorkerProfile, on_delete=models.CASCADE, related_name='received_feedback')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='given_feedback')  # User who posted the job
    rating = models.IntegerField(choices=RATING_CHOICES)
    feedback_text = models.TextField()
    work_quality = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    punctuality = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    communication = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    professionalism = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    would_hire_again = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['job', 'worker', 'user']  # Prevent duplicate feedback for same job-worker combination
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Feedback for {self.worker.user.get_full_name()} by {self.user.get_full_name()} - {self.rating}/5"

# Model for contractor feedback (by workers)
class ContractorFeedback(models.Model):
    # Rating choices
    RATING_CHOICES = [
        (1, '1 - Poor'),
        (2, '2 - Fair'),
        (3, '3 - Good'),
        (4, '4 - Very Good'),
        (5, '5 - Excellent'),
    ]
    
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='contractor_feedback')
    contractor = models.ForeignKey(ContractorProfile, on_delete=models.CASCADE, related_name='received_feedback')
    worker = models.ForeignKey(WorkerProfile, on_delete=models.CASCADE, related_name='given_contractor_feedback')
    rating = models.IntegerField(choices=RATING_CHOICES)
    feedback_text = models.TextField()
    professionalism = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    communication = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    payment_timeliness = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    job_clarity = models.IntegerField(choices=RATING_CHOICES, null=True, blank=True)
    would_work_again = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['job', 'contractor', 'worker']  # Prevent duplicate feedback for same job-contractor combination
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Feedback for {self.contractor.user.get_full_name()} by {self.worker.user.get_full_name()} - {self.rating}/5"

# Model for geographical/administrative divisions for help centers
class Division(models.Model):
    """
    Represents a geographical or administrative division for organizing help centers.
    This could be districts, regions, departments, or support categories.
    """
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name

# Model for Help Centers
class HelpCenter(models.Model):
    """
    Represents a help center that provides support to workers and contractors.
    Each help center belongs to a specific division for organizational purposes.
    """
    name = models.CharField(max_length=200)
    division = models.ForeignKey(Division, on_delete=models.CASCADE, related_name='help_centers')
    address = models.TextField()
    contact_number = models.CharField(max_length=15)
    email = models.EmailField(blank=True, null=True)
    description = models.TextField()
    operating_hours = models.CharField(max_length=100, blank=True, null=True, help_text="e.g., 9:00 AM - 5:00 PM")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['division__name', 'name']
    
    def __str__(self):
        return f"{self.name} - {self.division.name}"

