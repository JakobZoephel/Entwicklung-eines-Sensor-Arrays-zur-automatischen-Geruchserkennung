/*
 * @author Jakob Zöphel
 * @date 20.02.2023
 */

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import processing.serial.*;

// Pointer für Serial
final PApplet MAIN = this;
final Functions F = new Functions();

final BarChart barChart;
final ResultScreen resultScreen;
final LineChart lineChart;

// damit man alle auf einmal freezen/deFreezen kann
final Window[] APPLETS = new Window[]{
  barChart = new BarChart(),
  lineChart = new LineChart(),
  resultScreen  = new ResultScreen()
};

String EXAMPLES_FILE;
String LABELS_FILE;
String CLASS_NAMES_FILE;
String WEIGHTS_FILE;
final String MODEL_NAME = "GeruchsMessungen";

// Files, von denen vor dem Überschreiben ein Backup erstellt werden soll
String[] BACKUP_FILES;

Encoder examplesEncoder, weightsEncoder;

//für Paths etc.
final char SLASH = System.getProperty("os.name").toLowerCase().contains("win") ?  '\\' : '/';
/* momentan noch hard-coded, später vielleicht vom Arduino schicken lassen?
 so hat es natürlich den Vorteil, dass man gleich alles auf einem Blick sieht */
final String[] NAMES = {
  "MQ2",
  "MQ3",
  "MQ4",
  "MQ5",
  "MQ6",
  "MQ7",
  "MQ8",
  "MQ9",
  "MQ131",
  "MQ135",
  "MQ136",
  "MQ137",
  "MQ138",
  "VOC",
  "O2",
  "CO2",
  "PM2.5",
  "PM10",
  "Luftfeuchtigkeit",
  "Temperatur",
};

// Werte der Sensoren, Temperatur auslassen (-1)
float[] werte = new float[NAMES.length-1];
// die höchsten Werte der Sensoren, die jemals gemessen wurden
float[] maxValues = new float[werte.length];

// bereits gesammelte Beispiele, ist eine Liste von "werte" Arrays
ArrayList<float[]> examples;
// die dazu gehörenden Labels
ArrayList<String> labels;
// alle Gerüche, die bereits gemessen wurden
ArrayList<String> classNames;
// Anzahl der bereits empfangenen Werte-Sets
int messDurchgang = 0;
// seit wann die (jetzige) Messung läuft
int savedDurchgaenge;

final PVector BUTTON_SIZE = new PVector(100, 70);
color startColor = color(0, 255, 0);
Button startButton;
color lineChartColor = color(255, 0, 0);
Button lineChartButton;
color barChartColor = color(255, 0, 0);
Button barChartButton;

final color TEXT_COLOR = color(100);
color[] chartColors;

boolean started = false;
boolean killThreads = false;

Proxy proxy;
LabelList labelList;
Model model;

final int CORES = Runtime.getRuntime().availableProcessors();

final boolean DEBUG = true;

