from django.contrib.auth.models import AbstractUser
from django.db import models

class GeoTag(models.Model):
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    label = models.CharField(max_length=100, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.label} ({self.latitude}, {self.longitude})"


class CustomUser(AbstractUser):

    class Mood(models.TextChoices):
        SAD = 'sad', 'Sad'
        HAPPY = 'happy', 'Happy'
        EXCITED = 'excited', 'Excited'
        CRYING = 'crying', 'Crying'
        ANGRY = 'angry', 'Angry'

    phone = models.CharField(max_length=20, blank=True, null=True)
    birthday = models.DateField(blank=True, null=True)
    mood = models.CharField(           # renamed from status
        max_length=10,
        choices=Mood.choices,
        default=Mood.HAPPY
    )
    in_emergency = models.BooleanField(default=False)
    geotag = models.OneToOneField(
        GeoTag,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='user'
    )

    def __str__(self):
        return self.username