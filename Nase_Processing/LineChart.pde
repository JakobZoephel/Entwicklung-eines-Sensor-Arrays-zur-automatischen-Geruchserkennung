class LineChart extends Window {

  final int RAND = 40;
  int gap;

  @Override
    void setup() {

    surface.setTitle("Alle vergangenen Messwerte");
    surface.setResizable(true);
    surface.setLocation(displayWidth/2-width/2+OFFSET_X, displayHeight/2-height/2+OFFSET_Y);
    if (!DEBUG) {
      // erst starten, wenn der Arduino Daten sendet
      surface.setVisible(false);
    }
    noLoop();
    textSize(14);
  }

  @Override
    void draw() {

    // Beispiele noch nicht geladen
    if (examples.size() == 0) {
      return;
    }

    background(255);

    // .0001, damit es kein /0 gibt
    gap = round((width-2*RAND) / (examples.size()-savedDurchgaenge-1.0001));

    for (int wert = 0; wert < werte.length; wert++) {

      stroke(chartColors[wert]);
      noFill();

      beginShape();
      for (int durchgang = savedDurchgaenge; durchgang < examples.size(); durchgang++) {
        vertex(RAND+(durchgang-savedDurchgaenge)*gap, height-RAND - skaliere(examples.get(durchgang)[wert], maxValues[wert], height-2*RAND));
      }
      endShape();
    }

    fill(0);
    textAlign(CENTER, CENTER);
    textSize(13);

    // fill(100, 0, 0);
    text("Relative Konzentration in Prozent", RAND/2 + textWidth("Relative Konzentration in Prozent")/2, RAND/2);
    // fill(255, 0, 0);
    text(100, RAND-textWidth(str(100)), RAND);
    //fill(0, 100, 0);
    text("Zeit in Messdurchgängen", width-RAND/2-textWidth("Zeit in Messdurchgängen")/2, height-RAND+20);
    // fill(0, 255, 0);
    text(examples.size()-savedDurchgaenge, width-RAND-RAND/2, height-RAND+10);
    text((examples.size()/1.-savedDurchgaenge)/2, (width-2*RAND)/2, height-RAND+10);

    strokeWeight(1);
    stroke(50);
    // y
    line(RAND, height-RAND, RAND, RAND);
    // x
    line(RAND, height-RAND, width-RAND, height-RAND);
  }
}
