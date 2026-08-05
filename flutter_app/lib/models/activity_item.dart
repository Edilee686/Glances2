enum ActivityKind { likedYou, message, youLiked }

class ActivityItem {
  const ActivityItem({
    required this.personId,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.unread,
  });

  final String personId;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final String timeLabel;
  final bool unread;
}
