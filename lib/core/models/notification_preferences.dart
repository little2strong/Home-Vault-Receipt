class NotificationPreferences {
  const NotificationPreferences({
    this.returnDeadlines = true,
    this.warrantyExpiry = false,
    this.maintenance = false,
    this.newReviewItems = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        returnDeadlines: json['return_deadlines'] as bool? ?? true,
        warrantyExpiry: json['warranty_expiry'] as bool? ?? false,
        maintenance: json['maintenance'] as bool? ?? false,
        newReviewItems: json['new_review_items'] as bool? ?? true,
      );

  final bool returnDeadlines;
  final bool warrantyExpiry;
  final bool maintenance;
  final bool newReviewItems;

  NotificationPreferences copyWith({
    bool? returnDeadlines,
    bool? warrantyExpiry,
    bool? maintenance,
    bool? newReviewItems,
  }) => NotificationPreferences(
    returnDeadlines: returnDeadlines ?? this.returnDeadlines,
    warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
    maintenance: maintenance ?? this.maintenance,
    newReviewItems: newReviewItems ?? this.newReviewItems,
  );

  Map<String, dynamic> toJson() => {
    'return_deadlines': returnDeadlines,
    'warranty_expiry': warrantyExpiry,
    'maintenance': maintenance,
    'new_review_items': newReviewItems,
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.returnDeadlines == returnDeadlines &&
      other.warrantyExpiry == warrantyExpiry &&
      other.maintenance == maintenance &&
      other.newReviewItems == newReviewItems;

  @override
  int get hashCode =>
      Object.hash(returnDeadlines, warrantyExpiry, maintenance, newReviewItems);
}
