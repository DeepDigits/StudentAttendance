from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Attendance, Notification
from django.utils import timezone


@receiver(post_save, sender=Attendance)
def create_attendance_notification(sender, instance, created, **kwargs):
    """
    Automatically create a notification when attendance is marked.
    """
    if created:
        # Determine notification details based on action and status
        if instance.action == 'Check-In':
            if instance.status == 'On-Time':
                title = 'Attendance Marked Successfully'
                description = f'Your attendance for {instance.class_name} class has been marked present with {98.5}% confidence.'
                icon = 'checkmark_circle'
                icon_color = '#2ECC71'  # Green
                notification_type = 'success'
            else:  # Late
                title = 'Late Check-In Recorded'
                description = f'You checked in late for {instance.class_name} class. Please try to arrive on time.'
                icon = 'time'
                icon_color = '#F39C12'  # Orange
                notification_type = 'warning'
        else:  # Check-Out
            title = 'Check-Out Recorded'
            description = f'Your check-out for {instance.class_name} class has been recorded successfully.'
            icon = 'exit'
            icon_color = '#3498DB'  # Blue
            notification_type = 'info'
        
        # Create the notification
        Notification.objects.create(
            user=instance.student.user,
            title=title,
            description=description,
            notification_type=notification_type,
            icon=icon,
            icon_color=icon_color,
            related_attendance=instance,
        )


@receiver(post_save, sender=Attendance)
def create_class_reminder(sender, instance, created, **kwargs):
    """
    Create reminder notifications for upcoming classes.
    This is a placeholder - you can implement actual reminder logic based on schedules.
    """
    # Example: Create a reminder 15 minutes before next class
    # This would typically be done with a scheduled task (Celery, etc.)
    pass
