from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

# Create your models here.


class UserProfile(models.Model):
	"""Profile information linked to Django's User."""
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
