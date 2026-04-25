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


class Family(models.Model):
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name_plural = 'Families'


class CustomUser(AbstractUser):

    class Mood(models.TextChoices):
        SAD = 'sad', 'Sad'
        HAPPY = 'happy', 'Happy'
        EXCITED = 'excited', 'Excited'
        CRYING = 'crying', 'Crying'
        ANGRY = 'angry', 'Angry'

    phone = models.CharField(max_length=20, blank=True, null=True)
    birthday = models.DateField(blank=True, null=True)
    mood = models.CharField(max_length=10, choices=Mood.choices, default=Mood.HAPPY)
    in_emergency = models.BooleanField(default=False)
    is_adult = models.BooleanField(default=False)          # ← replaces role
    geotag = models.OneToOneField(GeoTag, on_delete=models.SET_NULL, null=True, blank=True, related_name='user')
    family = models.ForeignKey(Family, on_delete=models.SET_NULL, null=True, blank=True, related_name='members')

    def __str__(self):
        return self.username

class Note(models.Model):
    creator = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='notes')
    content = models.CharField(max_length=280)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.creator.username}: {self.content[:30]}"

    class Meta:
        ordering = ['-created_at']

class Reminder(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        DONE = 'done', 'Done'
        DISMISSED = 'dismissed', 'Dismissed'

    creator = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='created_reminders')
    assigned_to = models.ManyToManyField(CustomUser, related_name='reminders')   # ← ManyToMany
    title = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    remind_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.title} by {self.creator.username}"

    class Meta:
        ordering = ['remind_at']

class ReminderStatus(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        DONE = 'done', 'Done'
        DISMISSED = 'dismissed', 'Dismissed'

    reminder = models.ForeignKey(Reminder, on_delete=models.CASCADE, related_name='statuses')
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='reminder_statuses')
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['reminder', 'user']  # one status per user per reminder

    def __str__(self):
        return f"{self.reminder.title} → {self.user.username}: {self.status}"

class Medicine(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='medicines')
    name = models.CharField(max_length=100)
    dosage = models.CharField(max_length=100, blank=True, null=True)  # e.g. "500mg"
    scheduled_time = models.TimeField()                               # e.g. 15:00 for 3pm
    is_active = models.BooleanField(default=True)
    last_taken_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.name} at {self.scheduled_time}"

    class Meta:
        ordering = ['scheduled_time']