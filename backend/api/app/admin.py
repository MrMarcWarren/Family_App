from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, GeoTag, Family, Note


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
    list_display = ['sender', 'receiver', 'content', 'is_read', 'created_at']
    list_filter = ['is_read']
    search_fields = ['sender__username', 'receiver__username', 'content']