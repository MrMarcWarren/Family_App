from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import time, timedelta

from app.models import CustomUser, Family, GeoTag, Medicine, Note, Reminder, ReminderStatus


class Command(BaseCommand):
    help = 'Seeds the database with demo data for hackathon presentation.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Delete existing demo data before creating new data.',
        )

    def handle(self, *args, **options):
        if options['reset']:
            self.stdout.write('Clearing existing demo data...')
            CustomUser.objects.filter(username__in=['admin_demo', 'papa_jose', 'mama_maria', 'kuya_carlo']).delete()
            Family.objects.filter(name='Dela Cruz Family').delete()

        self.stdout.write('Creating demo family...')
        family, _ = Family.objects.get_or_create(name='Dela Cruz Family')

        self.stdout.write(f'Family ID: {family.pk}  ← give this to judges for "Join a Family"')

        # Admin user
        admin = self._create_user('admin_demo', 'Admin123!', family, is_staff=True, is_superuser=True,
                                   first_name='Admin', mood='happy', is_adult=True,
                                   lat='14.576400', lng='121.085100')

        # Parent 1
        papa = self._create_user('papa_jose', 'Demo1234!', family, first_name='Jose',
                                  last_name='Dela Cruz', mood='happy', is_adult=True,
                                  phone='+639171234567', lat='14.577100', lng='121.084500')

        # Parent 2
        mama = self._create_user('mama_maria', 'Demo1234!', family, first_name='Maria',
                                  last_name='Dela Cruz', mood='excited', is_adult=True,
                                  phone='+639179876543', lat='14.575800', lng='121.085900')

        # Child
        child = self._create_user('kuya_carlo', 'Demo1234!', family, first_name='Carlo',
                                   last_name='Dela Cruz', mood='sad', is_adult=False,
                                   lat='14.576200', lng='121.085300')

        self.stdout.write('Creating medicines...')
        Medicine.objects.get_or_create(user=papa, name='Metformin', defaults={
            'dosage': '500mg', 'scheduled_time': time(8, 0), 'is_active': True,
        })
        Medicine.objects.get_or_create(user=papa, name='Losartan', defaults={
            'dosage': '50mg', 'scheduled_time': time(20, 0), 'is_active': True,
        })
        Medicine.objects.get_or_create(user=mama, name='Vitamin C', defaults={
            'dosage': '1000mg', 'scheduled_time': time(7, 30), 'is_active': True,
        })

        self.stdout.write('Creating notes...')
        for content in [
            'Kamusta Kayo?',
            'Mag-ingat sa byahe!',
            'Miss ko na kayo\'ng lahat!',
            'Handa na ang hapunan.',
        ]:
            Note.objects.get_or_create(creator=mama, content=content)

        self.stdout.write('Creating reminders...')
        remind_soon = timezone.now() + timedelta(hours=2)
        remind_tomorrow = timezone.now() + timedelta(days=1)

        r1, created = Reminder.objects.get_or_create(
            creator=mama, title='Take Vitamins',
            defaults={'description': 'Don\'t forget your Vitamin C!', 'remind_at': remind_soon}
        )
        if created:
            r1.assigned_to.add(child)
            ReminderStatus.objects.get_or_create(reminder=r1, user=child)

        r2, created = Reminder.objects.get_or_create(
            creator=papa, title='Doctor Appointment',
            defaults={'description': 'Annual check-up at 3PM', 'remind_at': remind_tomorrow}
        )
        if created:
            r2.assigned_to.add(mama)
            ReminderStatus.objects.get_or_create(reminder=r2, user=mama)

        r3, created = Reminder.objects.get_or_create(
            creator=admin, title='Family Dinner',
            defaults={'description': 'Everyone at home by 7PM', 'remind_at': remind_tomorrow}
        )
        if created:
            for member in [papa, mama, child]:
                r3.assigned_to.add(member)
                ReminderStatus.objects.get_or_create(reminder=r3, user=member)

        self.stdout.write(self.style.SUCCESS('\nDemo data ready!'))
        self.stdout.write('─' * 40)
        self.stdout.write(f'Family name : Dela Cruz Family')
        self.stdout.write(f'Family ID   : {family.pk}')
        self.stdout.write('─' * 40)
        self.stdout.write('Accounts (username / password):')
        self.stdout.write('  admin_demo   / Admin123!  (admin)')
        self.stdout.write('  papa_jose    / Demo1234!')
        self.stdout.write('  mama_maria   / Demo1234!')
        self.stdout.write('  kuya_carlo   / Demo1234!')
        self.stdout.write('─' * 40)

    def _create_user(self, username, password, family, first_name='', last_name='',
                     mood='happy', is_adult=False, is_staff=False, is_superuser=False,
                     phone=None, lat=None, lng=None):
        if CustomUser.objects.filter(username=username).exists():
            self.stdout.write(f'  {username} already exists, skipping.')
            return CustomUser.objects.get(username=username)

        geotag = None
        if lat and lng:
            geotag = GeoTag.objects.create(latitude=lat, longitude=lng, label=first_name)

        user = CustomUser.objects.create_user(
            username=username,
            password=password,
            first_name=first_name,
            last_name=last_name,
            mood=mood,
            is_adult=is_adult,
            is_staff=is_staff,
            is_superuser=is_superuser,
            family=family,
            geotag=geotag,
            phone=phone or '',
        )
        self.stdout.write(f'  Created {username}')
        return user
