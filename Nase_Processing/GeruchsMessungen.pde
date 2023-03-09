class GeruchsMessungen extends Dataset {

  // public zum Erstellen der Instanz mit Reflections
  public GeruchsMessungen() {
    super();
  }

  GeruchsMessungen(final int totalExamples, final String examplePath, final int threads) {
    super(totalExamples, examplePath, threads);
  }

  final int[] loadShape() {
    // werte.length
    return new int[]{NAMES.length-1};
  }

  final boolean createable() {
    return false;
  }

  float[] createExample(String desired) {
    return null;
  }

  void loadAndSave(final int totalExamples, final String examplePath, final int threads) {
    // sind bereits in dem richtigen Format gespeichert worden
    examplesEncoder.load(totalExamples);
  }
}
