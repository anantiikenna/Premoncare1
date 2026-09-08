String formatNairaAmount(double amount) {
  final formatted = amount.toStringAsFixed(0);
  return formatted.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}
