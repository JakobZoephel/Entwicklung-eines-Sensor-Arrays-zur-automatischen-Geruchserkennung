public abstract class Dataset {

  final class LoadingFailureException extends RuntimeException {

    LoadingFailureException(Dataset ds, String message) {
      super("Could not load the Dataset, " + ds.getClass().getSimpleName() + " " + message);
    }
  }

  final String name;
  // Dimensionen des Input-Tensors
  final int[] shape;
  int numExamples;
  // Länge der 1D (flachen) Version des Input-Tensors
  final int features;
  final boolean createable;
  private float[][] examples;
  private float[][] labels;
  final String[] classNames;
  final Encoder examplesEncoder;
  final Encoder labelsEncoder;
  int numThreads = 0;

  // damit erbende Klassen super() aufrufen können
  Dataset() {
  }

  {
    name = getName();
    // alle möglichen Klassifizierungen
    classNames = loadStrings(getPath(name + "_classNames.txt"));
    examplesEncoder = new Encoder(getPath(name + "_examples.bin"));
    labelsEncoder = new Encoder(getPath(name + "_labels.bin"));

    shape = loadShape();
    createable = createable();
    int sum = shape[0];
    for (int i = 1; i < shape.length; i++) {
      sum *= shape[i];
    }

    features = sum;
    examplesEncoder.loadMetaData();
    numExamples = examplesEncoder.ARRAY_LENGTH;

    if (features != examplesEncoder.EXAMPLE_SIZE) {
      throw new LoadingFailureException(this, features + " != " + examplesEncoder.EXAMPLE_SIZE);
    }
  }

  Dataset(final int totalExamples, final String examplePath, final int threads) {
    loadAndSave(totalExamples, examplePath, threads);
  }

  // überschreibbar
  String getName() {
    return this.getClass().getSimpleName();
  }

  abstract void loadAndSave(final int totalExamples, final String examplePath, final int threads);
  abstract int[] loadShape();
  abstract boolean createable();
  abstract float[] createExample(String desired);


  final void load(final int numExamples) {
    this.numExamples = numExamples;
    load();
  }

  final void load() {
    if (numThreads <= 0) {
      examples = examplesEncoder.load(numExamples);
      labels = labelsEncoder.load(numExamples);
    } else {
      examples = examplesEncoder.loadThreads(numExamples, numThreads);
      labels = labelsEncoder.loadThreads(numExamples, numThreads);
    }

    // wenn möglich und notwendig, weitere Beispiel generieren
    if (createable) {
      for (int i = examplesEncoder.ARRAY_LENGTH; i < examples.length; i++) {
        int label = i%classNames.length;
        examples[i] = createExample(classNames[label]);
        labels[i] = new float[classNames.length];
        labels[i][label] = 1;
      }
    }
  }


  void split(float split, float[][] train, float[][] test) {
    if (split < 0 || split > 1) {
      throw new LoadingFailureException(this, "split < 0 or split > 1");
    }
    if (examples == null || labels == null) {
      load();
    }

    //train = new float[round(examples.length*split)][];
    //test = new float[round(examples.length*(1-split))][];

    float[][][] shuffled = permut(makePermutation(examples.length, 2), examples, labels);
    examples = shuffled[0];
    labels = shuffled[1];


    // nur pointer setzen
    for (int i = 0; i < train.length; i++) {
      train[i] = examples[i];
    }
    for (int i = 0; i < test.length; i++) {
      test[i] = examples[train.length+i];
    }
  }

  int[] makePermutation(int len, int depth) {

    int[] permut = new int[len];
    for (int i = 0; i < permut.length; i++) {
      permut[i] = i;
    }

    // shuffle
    for (int i = 0; i < permut.length*depth; i++) {
      int firstIndex = int(random(permut.length));
      int secondIndex = int(random(permut.length));

      int a = permut[firstIndex];
      permut[firstIndex] = permut[secondIndex];
      permut[secondIndex] = a;
    }
    return permut;
  }

  float[][][] permut(int[] permutation, float[][] ... arrays) {

    float[][][] copy = arrays.clone();

    for (int i = 0; i < copy.length; i++) {
      for (int j = 0; j < copy[i].length; j++) {
        arrays[i][j] = copy[i][permutation[j]].clone();
      }
    }
    return arrays;
  }
}
