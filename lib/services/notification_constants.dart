class NotificationConstants {
  // Channel IDs
  static const String highImportanceChannelId = 'high_importance_channel';
  static const String customSoundChannelId = 'custom_sound_channel';
  static const String progressChannelId = 'progress_channel';

  // Channel Names
  static const String highImportanceChannelName = 'High Importance Notifications';
  static const String customSoundChannelName = 'Custom Sound Notifications';
  static const String progressChannelName = 'Progress Notifications';

  // Channel Descriptions
  static const String highImportanceChannelDescription = 'This channel is used for important notifications.';
  static const String customSoundChannelDescription = 'Notifications with custom sound.';
  static const String progressChannelDescription = 'This channel is used for progress notifications.';

  // Sound Files (stored in android/app/src/main/res/raw/)
  static const String customSoundFile = 'ketawa'; // ketawa.mp3
  static const String alternativeSound1 = 'hehe'; // hehe.mp3
  static const String alternativeSound2 = 'kaget'; // kaget.mp3

  // Notification Types
  static const String typePromo = 'promo';
  static const String typeBooking = 'booking';
  static const String typeOrder = 'order';
  static const String typeGeneral = 'notification';
}
