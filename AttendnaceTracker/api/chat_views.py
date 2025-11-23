from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.db import models
from django.core.exceptions import ValidationError
from .models import ChatMessage, ContractorProfile
from .serializers import ChatMessageSerializer
from django.contrib.auth.models import User

@api_view(['GET'])
def get_chat_messages(request, worker_id, contractor_id):
    """Get chat messages between a worker and contractor"""
    try:
        # Validate IDs
        if not worker_id or not contractor_id:
            return Response(
                {'error': 'Both worker_id and contractor_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        print(f"Fetching messages between worker_id: {worker_id} and contractor_id: {contractor_id}")
        
        # Get messages where either:
        # 1. Worker sent to contractor, OR
        # 2. Contractor sent to worker
        messages = ChatMessage.objects.filter(
            (models.Q(sender_id=worker_id, receiver_id=contractor_id) |
             models.Q(sender_id=contractor_id, receiver_id=worker_id))
        ).order_by('timestamp')  # Changed to ascending order (oldest first)
        
        print(f"Found {messages} messages")
        serializer = ChatMessageSerializer(messages, many=True)
        return Response({
            'status': 'success',
            'messages': serializer.data
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
def send_message(request):
    """Send a new chat message"""
    try:
        # Basic validation
        if not request.data.get('message', '').strip():
            return Response(
                {'error': 'Message content cannot be empty'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = ChatMessageSerializer(data=request.data)
        if serializer.is_valid():
            message = serializer.save()
            return Response({
                'status': 'success',
                'message': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        return Response({
            'error': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
def mark_messages_read(request, worker_id, contractor_id):
    """Mark messages as read"""
    try:
        if not worker_id or not contractor_id:
            return Response(
                {'error': 'Both worker_id and contractor_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        updated_count = ChatMessage.objects.filter(
            sender_id=contractor_id,
            receiver_id=worker_id,
            is_read=False
        ).update(is_read=True)

        return Response({
            'status': 'success',
            'messages_marked_read': updated_count
        })
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
