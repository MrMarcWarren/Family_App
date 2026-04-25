from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import CustomUser, Family, GeoTag, Medicine, Note, Reminder, ReminderStatus

class GeoTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = GeoTag
        fields = ['id', 'latitude', 'longitude', 'label', 'address', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class FamilySerializer(serializers.ModelSerializer):
    class Meta:
        model = Family
        fields = ['id']                 # ← only id
        read_only_fields = ['id']


class FamilyDetailSerializer(serializers.ModelSerializer):
    """Used by admin or when fetching full family info"""
    members = serializers.SerializerMethodField()
    total_members = serializers.SerializerMethodField()

    class Meta:
        model = Family
        fields = ['id', 'name', 'total_members', 'members', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_members(self, obj):
        members = obj.members.all().select_related('geotag')
        return FamilyMemberSerializer(members, many=True).data

    def get_total_members(self, obj):
        return obj.members.count()


class FamilyMemberSerializer(serializers.ModelSerializer):
    geotag = GeoTagSerializer(read_only=True)

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'first_name', 'last_name', 'phone', 'mood', 'in_emergency', 'is_adult', 'geotag']
        read_only_fields = fields


class UserSerializer(serializers.ModelSerializer):
    mood_display = serializers.CharField(source='get_mood_display', read_only=True)
    geotag = GeoTagSerializer(read_only=True)
    family = FamilySerializer(read_only=True)
    family_id = serializers.PrimaryKeyRelatedField(
        queryset=Family.objects.all(),
        source='family',
        write_only=True,
        required=False,
        allow_null=True
    )

    class Meta:
        model = CustomUser
        fields = [
            'id', 'username', 'email',
            'first_name', 'last_name',
            'phone', 'birthday',
            'mood', 'mood_display', 'mood_updated_at',
            'in_emergency', 'is_adult',
            'checked_on',                                # ← no checked_on_by
            'geotag',
            'family', 'family_id',
            'date_joined'
        ]
        read_only_fields = ['id', 'date_joined', 'mood_updated_at', 'checked_on']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)
    geotag = GeoTagSerializer(required=False)

    class Meta:
        model = CustomUser
        fields = [
            'id', 'username', 'email',
            'first_name', 'last_name',
            'phone', 'birthday',
            'mood', 'in_emergency', 'is_adult',
            'family',
            'geotag',
            'password', 'password2'
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        password = validated_data.pop('password')
        geotag_data = validated_data.pop('geotag', None)

        user = CustomUser(**validated_data)
        user.set_password(password)
        user.save()

        if geotag_data:
            geotag = GeoTag.objects.create(**geotag_data)
            user.geotag = geotag
            user.save()

        return user

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True, write_only=True, label="Confirm New Password")

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({"new_password": "Passwords do not match."})
        return attrs

class NoteSerializer(serializers.ModelSerializer):
    creator = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = Note
        fields = ['id', 'creator', 'content', 'created_at']
        read_only_fields = ['id', 'creator', 'created_at']

class ReminderStatusSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = ReminderStatus
        fields = ['user', 'status', 'status_display', 'updated_at']


class ReminderSerializer(serializers.ModelSerializer):
    creator = serializers.StringRelatedField(read_only=True)
    assigned_to = serializers.StringRelatedField(many=True, read_only=True)
    assigned_to_ids = serializers.PrimaryKeyRelatedField(
        queryset=CustomUser.objects.all(),
        many=True,
        write_only=True,
        source='assigned_to'
    )
    statuses = ReminderStatusSerializer(many=True, read_only=True)

    class Meta:
        model = Reminder
        fields = [
            'id', 'creator',
            'assigned_to', 'assigned_to_ids',
            'title', 'description', 'remind_at',
            'statuses',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'creator', 'created_at', 'updated_at']

    def validate_assigned_to_ids(self, assigned_to_list):
        creator = self.context['request'].user

        for member in assigned_to_list:
            # Can assign to yourself
            if member == creator:
                continue
            # Must be in the same family
            if member.family != creator.family or creator.family is None:
                raise serializers.ValidationError(
                    f"{member.username} is not a member of your family."
                )

        return assigned_to_list

    def create(self, validated_data):
        assigned_to_list = validated_data.pop('assigned_to', [])
        reminder = Reminder.objects.create(**validated_data)

        # Add assignees and create a status for each
        for user in assigned_to_list:
            reminder.assigned_to.add(user)
            ReminderStatus.objects.create(reminder=reminder, user=user)

        return reminder

    def update(self, instance, validated_data):
        assigned_to_list = validated_data.pop('assigned_to', None)
        instance.title = validated_data.get('title', instance.title)
        instance.description = validated_data.get('description', instance.description)
        instance.remind_at = validated_data.get('remind_at', instance.remind_at)
        instance.save()

        if assigned_to_list is not None:
            # Remove statuses for removed assignees
            removed = instance.assigned_to.exclude(pk__in=[u.pk for u in assigned_to_list])
            ReminderStatus.objects.filter(reminder=instance, user__in=removed).delete()

            # Add statuses for new assignees
            for user in assigned_to_list:
                instance.assigned_to.add(user)
                ReminderStatus.objects.get_or_create(reminder=instance, user=user)

            # Remove old assignees
            instance.assigned_to.set(assigned_to_list)

        return instance

class MedicineSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    is_overdue = serializers.SerializerMethodField()
    skip_message = serializers.SerializerMethodField()

    class Meta:
        model = Medicine
        fields = [
            'id', 'user', 'name', 'dosage',
            'scheduled_time', 'is_active',
            'last_taken_at', 'is_overdue',
            'skip_message', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'last_taken_at', 'created_at']

    def get_is_overdue(self, obj):
        from django.utils import timezone
        import datetime
        now = timezone.now()
        scheduled_dt = timezone.make_aware(
            datetime.datetime.combine(now.date(), obj.scheduled_time)
        )
        # Overdue if past scheduled time and not taken today
        if obj.last_taken_at:
            return obj.last_taken_at.date() < now.date() and now > scheduled_dt
        return now > scheduled_dt

    def get_skip_message(self, obj):
        if self.get_is_overdue(obj):
            time_str = obj.scheduled_time.strftime("%I:%M %p")
            return f"You were supposed to take {obj.name} at {time_str}"
        return None