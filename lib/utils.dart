extension Max on List<num> {
  num maxOrNull() {
    if (this.isEmpty) {
      return null;
    }
    var max = this[0];
    for (var i = 1; i < this.length; ++i) {
      if (this[i] > max) {
        max = this[i];
      }
    }
    return max;
  }
}
