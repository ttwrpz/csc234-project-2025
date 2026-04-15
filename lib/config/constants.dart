class AppConstants {
  static const appName = 'MoodBloom';
  static const maxTextLength = 500;
  static const maxAttachmentSizeMB = 5;
  static const maxAttachmentSizeBytes = maxAttachmentSizeMB * 1024 * 1024;
  static const maxVideoSeconds = 30;
  static const entriesPerPage = 20;
  static const gardenDaysRange = 30;
  static const defaultAnimationSpeed = 2.0;
  static const minAnimationSpeed = 1.0;
  static const maxAnimationSpeed = 5.0;

  // SharedPreferences keys
  static const prefOnboardingSeen = 'onboarding_seen';
  static const prefAnimationSpeed = 'animation_speed';
  static const prefNotificationsEnabled = 'notifications_enabled';
  static const prefDarkMode = 'dark_mode';

  // Firestore collections
  static const usersCollection = 'users';
  static const moodsCollection = 'moods';

  // Storage paths
  static const moodAttachmentsPath = 'mood_attachments';
}
