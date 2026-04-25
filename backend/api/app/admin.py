from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, GeoTag, Family, Medicine, Note, Reminder, ReminderStatus


@admin.register(Family)
class FamilyAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'created_at']
    search_fields = ['name']


@admin.register(GeoTag)
class GeoTagAdmin(admin.ModelAdmin):
    list_display = ['label', 'latitude', 'longitude', 'address', 'created_at']
    search_fields = ['label', 'address']


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'email', 'phone', 'mood', 'in_emergency', 'is_adult', 'birthday', 'family']
    list_filter = ['mood', 'in_emergency', 'is_adult', 'family']
    search_fields = ['username', 'email', 'phone']

    fieldsets = UserAdmin.fieldsets + (
        ('Contact & Status', {
            'fields': ('phone', 'birthday', 'mood', 'in_emergency', 'is_adult', 'geotag', 'family')
        }),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Contact & Status', {
            'fields': ('phone', 'birthday', 'mood', 'in_emergency', 'is_adult', 'family')
        }),
    )


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ['creator', 'content', 'created_at']
    search_fields = ['creator__username', 'content']

@admin.register(Reminder)
class ReminderAdmin(admin.ModelAdmin):
    list_display = ['title', 'creator', 'remind_at', 'created_at']
    search_fields = ['title', 'creator__username']
    filter_horizontal = ['assigned_to']     # ← nice UI for ManyToMany in admin

@admin.register(ReminderStatus)
class ReminderStatusAdmin(admin.ModelAdmin):
    list_display = ['reminder', 'user', 'status', 'updated_at']
    list_filter = ['status']
    search_fields = ['reminder__title', 'user__username']

@admin.register(Medicine)
class MedicineAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'dosage', 'scheduled_time', 'is_active', 'last_taken_at']
    list_filter = ['is_active']
    search_fields = ['name', 'user__username']