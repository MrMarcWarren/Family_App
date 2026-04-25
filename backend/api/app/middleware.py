from django.utils import timezone
from django.http import JsonResponse
import datetime

class MedicineReminderMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        # Only check for authenticated users
        if request.user.is_authenticated:
            self.check_overdue_medicines(request)

        return response

    def check_overdue_medicines(self, request):
        from app.models import Medicine
        now = timezone.now()
        today = now.date()

        overdue = Medicine.objects.filter(
            user=request.user,
            is_active=True,
        ).exclude(
            last_taken_at__date=today     # exclude already taken today
        )

        skipped = []
        for medicine in overdue:
            scheduled_dt = timezone.make_aware(
                datetime.datetime.combine(today, medicine.scheduled_time)
            )
            if now > scheduled_dt:
                time_str = medicine.scheduled_time.strftime("%I:%M %p")
                skipped.append({
                    "medicine": medicine.name,
                    "message": f"You were supposed to take {medicine.name} at {time_str}"
                })

        # Attach to request so views can access it if needed
        request.overdue_medicines = skipped