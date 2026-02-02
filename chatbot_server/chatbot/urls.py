from django.urls import path
from .views import chat_view, available_time_slots_view, my_appointments_view

urlpatterns = [
    path("", chat_view, name="chat"),
    path("available-time-slots/", available_time_slots_view, name="available_time_slots"),
    path("appointments/", my_appointments_view, name="my_appointments"),
]