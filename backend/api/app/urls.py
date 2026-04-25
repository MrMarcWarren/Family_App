from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import AuthViewSet, FamilyViewSet, MedicineViewSet, NoteViewSet, ReminderViewSet, UserViewSet, GeoTagViewSet

router = DefaultRouter()
router.register(r'auth', AuthViewSet, basename='auth')
router.register(r'users', UserViewSet, basename='users')
router.register(r'geotags', GeoTagViewSet, basename='geotags')
router.register(r'families', FamilyViewSet, basename='families')
router.register(r'notes', NoteViewSet, basename='notes')
router.register(r'reminders', ReminderViewSet, basename='reminders')
router.register(r'medicines', MedicineViewSet, basename='medicines')


urlpatterns = [
    path('', include(router.urls)),
    path('auth/login/', TokenObtainPairView.as_view(), name='login'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
]