class Proxy {

  Serial myPort;

  // empfangene Daten
  String prevPortStream, portStream = "";
  /* wie viele Sensorwerte bereits empfangen wurden
   (counter == werte.length ? => counter == 0; messDurchgang++;) */
  int dataCounter = 0;
  // Sensorkalibrierung. Aus wie vielen Messdurchgängen die Umgebungskonzentration ohne Geruch berechnet werden soll
  final int KALI_DURCHGAENGE = 8;
  float[][] kaliWerte = new float[KALI_DURCHGAENGE][werte.length];
  // Durchschnitt der Kalibrierungswerte
  float[] meanWerte = new float[werte.length];

  // Variablenwerte einmalig über den Serial-Bus an den Arduino senden
  boolean dataSend = false;
  // Temperatur
  float temp = 0;
  // den ersten Messdurchgang ignorieren, da sonst vielleicht nicht alle Messwerte aufgezeichnet werden
  boolean ignoredFirst = false;

  Proxy() {

    try {
      myPort = new Serial(MAIN, Serial.list()[0], 19200);
      myPort.bufferUntil('\n');
      myPort.clear();
    }
    catch(IndexOutOfBoundsException e) {
      println("Bitte das Kabel des Arduinos einstecken!");
    }
  }

  void update() {

    if (myPort == null) {
      try {
        myPort = new Serial(MAIN, Serial.list()[0], 19200);
        myPort.bufferUntil('\n');
        myPort.clear();
      }
      catch(IndexOutOfBoundsException e) {
        return;
      }
    }

    if (!dataSend && millis() > 3000) {
      myPort.write(char(KALI_DURCHGAENGE));
      dataSend = true;
    }

    // neues serialEvent (siehe serialEvent())
    if (portStream.length() <= 2 || portStream.equals(prevPortStream)) {
      return;
    }
    //portStream = portStream.trim();
    println(portStream);
    prevPortStream = portStream;

    // Ein Daten-Set wurde empfangen
    if (dataCounter >= werte.length) {

      if (messDurchgang < KALI_DURCHGAENGE) {

        for (int i = 0; i < werte.length; i++) {
          kaliWerte[messDurchgang][i] = werte[i];
        }
      } else if (messDurchgang == KALI_DURCHGAENGE) {

        // am Ende der Kalibrierung Durchschnitt berechnen
        for (int i = 0; i < meanWerte.length; i++) {
          float sum = 0;
          for (int j = 0; j < KALI_DURCHGAENGE; j++) {
            sum += kaliWerte[j][i];
          }
          meanWerte[i] = sum/KALI_DURCHGAENGE;
        }
      }
      dataCounter = 0;

      /* bevor examples.add(werte.clone()), sonst ergibt das K-NN keinen Sinn,
       da das Ergenmis bereits in den prev_examples wäre */
      if (messDurchgang > KALI_DURCHGAENGE+1) {
        resultScreen.update(werte.clone());
      }

      // wenn start-Messung Button aktiviert wurde
      if (started) {
        if (!ignoredFirst) {
          ignoredFirst = true;
          return;
        }
        examples.add(werte.clone());
        labels.add(labelList.getLabel());

        // update max values
        for (int i = 0; i < examples.size(); i++) {
          for (int j = 0; j < examples.get(i).length; j++) {
            if (examples.get(i)[j] > maxValues[j]) {
              maxValues[j] = examples.get(i)[j];
            }
          }
        }
      }
      messDurchgang++;
      println("messDurchgang: " + messDurchgang);
    }

    // Sensor-Wert empfangenn
    if (portStream.split(" ").length == 2) {

      String name = portStream.split(" ")[0];
      float wert = float(portStream.split(" ")[1].trim());

      // ändert sich meist mit Zunahme der Zeit, wird deshalb für die "werte" ignoriert
      if (name.equals("Temperatur")) {
        temp = wert;
        return;
      }

      int index = getElement(name);
      if (index != -1) {
        werte[index] = wert - meanWerte[index];
        dataCounter++;
        barChart.redraw();
        lineChart.redraw();
      }
      // Counter empfangen
    } else if (DEBUG && portStream.split(" ").length == 3) {

      String name = portStream.split(" ")[0];
      int val = int(portStream.split(" ")[2].trim());
      if (name.equals("loopCounter") && val != messDurchgang) {
        if (val-messDurchgang == 1)
          println("Eine Messdurchgang ist verloren gegangen! " + messDurchgang);
        else
          println(val-messDurchgang + " Messdurchgänge sind verloren gegangen!", val, messDurchgang);
      }
    }
  }


  int getElement(String name) {
    for (int i = 0; i < werte.length; i++) {
      if (NAMES[i].equals(name)) {
        return i;
      }
    }
    return -1;
  }

  void serialEvent(Serial myPort) {
    portStream = myPort.readString().trim();

    if (portStream.equals("Starting reading of sensors")) {
      surface.setVisible(true);
      for (Window w : APPLETS) {
        w.getSurface().setVisible(true);
      }
    }
  }
}
