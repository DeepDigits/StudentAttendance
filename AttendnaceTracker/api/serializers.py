from rest_framework import serializers
from .models import ChatMessage, Complaint

class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ['id', 'sender_id', 'receiver_id', 'message', 'timestamp', 'is_read', 'attachment_url']
        read_only_fields = ['id', 'timestamp']

class ComplaintSerializer(serializers.ModelSerializer):
    complainant_worker_name = serializers.CharField(source='complainant_worker.user.get_full_name', read_only=True)
    complained_against_contractor_name = serializers.CharField(source='complained_against_contractor.user.get_full_name', read_only=True)
    
    class Meta:
        model = Complaint
        fields = [
            'id', 'title', 'description', 'complaint_type', 'status',
            'created_at', 'updated_at', 'admin_response',
            'complainant_worker', 'complained_against_contractor',
            'complainant_worker_name', 'complained_against_contractor_name'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'status', 'admin_response']
