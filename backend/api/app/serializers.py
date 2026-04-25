from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import CustomUser, GeoTag

class GeoTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = GeoTag
        fields = ['id', 'latitude', 'longitude', 'label', 'address', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    mood_display = serializers.CharField(source='get_mood_display', read_only=True)  # renamed
    geotag = GeoTagSerializer(read_only=True)

    class Meta:
        model = CustomUser
        fields = [
            'id', 'username', 'email',
            'first_name', 'last_name',
            'phone', 'birthday',
            'mood', 'mood_display',        # renamed from status/status_display
            'in_emergency', 'geotag',
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
            'mood',                        # renamed from status
            'in_emergency', 'geotag',
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