void setup() {

  size(750, 400);
  frameRate(30);

  surface.setResizable(true);
  surface.setLocation(displayWidth/2-width/2-Window.OFFSET_X, displayHeight/2-height/2-Window.OFFSET_Y);
  if (!DEBUG) {
    // erst starten, wenn der Arduino Daten sendet
    surface.setVisible(false);
  }
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  textSize(22);

  chartColors = new color[werte.length];
  // wird noch verbessert/überarbeitet
  for (int i = 0; i < chartColors.length; i++) {
    int r = int(random(255));
    int g = int(random(255));
    int b = int(random(255));
    int a = 200;
    chartColors[i] = color(r, g, b, a);
  }

  // Laden der bereits gespeicherten Beispiele //

  CLASS_NAMES_FILE = getPath("GeruchsMessungen_classNames.txt");
  EXAMPLES_FILE =  getPath("GeruchsMessungen_examples.bin");
  LABELS_FILE =  getPath("labels.txt");
  WEIGHTS_FILE = getPath("GeruchsMessungen_weights.bin");

  weightsEncoder = new Encoder(WEIGHTS_FILE);

  model = new Model(new GeruchsMessungen());
  model.eval();

  BACKUP_FILES = new String[]{
    CLASS_NAMES_FILE,
    EXAMPLES_FILE,
    LABELS_FILE,
  };

  examplesEncoder = new Encoder(EXAMPLES_FILE);

  examples = new ArrayList<float[]>();
  labels = new ArrayList<String>();
  classNames = new ArrayList<String>();

  try {
    examples = F.toFloatList(examplesEncoder.load());
  }
  catch(Exception e) {
    e.printStackTrace();
    println("missing file " + EXAMPLES_FILE);
  }

  labels = F.toStringList(loadStrings(LABELS_FILE));

  if (labels.size() == 0) {
    println("missing file " + LABELS_FILE);
  }

  classNames = F.toStringList(loadStrings(CLASS_NAMES_FILE));

  if (classNames.size() == 0) {
    println("missing file " + CLASS_NAMES_FILE);
  }

  // update max values
  for (int i = 0; i < examples.size(); i++) {
    for (int j = 0; j < examples.get(i).length; j++) {
      if (examples.get(i)[j] > maxValues[j]) {
        maxValues[j] = examples.get(i)[j];
      }
    }
  }

  if (DEBUG) {
    // damit etwas gezeigt wird
    for (int i = 0; i < werte.length; i++) {
      werte[i] = examples.get(examples.size()-1)[i];
    }
  } else {
    savedDurchgaenge = examples.size();
  }

  // braucht height Variable, die erst mit size() festgelegt wurde
  labelList = new LabelList();

  startButton = new Button(
    width/1.3, height/5,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {
    if (labelList.getLabel() == null) {
      return;
    }
    if (started) {
      startColor = color(0, 255, 0);
      stop();
    } else if (messDurchgang > proxy.KALI_DURCHGAENGE) {
      startColor = color(255, 0, 0);
      savedDurchgaenge = examples.size();
      proxy.ignoredFirst = false;
      started = true;
    }
  }
  ,
    (self) -> {
    fill(startColor);
    stroke(0);
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    fill(0);
    text(started ? "STOP" : "Start", self.pos.x, self.pos.y);
    fill(TEXT_COLOR);
    text(started ? "" : "Select a label", self.pos.x, self.pos.y+self.size.y/1.6);
  }
  );

  lineChartButton = new Button(
    width/1.3, height/2,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {

    if (lineChart.freezed) {
      lineChart.deFreeze();
      lineChartColor = color(255, 0, 0);
    } else {
      lineChart.freeze();
      lineChartColor = color(0, 255, 0);
    }
  }
  ,
    (self) -> {
    fill(lineChartColor);
    stroke(0);
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    fill(0);
    text(lineChart.freezed ? "show" : "hide", self.pos.x, self.pos.y);
    fill(TEXT_COLOR);
    text((lineChart.freezed ? "show" : "hide") + " line-chart", self.pos.x, self.pos.y+self.size.y/1.6);
  }
  );

  barChartButton = new Button(
    width/1.3, height/1.2,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {

    if (barChart.freezed) {
      barChart.deFreeze();
      barChartColor = color(255, 0, 0);
    } else {
      barChart.freeze();
      barChartColor = color(0, 255, 0);
    }
  }
  ,
    (self) -> {
    fill(barChartColor);
    stroke(0);
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    fill(0);
    text(barChart.freezed ? "show" : "hide", self.pos.x, self.pos.y);
    fill(TEXT_COLOR);
    text((barChart.freezed ? "show" : "hide") + " bar-chart", self.pos.x, self.pos.y + self.size.y/1.6);
  }
  );

  proxy = new Proxy();

  for (Window w : APPLETS) {
    w.deFreeze();
  }

  new Thread(()-> {
    while (!killThreads) {
      proxy.update();
    }
  }
  ).start();

  //examplesEncoder.save(examplesArray);
  //Encoder binary_encoder = new Encoder("GeruchsMessungen_labels.bin");
  //binary_encoder.save(getLabelsOneHot());
}

