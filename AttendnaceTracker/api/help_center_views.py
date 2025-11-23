from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Division, HelpCenter
import json

@api_view(['GET'])
def get_divisions(request):
    """
    Get all active divisions
    """
    try:
        divisions = Division.objects.filter(is_active=True).order_by('name')
        divisions_data = []
        
        for division in divisions:
            divisions_data.append({
                'id': division.id,
                'name': division.name,
                'description': division.description,
                'help_centers_count': division.help_centers.filter(is_active=True).count(),
                'created_at': division.created_at.isoformat() if division.created_at else None,
            })
        
        return Response(divisions_data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def create_division(request):
    """
    Create a new division
    """
    try:
        data = request.data
        name = data.get('name', '').strip()
        description = data.get('description', '').strip()
        
        if not name:
            return Response({'error': 'Division name is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if division already exists
        if Division.objects.filter(name__iexact=name).exists():
            return Response({'error': 'Division with this name already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        division = Division.objects.create(
            name=name,
            description=description if description else None
        )
        
        return Response({
            'message': 'Division created successfully',
            'division': {
                'id': division.id,
                'name': division.name,
                'description': division.description,
                'created_at': division.created_at.isoformat()
            }
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_help_centers(request):
    """
    Get all help centers grouped by division
    """
    try:
        # Get all active divisions first
        divisions = Division.objects.filter(is_active=True).order_by('name')
        divisions_data = {}
        
        # Initialize all divisions with empty help centers list
        for division in divisions:
            divisions_data[division.name] = {
                'division_id': division.id,
                'division_name': division.name,
                'division_description': division.description,
                'help_centers': []
            }
        
        # Get all help centers and group them by division
        help_centers = HelpCenter.objects.filter(is_active=True).select_related('division').order_by('division__name', 'name')
        
        for help_center in help_centers:
            division_name = help_center.division.name
            if division_name in divisions_data:
                divisions_data[division_name]['help_centers'].append({
                    'id': help_center.id,
                    'name': help_center.name,
                    'division_id': help_center.division.id,
                    'address': help_center.address,
                    'contact_number': help_center.contact_number,
                    'email': help_center.email,
                    'description': help_center.description,
                    'operating_hours': help_center.operating_hours,
                    'created_at': help_center.created_at.isoformat() if help_center.created_at else None,
                })
        
        # Convert to list format
        result = list(divisions_data.values())
        
        return Response(result, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def create_help_center(request):
    """
    Create a new help center
    """
    try:
        data = request.data
        name = data.get('name', '').strip()
        division_id = data.get('division_id')
        address = data.get('address', '').strip()
        contact_number = data.get('contact_number', '').strip()
        email = data.get('email', '').strip()
        description = data.get('description', '').strip()
        operating_hours = data.get('operating_hours', '').strip()
        
        # Validate required fields
        if not all([name, division_id, address, contact_number, description]):
            return Response({'error': 'Name, division, address, contact number, and description are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if division exists
        try:
            division = Division.objects.get(id=division_id, is_active=True)
        except Division.DoesNotExist:
            return Response({'error': 'Invalid division selected'}, status=status.HTTP_400_BAD_REQUEST)
        
        help_center = HelpCenter.objects.create(
            name=name,
            division=division,
            address=address,
            contact_number=contact_number,
            email=email if email else None,
            description=description,
            operating_hours=operating_hours if operating_hours else None
        )
        
        return Response({
            'message': 'Help center created successfully',
            'help_center': {
                'id': help_center.id,
                'name': help_center.name,
                'division': {
                    'id': division.id,
                    'name': division.name
                },
                'address': help_center.address,
                'contact_number': help_center.contact_number,
                'email': help_center.email,
                'description': help_center.description,
                'operating_hours': help_center.operating_hours,
                'created_at': help_center.created_at.isoformat()
            }
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
def update_help_center(request, help_center_id):
    """
    Update an existing help center
    """
    try:
        help_center = get_object_or_404(HelpCenter, id=help_center_id)
        data = request.data
        
        # Update fields if provided
        if 'name' in data:
            help_center.name = data['name'].strip()
        if 'division_id' in data:
            try:
                division = Division.objects.get(id=data['division_id'], is_active=True)
                help_center.division = division
            except Division.DoesNotExist:
                return Response({'error': 'Invalid division selected'}, status=status.HTTP_400_BAD_REQUEST)
        if 'address' in data:
            help_center.address = data['address'].strip()
        if 'contact_number' in data:
            help_center.contact_number = data['contact_number'].strip()
        if 'email' in data:
            help_center.email = data['email'].strip() if data['email'].strip() else None
        if 'description' in data:
            help_center.description = data['description'].strip()
        if 'operating_hours' in data:
            help_center.operating_hours = data['operating_hours'].strip() if data['operating_hours'].strip() else None
        
        help_center.save()
        
        return Response({
            'message': 'Help center updated successfully',
            'help_center': {
                'id': help_center.id,
                'name': help_center.name,
                'division': {
                    'id': help_center.division.id,
                    'name': help_center.division.name
                },
                'address': help_center.address,
                'contact_number': help_center.contact_number,
                'email': help_center.email,
                'description': help_center.description,
                'operating_hours': help_center.operating_hours,
            }
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
def delete_help_center(request, help_center_id):
    """
    Delete (deactivate) a help center
    """
    try:
        help_center = get_object_or_404(HelpCenter, id=help_center_id)
        help_center.is_active = False
        help_center.save()
        
        return Response({'message': 'Help center deleted successfully'}, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET', 'PUT', 'DELETE'])
def help_center_detail(request, help_center_id):
    """
    Handle GET, PUT, and DELETE operations for a specific help center
    """
    try:
        help_center = get_object_or_404(HelpCenter, id=help_center_id)
        
        if request.method == 'GET':
            # Get help center details
            if not help_center.is_active:
                return Response({'error': 'Help center not found'}, status=status.HTTP_404_NOT_FOUND)
            
            return Response({
                'id': help_center.id,
                'name': help_center.name,
                'division_id': help_center.division.id,
                'division': {
                    'id': help_center.division.id,
                    'name': help_center.division.name,
                    'description': help_center.division.description
                },
                'address': help_center.address,
                'contact_number': help_center.contact_number,
                'email': help_center.email,
                'description': help_center.description,
                'operating_hours': help_center.operating_hours,
                'created_at': help_center.created_at.isoformat() if help_center.created_at else None,
            }, status=status.HTTP_200_OK)
        
        elif request.method == 'PUT':
            # Update help center
            data = request.data
            
            # Update fields if provided
            if 'name' in data and data['name'].strip():
                help_center.name = data['name'].strip()
            if 'division_id' in data:
                try:
                    division = Division.objects.get(id=data['division_id'], is_active=True)
                    help_center.division = division
                except Division.DoesNotExist:
                    return Response({'error': 'Invalid division selected'}, status=status.HTTP_400_BAD_REQUEST)
            if 'address' in data and data['address'].strip():
                help_center.address = data['address'].strip()
            if 'contact_number' in data and data['contact_number'].strip():
                help_center.contact_number = data['contact_number'].strip()
            if 'email' in data:
                help_center.email = data['email'].strip() if data['email'] and data['email'].strip() else None
            if 'description' in data and data['description'].strip():
                help_center.description = data['description'].strip()
            if 'operating_hours' in data:
                help_center.operating_hours = data['operating_hours'].strip() if data['operating_hours'] and data['operating_hours'].strip() else None
            
            help_center.save()
            
            return Response({
                'message': 'Help center updated successfully',
                'help_center': {
                    'id': help_center.id,
                    'name': help_center.name,
                    'division_id': help_center.division.id,
                    'division': {
                        'id': help_center.division.id,
                        'name': help_center.division.name
                    },
                    'address': help_center.address,
                    'contact_number': help_center.contact_number,
                    'email': help_center.email,
                    'description': help_center.description,
                    'operating_hours': help_center.operating_hours,
                }
            }, status=status.HTTP_200_OK)
        
        elif request.method == 'DELETE':
            # Delete (deactivate) help center
            help_center.is_active = False
            help_center.save()
            
            return Response({'message': 'Help center deleted successfully'}, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
def update_division(request, division_id):
    """
    Update an existing division
    """
    try:
        division = get_object_or_404(Division, id=division_id, is_active=True)
        data = request.data
        
        name = data.get('name', '').strip()
        description = data.get('description', '').strip()
        
        if not name:
            return Response({'error': 'Division name is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if another division with the same name exists
        if Division.objects.filter(name__iexact=name, is_active=True).exclude(id=division_id).exists():
            return Response({'error': 'Division with this name already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update division
        division.name = name
        division.description = description if description else None
        division.save()
        
        return Response({
            'message': 'Division updated successfully',
            'division': {
                'id': division.id,
                'name': division.name,
                'description': division.description,
                'created_at': division.created_at.isoformat() if division.created_at else None
            }
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
def delete_division(request, division_id):
    """
    Delete (deactivate) a division
    """
    try:
        division = get_object_or_404(Division, id=division_id, is_active=True)
        
        # Check if division has active help centers
        # active_help_centers = division.help_centers.filter(is_active=True).count()
        
        
        # Deactivate division
        division.is_active = False
        division.save()
        
        return Response({'message': 'Division deleted successfully'}, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
