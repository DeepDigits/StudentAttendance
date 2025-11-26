"""
Notification API Views for student attendance notifications.
"""
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from .models import Notification
from datetime import datetime, timedelta
from django.utils import timezone


@api_view(['GET'])
def get_user_notifications(request, user_id):
    """
    Get all notifications for a specific user.
    Returns notifications ordered by most recent first.
    """
    try:
        user = User.objects.get(id=user_id)
        
        # Get all notifications for the user
        notifications = Notification.objects.filter(user=user)
        
        # Build response data
        notifications_list = []
        for notif in notifications:
            # Calculate time ago
            time_diff = timezone.now() - notif.created_at
            if time_diff.days > 0:
                time_ago = f"{time_diff.days} day{'s' if time_diff.days > 1 else ''} ago"
            elif time_diff.seconds >= 3600:
                hours = time_diff.seconds // 3600
                time_ago = f"{hours} hour{'s' if hours > 1 else ''} ago"
            elif time_diff.seconds >= 60:
                minutes = time_diff.seconds // 60
                time_ago = f"{minutes} min ago"
            else:
                time_ago = "Just now"
            
            notifications_list.append({
                'id': notif.id,
                'title': notif.title,
                'description': notif.description,
                'type': notif.notification_type,
                'icon': notif.icon,
                'iconColor': notif.icon_color,
                'time': time_ago,
                'isRead': notif.is_read,
                'createdAt': notif.created_at.isoformat(),
            })
        
        return Response(notifications_list, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_unread_count(request, user_id):
    """
    Get the count of unread notifications for a user.
    """
    try:
        user = User.objects.get(id=user_id)
        unread_count = Notification.objects.filter(user=user, is_read=False).count()
        
        return Response({'unreadCount': unread_count}, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def mark_notification_read(request, notification_id):
    """
    Mark a specific notification as read.
    """
    try:
        notification = Notification.objects.get(id=notification_id)
        notification.is_read = True
        notification.save()
        
        return Response({'message': 'Notification marked as read.'}, status=status.HTTP_200_OK)
        
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def mark_all_notifications_read(request, user_id):
    """
    Mark all notifications as read for a specific user.
    """
    try:
        user = User.objects.get(id=user_id)
        
        # Update all unread notifications to read
        updated_count = Notification.objects.filter(user=user, is_read=False).update(is_read=True)
        
        return Response({
            'message': 'All notifications marked as read.',
            'updatedCount': updated_count
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
def delete_notification(request, notification_id):
    """
    Delete a specific notification.
    """
    try:
        notification = Notification.objects.get(id=notification_id)
        notification.delete()
        
        return Response({'message': 'Notification deleted.'}, status=status.HTTP_200_OK)
        
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def create_class_reminder(request, user_id):
    """
    Create a manual class reminder notification.
    Expected POST data: {'class_name': 'BCA', 'time_minutes': 15}
    """
    try:
        user = User.objects.get(id=user_id)
        
        class_name = request.data.get('class_name', 'Class')
        time_minutes = request.data.get('time_minutes', 15)
        
        Notification.objects.create(
            user=user,
            title='Class Reminder',
            description=f'{class_name} class is starting in {time_minutes} minutes. Room 305, Building A.',
            notification_type='reminder',
            icon='time',
            icon_color='#3498DB',
        )
        
        return Response({'message': 'Reminder created successfully.'}, status=status.HTTP_201_CREATED)
        
    except User.DoesNotExist:
        return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