// one-hot encoding für die KI
float[][] getLabelsOneHot() {

  float[][] oneHot = new float[labels.size()][classNames.size()];

  for (int i = 0; i < labels.size(); i++) {
    int label = classNames.indexOf(labels.get(i));
    oneHot[i][label] = 1;
  }
  return oneHot;
}

void draw() {

  background(255);

  startButton.show();
  barChartButton.show();
  lineChartButton.show();

  labelList.show();

  if (DEBUG) {
    textSize(15);
    fill(60);
    text("Debug Mode", width/2, height-20);
  }
}


// wird von dem STOPP Button aufgerufen
void stop() {

  started = false;

  if (DEBUG) {
    return;
  }

  // backup //
  String time =   "_" + year() + "_" + month() +  "_" + hour() +  "_"  + minute() +  "_"  + second();

  for (int i = 0; i < BACKUP_FILES.length; i++) {

    Path source = Paths.get(BACKUP_FILES[i]);
    Path target = Paths.get(BACKUP_FILES[i] + time);
    try {
      Files.copy(source, target);
    }
    catch (IOException e) {
      e.printStackTrace();
      println("Einige Backups konnten nicht erstellt werden!!!");
    }
  }

  lineChart.save(getPath(labelList.getLabel() + "_lines.jpg"));
  barChart.save(getPath(labelList.getLabel() + "_bars.jpg"));

  examplesEncoder.save(F.toFloatArray(examples));
  saveStrings(LABELS_FILE, F.toStringArray(labels));
  saveStrings(CLASS_NAMES_FILE, F.toStringArray(classNames));
}

// alle Rechtecke per default mit abgerundeten Ecken, einfach da es moderner aussieht
final int CORNER_RADIUS = 8;

@Override
  void rect(float x, float y, float sx, float sy) {
  rect(x, y, sx, sy, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS);
}

@Override
  void exit() {
  killThreads = true;
}


// wird von Serial aufgerufen, wenn: buffer = data + -> \n <-
void serialEvent(Serial myPort) {
  proxy.serialEvent(myPort);
}

// kann wgen sketchPath() erst ab setup() aufgerufen werden
String getPath (String name) {
  return sketchPath("data" + SLASH + name);
}

void exitError(Exception e, String message) {

  e.printStackTrace();
  println(message);
  noLoop();
}

void exitError(Exception e, String message, boolean exit) {

  exitError(e, message);
  if (exit)
    System.exit(0);
}

float skaliere(float oldVal, float oldMax, float newMax) {
  return newMax * (oldVal / oldMax);
}

//// höchte Wert, den der jeweilige Sensor ausgeben kann
//final int[] maxValues = {
//  1024, // analoger output hat 10 Bits, also 2^10
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  1024,
//  500, // info taken from example sketch of library
//  30, // https://wiki.dfrobot.com/Gravity_I2C_Oxygen_Sensor_SKU_SEN0322
//  5000, // 400-5000 https://www.amazon.de/dp/B09B27MWNG?tag=shopping-de-amazon-suggestedresults-1-21&linkCode=osi&th=1&psc=1
//  1000, // https://microcontrollerslab.com/nova-pm-sds011-dust-sensor-pinout-working-interfacing-datasheet/
//  1000, // https://microcontrollerslab.com/nova-pm-sds011-dust-sensor-pinout-working-interfacing-datasheet/
//  50, // 0-50, https://www.wellpcb.com/dht11-datasheet.html
//  80 // 20-80, https://www.wellpcb.com/dht11-datasheet.html
//};
