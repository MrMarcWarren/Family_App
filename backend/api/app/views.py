from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from .models import CustomUser, GeoTag, Family, Medicine, Note, Reminder, ReminderStatus
from .serializers import (
    MedicineSerializer, RegisterSerializer, UserSerializer,
    GeoTagSerializer, ChangePasswordSerializer,
    FamilySerializer, FamilyDetailSerializer,
    FamilyMemberSerializer, NoteSerializer,
    ReminderSerializer, ReminderStatusSerializer
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

    @action(detail=False, methods=['patch'], url_path='emergency/toggle')
    def emergency_toggle(self, request):
        user = request.user
        user.in_emergency = not user.in_emergency
        user.save()
        return Response({
            "message": f"Emergency status set to {'ON' if user.in_emergency else 'OFF'}.",
            "in_emergency": user.in_emergency
        })

    @action(detail=False, methods=['get'], url_path='emergency/list',
            permission_classes=[permissions.IsAdminUser])
    def emergency_list(self, request):
        users = CustomUser.objects.filter(in_emergency=True).select_related('geotag')
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

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

    @action(detail=True, methods=['patch'], url_path='check-on')
    def check_on(self, request, pk=None):
        target_user = self.get_object()
        requester = request.user

        if target_user == requester:
            return Response(
                {"error": "You cannot check on yourself."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if target_user.family != requester.family or requester.family is None:
            return Response(
                {"error": "You can only check on family members."},
                status=status.HTTP_403_FORBIDDEN
            )

        target_user.checked_on = True
        target_user.save()
        return Response({"message": "Checked on successfully."})

    @action(detail=False, methods=['patch'], url_path='dismiss-check-on')
    def dismiss_check_on(self, request):
        user = request.user
        user.checked_on = False
        user.save()
        return Response({"message": "Check-on dismissed.", "checked_on": False})


class GeoTagViewSet(viewsets.ModelViewSet):
    serializer_class = GeoTagSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return GeoTag.objects.all().select_related('user')

    def get_permissions(self):
        if self.action == 'destroy':
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        user = self.request.user
        if user.geotag:
            raise ValidationError("GeoTag already exists. Use PUT to update.")
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
        if self.action in ['retrieve', 'list', 'members', 'emergency']:
            return FamilyDetailSerializer
        return FamilySerializer

    def get_queryset(self):
        user = self.request.user
        name_query = self.request.query_params.get('name')
        if name_query:
            return Family.objects.filter(name__icontains=name_query).prefetch_related('members')
        if user.is_staff:
            return Family.objects.all().prefetch_related('members')
        if user.family:
            return Family.objects.filter(pk=user.family.pk).prefetch_related('members')
        return Family.objects.none()

    def get_permissions(self):
        if self.action in ['create', 'destroy']:
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticated()]

    @action(detail=True, methods=['post'], url_path='add-member')
    def add_member(self, request, pk=None):
        family = self.get_object()
        user = request.user

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

    @action(detail=True, methods=['get'], url_path='members')
    def members(self, request, pk=None):
        family = self.get_object()
        members = family.members.all().select_related('geotag')
        serializer = FamilyMemberSerializer(members, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='join')
    def join(self, request, pk=None):
        user = request.user

        if user.family is not None:
            return Response(
                {"error": "You are already in a family. Leave your current family first."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            family = Family.objects.get(pk=pk)
        except Family.DoesNotExist:
            return Response({"error": "Family not found."}, status=status.HTTP_404_NOT_FOUND)

        user.family = family
        user.save()
        return Response({"message": f"You have joined {family.name}."})

    @action(detail=True, methods=['get'], url_path='emergency')
    def emergency(self, request, pk=None):
        family = self.get_object()
        members = family.members.filter(in_emergency=True).select_related('geotag')
        serializer = FamilyMemberSerializer(members, many=True)
        return Response(serializer.data)


class NoteViewSet(viewsets.ModelViewSet):
    serializer_class = NoteSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        user = self.request.user
        if user.family:
            return Note.objects.filter(
                creator__family=user.family
            ).select_related('creator')
        return Note.objects.filter(creator=user).select_related('creator')

    def perform_create(self, serializer):
        serializer.save(creator=self.request.user)

    def perform_destroy(self, instance):
        if instance.creator != self.request.user:
            raise PermissionDenied("You can only delete your own notes.")
        instance.delete()

    @action(detail=False, methods=['get'], url_path='mine')
    def mine(self, request):
        notes = Note.objects.filter(creator=request.user)
        serializer = NoteSerializer(notes, many=True, context={'request': request})
        return Response(serializer.data)


class ReminderViewSet(viewsets.ModelViewSet):
    serializer_class = ReminderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Reminder.objects.filter(
            creator=user
        ) | Reminder.objects.filter(
            assigned_to=user
        ).select_related('creator').prefetch_related('assigned_to', 'statuses')

    def perform_create(self, serializer):
        serializer.save(creator=self.request.user)

    @action(detail=False, methods=['get'], url_path='mine')
    def mine(self, request):
        reminders = Reminder.objects.filter(
            assigned_to=request.user
        ).select_related('creator').prefetch_related('assigned_to', 'statuses')
        serializer = ReminderSerializer(reminders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='created')
    def created(self, request):
        reminders = Reminder.objects.filter(
            creator=request.user
        ).prefetch_related('assigned_to', 'statuses')
        serializer = ReminderSerializer(reminders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='pending')
    def pending(self, request):
        reminders = Reminder.objects.filter(
            assigned_to=request.user,
            statuses__user=request.user,
            statuses__status=ReminderStatus.Status.PENDING
        ).prefetch_related('assigned_to', 'statuses')
        serializer = ReminderSerializer(reminders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['patch'], url_path='done')
    def mark_done(self, request, pk=None):
        reminder = self.get_object()
        reminder_status = ReminderStatus.objects.filter(
            reminder=reminder, user=request.user
        ).first()

        if not reminder_status:
            return Response(
                {"error": "This reminder is not assigned to you."},
                status=status.HTTP_403_FORBIDDEN
            )

        reminder_status.status = ReminderStatus.Status.DONE
        reminder_status.save()
        return Response({"message": "Reminder marked as done.", "status": reminder_status.status})

    @action(detail=True, methods=['patch'], url_path='dismiss')
    def dismiss(self, request, pk=None):
        reminder = self.get_object()
        reminder_status = ReminderStatus.objects.filter(
            reminder=reminder, user=request.user
        ).first()

        if not reminder_status:
            return Response(
                {"error": "This reminder is not assigned to you."},
                status=status.HTTP_403_FORBIDDEN
            )

        reminder_status.status = ReminderStatus.Status.DISMISSED
        reminder_status.save()
        return Response({"message": "Reminder dismissed.", "status": reminder_status.status})

    @action(detail=False, methods=['get'], url_path='family')
    def family_reminders(self, request):
        user = request.user

        if not user.family:
            return Response(
                {"error": "You are not part of a family."},
                status=status.HTTP_403_FORBIDDEN
            )

        reminders = Reminder.objects.filter(
            assigned_to__family=user.family
        ).exclude(
            assigned_to=user
        ).select_related('creator').prefetch_related('assigned_to', 'statuses').distinct()

        serializer = ReminderSerializer(reminders, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='user/(?P<user_id>[^/.]+)')
    def user_reminders(self, request, user_id=None):
        user = request.user

        if not user.family:
            return Response(
                {"error": "You are not part of a family."},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            target_user = CustomUser.objects.get(pk=user_id, family=user.family)
        except CustomUser.DoesNotExist:
            return Response(
                {"error": "User not found in your family."},
                status=status.HTTP_404_NOT_FOUND
            )

        reminders = Reminder.objects.filter(
            assigned_to=target_user
        ).select_related('creator').prefetch_related('assigned_to', 'statuses').distinct()

        serializer = ReminderSerializer(reminders, many=True, context={'request': request})
        return Response(serializer.data)


class MedicineViewSet(viewsets.ModelViewSet):
    serializer_class = MedicineSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Medicine.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['patch'], url_path='take')
    def take(self, request, pk=None):
        from django.utils import timezone
        medicine = self.get_object()
        medicine.last_taken_at = timezone.now()
        medicine.save()
        return Response({
            "message": f"{medicine.name} marked as taken.",
            "last_taken_at": medicine.last_taken_at
        })
