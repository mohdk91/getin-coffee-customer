String homeGreetingForHour(int hour) {
  final normalized = hour < 0 ? 0 : (hour > 23 ? 23 : hour);
  if (normalized < 12) return 'Good morning';
  if (normalized < 17) return 'Good afternoon';
  return 'Good evening';
}
