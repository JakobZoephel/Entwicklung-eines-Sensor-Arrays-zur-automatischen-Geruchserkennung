class ResultScreen extends Window {

  @Override
    void setup() {

    surface.setLocation(displayWidth/2-width/2+OFFSET_X, displayHeight/2-height/2-OFFSET_Y);
    surface.setTitle("Ergebnis");
    if (!DEBUG) {
      // erst starten, wenn der Arduino Daten sendet
      surface.setVisible(false);
    }
    rectMode(CENTER);
    textAlign(CENTER, CENTER);
    noLoop();
  }

  String modelResult = "?";
  String knnResult = "?";
  String knnSoftmaxResult = "?";


  @Override
    void draw() {

    background(255);

    fill(TEXT_COLOR);
    textSize(35);
    text("Hmmm... sieht aus, als wäre es", width/2, height/4);
    fill(0, 100, 0);
    text(modelResult, width/2, height/2);

    textSize(17);
    text("KNN: " + knnResult, width/2, height/2+80);
    text("Mit Softmax: " + knnSoftmaxResult, width/2, height/2+160);
  }

  void update(float[] werte) {

    knnResult = sniff(werte, 0, false);
    knnSoftmaxResult = sniff(werte, 0, true);
    modelResult = model.ds.classNames[F.max_pool_index(model.feedForward(werte))];

    redraw();
  }


  String sniff(float[] _currExample, int depth, boolean softmax) {

    if (examples.size() == 0)
      return "?";

    // das jetzige Beispiel
    float[] example = _currExample.clone();
    // die Vergleichsbeispiele
    float[][] prevExamples = F.toFloatArray(examples);

    if (softmax) {
      for (int i = 0; i < example.length; i++) {
        example[i] = skaliere(example[i], maxValues[i], 1);
      }
      example = F.softmax(example);
    }

    for (int i = 0; i < prevExamples.length; i++) {
      if (softmax) {
        for (int j = 0; j < prevExamples[i].length; j++) {
          prevExamples[i][j] = skaliere(prevExamples[i][j], maxValues[j], 1);
        }
        prevExamples[i] = F.softmax(prevExamples[i]);
      }
    }
    return K_NN(example, prevExamples, F.toStringArray(labels), F.toStringArray(classNames), depth);
  }
}
