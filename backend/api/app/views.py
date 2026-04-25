from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import CustomUser, Family, GeoTag
from .serializers import (
    FamilyDetailSerializer, FamilySerializer, RegisterSerializer, UserSerializer,
    GeoTagSerializer, ChangePasswordSerializer
)
from app import serializers


class AuthViewSet(viewsets.GenericViewSet):
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['post'])
    def register(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Admins see all users, regular users see only themselves
        if self.request.user.is_staff:
            return CustomUser.objects.all().select_related('geotag')
        return CustomUser.objects.filter(pk=self.request.user.pk).select_related('geotag')

    def get_serializer_class(self):
        if self.action == 'create':
            return RegisterSerializer
        return UserSerializer

    def get_permissions(self):
        if self.action in ['create']:
            return [permissions.AllowAny()]
        if self.action in ['destroy', 'list']:
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticated()]

    # PATCH /api/users/change-password/
    @action(detail=False, methods=['patch'], url_path='change-password')
    def change_password(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            if not user.check_password(serializer.validated_data['old_password']):
                return Response(
                    {"old_password": "Incorrect password."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({"message": "Password changed successfully."})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # PATCH /api/users/emergency/toggle/
    @action(detail=False, methods=['patch'], url_path='emergency/toggle')
    def emergency_toggle(self, request):
        user = request.user
        user.in_emergency = not user.in_emergency
        user.save()
        return Response({
            "message": f"Emergency status set to {'ON' if user.in_emergency else 'OFF'}.",
            "in_emergency": user.in_emergency
        })

    # GET /api/users/emergency/list/
    @action(detail=False, methods=['get'], url_path='emergency/list',
            permission_classes=[permissions.IsAdminUser])
    def emergency_list(self, request):
        users = CustomUser.objects.filter(in_emergency=True).select_related('geotag')
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

    # GET /api/users/me/
    @action(detail=False, methods=['get', 'put', 'patch'], url_path='me')
    def me(self, request):
        user = request.user
        if request.method == 'GET':
            serializer = UserSerializer(user)
            return Response(serializer.data)
        serializer = UserSerializer(user, data=request.data, partial=request.method == 'PATCH')
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class GeoTagViewSet(viewsets.ModelViewSet):
    serializer_class = GeoTagSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return GeoTag.objects.all().select_related('user')  # ← all users see all geotags

    def get_permissions(self):
        if self.action == 'destroy':
            return [permissions.IsAdminUser()]   # only admin can delete
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        user = self.request.user
        if user.geotag:
            raise serializers.ValidationError("GeoTag already exists. Use PUT to update.")
        geotag = serializer.save()
        user.geotag = geotag
        user.save()

    def perform_destroy(self, instance):
        user = self.request.user
        instance.delete()
        user.geotag = None
        user.save()

    @action(detail=False, methods=['get', 'put', 'patch', 'delete'], url_path='me')
    def me(self, request):
        user = request.user

        if not user.geotag:
            return Response({"message": "No geotag found."}, status=status.HTTP_404_NOT_FOUND)

        if request.method == 'GET':
            serializer = GeoTagSerializer(user.geotag)
            return Response(serializer.data)

        if request.method in ['PUT', 'PATCH']:
            serializer = GeoTagSerializer(
                user.geotag,
                data=request.data,
                partial=request.method == 'PATCH'
            )
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        if request.method == 'DELETE':
            user.geotag.delete()
            user.geotag = None
            user.save()
            return Response({"message": "GeoTag removed successfully."}, status=status.HTTP_204_NO_CONTENT)

class FamilyViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        # Use detailed serializer for retrieve, list; simple for others
        if self.action in ['retrieve', 'list', 'members', 'emergency']:
            return FamilyDetailSerializer
        return FamilySerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Family.objects.all().prefetch_related('members')
        if user.family:
            return Family.objects.filter(pk=user.family.pk).prefetch_related('members')
        return Family.objects.none()

    def get_permissions(self):
        if self.action in ['create', 'destroy']:
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticated()]

    # POST /api/families/{id}/add-member/
    @action(detail=True, methods=['post'], url_path='add-member')
    def add_member(self, request, pk=None):
        family = self.get_object()
        user = request.user

        # Only adults or staff can add members
        if not user.is_staff and not user.is_adult:
            return Response(
                {"error": "Only adults can add members."},
                status=status.HTTP_403_FORBIDDEN
            )
        user_id = request.data.get('user_id')
        try:
            member = CustomUser.objects.get(pk=user_id)
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        member.family = family
        member.save()
        return Response({"message": f"{member.username} added to {family.name}."})

    # POST /api/families/{id}/remove-member/
    @action(detail=True, methods=['post'], url_path='remove-member')
    def remove_member(self, request, pk=None):
        family = self.get_object()
        user = request.user

        if not user.is_staff and not user.is_adult:
            return Response(
                {"error": "Only adults can remove members."},
                status=status.HTTP_403_FORBIDDEN
            )
        user_id = request.data.get('user_id')
        try:
            member = CustomUser.objects.get(pk=user_id, family=family)
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found in this family."}, status=status.HTTP_404_NOT_FOUND)

        member.family = None
        member.save()
        return Response({"message": f"{member.username} removed from {family.name}."})

    # GET /api/families/{id}/members/
    @action(detail=True, methods=['get'], url_path='members')
    def members(self, request, pk=None):
        family = self.get_object()
        members = family.members.all().select_related('geotag')
        serializer = FamilyMemberSerializer(members, many=True)
        return Response(serializer.data)

    # GET /api/families/{id}/emergency/
    @action(detail=True, methods=['get'], url_path='emergency')
    def emergency(self, request, pk=None):
        family = self.get_object()
        members = family.members.filter(in_emergency=True).select_related('geotag')
        serializer = FamilyMemberSerializer(members, many=True)
        return Response(serializer.data)