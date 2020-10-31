extension Max<T extends num> on List<T> {
  T maxOrNull() {
    if (isEmpty) {
      return null;
    }
    var max = this[0];
    for (var i = 1; i < length; ++i) {
      if (this[i] > max) {
        max = this[i];
      }
    }
    return max;
  }
}
