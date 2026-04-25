from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import CustomUser, Family, GeoTag

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
    family = FamilySerializer(read_only=True)               # ← shows only id
    family_id = serializers.PrimaryKeyRelatedField(         # ← allows setting family by id
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
            'mood', 'mood_display',
            'in_emergency', 'is_adult',
            'geotag',
            'family', 'family_id',
            'date_joined'
        ]
        read_only_fields = ['id', 'date_joined']


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

