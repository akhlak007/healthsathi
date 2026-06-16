enum ReminderType {
  medicine,
  appointment,
  vaccination;

  String get displayName {
    switch (this) {
      case ReminderType.medicine:
        return 'Medicine';
      case ReminderType.appointment:
        return 'Appointment';
      case ReminderType.vaccination:
        return 'Vaccination';
    }
  }

  static ReminderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'appointment':
        return ReminderType.appointment;
      case 'vaccination':
        return ReminderType.vaccination;
      case 'medicine':
      default:
        return ReminderType.medicine;
    }
  }
}
