class BarChart extends Window {

  int len, w;

  @Override
    void setup() {

    surface.setTitle("Jetzige Messwerte");
    surface.setResizable(true);
    surface.setLocation(displayWidth/2-width/2-OFFSET_X, displayHeight/2-height/2+OFFSET_Y);
    if (!DEBUG) {
      // erst starten, wenn der Arduino Daten sendet
      surface.setVisible(false);
    }
    noLoop();
    textSize(16);
    // Temperatur und Luftfeuchtigkeit auslassen
    len = NAMES.length-2;
    w = width/2/len;
  }

  @Override
    void draw() {

    background(250);

    stroke(50);
    for (int i = 0; i < len; i++) {
      fill(chartColors[i]);
      rect(width/len*i+w/2, height, w, -int(skaliere(werte[i], maxValues[i], height)));
    }

    noStroke();
    fill(10);
    textSize(14);
    textAlign(CENTER, CENTER);
    for (int i = 0; i < len; i++) {
      text(NAMES[i], width/len*i+w, height-30);
    }

    textSize(16);
    text(proxy.temp + " °C", 50, 50);
    text(werte[len] + " %", width-50, 50);
    if (savedDurchgaenge == examples.size()) {
      text("kalibriere..." + (proxy.KALI_DURCHGAENGE-messDurchgang), width/2-textWidth("kalibriere... x")/2, 50);
    } else {
      text("Messdurchgang: " + ( examples.size()-savedDurchgaenge), width/2-textWidth("Messdurchgang: ")/2, 50);
    }
    fill(50);

    // 1/6
    text(100/6 + " %", 20, height - height/6);
    // 2/6
    text(200/6 + " %", 20, height - height/3);
    // 3/6
    text(300/6 + " %", 20, height/2);
    // 4/6
    text(400/6 + " %", 20, height - 2*height/3);
    // 5/6
    text(500/6 + " %", 20, height - 5*height/6);

    stroke(100);
    strokeWeight(1);
    // 1/6
    line(40, height - height/6, width, height - height/6);
    // 2/6
    line(40, height - height/3, width, height - height/3);
    // 3/6
    line(40, height/2, width, height/2);
    // 4/6
    line(40, height - 2*height/3, width, height - 2*height/3);
    // 5/6
    line(40, height - 5*height/6, width, height - 5*height/6);
  }
}
