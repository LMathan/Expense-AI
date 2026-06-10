String getCategoryEmoji(String category) {
  switch (category) {
    case 'Food':
      return '🍔';
    case 'Travel':
      return '🚗';
    case 'Shopping':
      return '🛍️';
    case 'Entertainment':
      return '🎬';
    case 'Bills':
      return '🧾';
    case 'Healthcare':
      return '🏥';
    case 'Education':
      return '🎓';
    case 'Rent':
      return '🏠';
    case 'EMI':
      return '💳';
    case 'Fuel':
      return '⛽';
    case 'Services':
      return '⚙️';
    default:
      return '📦';
  }
}
