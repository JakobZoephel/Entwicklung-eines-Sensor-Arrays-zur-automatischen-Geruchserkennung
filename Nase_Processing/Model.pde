/*
 * Das ist ein extrem kleiner Teil aus meinem Jugend Forscht Projekt aus dem letzten Jahr.
 * Ich habe von den ca. 6000 Codezeilen nur die "gepastet", die für das forwarden gebraucht werden.
 * Das Training wurde mit der "richtigen" codebase gemacht. Diese ist aber temporär nicht auf GitHub,
 * da sie sich seit Monaten in einem großen Refactoring befindet (was für neue Projekte benötigt wird).
 */

import java.util.concurrent.atomic.AtomicInteger;
import static java.lang.Float.floatToIntBits;
import static java.lang.Float.intBitsToFloat;


@FunctionalInterface
  public interface Function {
  float f(float ... x);
}


public class AtomicFloat extends Number {

  AtomicInteger bits;

  public AtomicFloat() {
    this(0f);
  }

  public AtomicFloat(float initialValue) {
    bits = new AtomicInteger(floatToIntBits(initialValue));
  }

  public final void add(float value) {
    set(get()+value);
  }

  public final void set(float newValue) {
    bits.set(floatToIntBits(newValue));
  }

  public final float get() {
    return intBitsToFloat(bits.get());
  }

  @Override
    public float floatValue() {
    return get();
  }

  @Override
    public double doubleValue() {
    return (double) floatValue();
  }

  @Override
    public int intValue() {
    return (int) get();
  }

  @Override
    public long longValue() {
    return (long) get();
  }
}

//abstract class Layer {

//  Perceptron[] perceptrons;
//  Function[] function;
//   void createWeights(int numberOfWeigths) {
//    for (int i=0; i < perceptrons.length; i++) {
//      perceptrons[i].createWeights(numberOfWeigths);
//    }
//  }

//  void createWeights() {
//    for (int i=0; i < perceptrons.length; i++) {
//      perceptrons[i].createWeights();
//    }
//  }

//  abstract void connect();
// }

//class LinearLayer extends Layer {
//}


class Perceptron {

  float[] weights;
  float bias;

  AtomicFloat[] batchDelta;
  AtomicFloat batchBias = new AtomicFloat();

  Function[] function;

  Perceptron(Function[] function_) {
    this.function = function_;
  }

  void createWeights(int numberOfWeigths) {
    weights = new float[numberOfWeigths];
    batchDelta = new AtomicFloat[numberOfWeigths];
    for (int i = 0; i < batchDelta.length; i++)
      batchDelta[i] = new AtomicFloat();
  }

  void createWeights() {
    weights = new float[model.hiddenLayers[model.hiddenLayers.length-1].perceptrons.length];
    batchDelta = new AtomicFloat[weights.length];
    for (int i = 0; i < batchDelta.length; i++)
      batchDelta[i] = new AtomicFloat();
  }

  float feedForward(float[] input) {

    float sum = 0;
    for (int i = 0; i < weights.length; i++) {
      sum += input[i] * weights[i];
    }
    return sum + bias;
  }
}

class LinearLayer {

  Perceptron[] perceptrons;
  Function[] function;

  LinearLayer(int numberOfperceptrons, Function[] func) {

    function = func;
    perceptrons = new Perceptron[numberOfperceptrons];
    for (int i=0; i < numberOfperceptrons; i++) {
      perceptrons[i] = new Perceptron(func);
    }
  }

  void createWeights(int numberOfWeigths) {
    for (int i=0; i < perceptrons.length; i++) {
      perceptrons[i].createWeights(numberOfWeigths);
    }
  }

  void createWeights() {
    for (int i=0; i < perceptrons.length; i++) {
      perceptrons[i].createWeights();
    }
  }

  float[] forward(float[] input) {

    float[] outputs = new float[perceptrons.length];

    for (int i = 0; i < perceptrons.length; i++) {
      outputs[i] = function[0].f(perceptrons[i].feedForward(input));
    }

    if (function.equals(F.softmax)) {
      //softmax ist speziell und braucht daher eine spezielle Behandlung
      F.softmax(outputs);
    }
    return outputs;
  }
}

class Model {

  Dataset ds;

  // damit hiddenLayers nicht null ist
  LinearLayer[] hiddenLayers = new LinearLayer[0];

  LinearLayer outL;

  //mit dieser Funktion wird der Fehler berechnet
  //final Function loss = F.MSE;
  Function loss;

  //nach wie vielen Minuten das Training unterbrochen werden soll
  public int timeOut = 60;

  //nach dem die Trainingsbeipsiele durch sind, wird epochs mal von vorne angefangen.
  //(ein Durchlauf aller Trainigsbeispiele == eine Epoche)
  public int epochs = 100;

  // die Anzahl der zu erstellenden Beispiele
  public int examples = 1000;
  // wie viel Prozent der Beispiele zum Training verwendet werden sollen
  public float split = 0.7;

  //Anzahl der zu benutzenden Threads
  public int threadCount = 2;

  //bestimmt ob die threads anderen gegenüber Vorrang haben.
  //1 == niedrigste, 10 == höchste. Standard ist 5
  public int threadPriority = 10;

  //Größe eines Trainingsstapels
  public int batchSize = 4;

  //lernrate
  public float lr = 0.01;

  //um den Faktor wird das Momentum multipliziert
  public float momentum = 0.8;

  //maximum des Betrages welchen ein Gewicht am Anfang annehmen kann
  //(die Gewichte werden am Anfang zufällig gewählt)
  public float weigthsValue = 0.02;

  public boolean
    show = false,

    load = false,
    save = false,

    loadExamples = false;

  // danach model.build(...)
  Model(Dataset ds) {
    this.ds = ds;
  }


  Model(Function loss, Dataset ds, LinearLayer ... layers) {
    build(loss, ds, layers);
  }

  void build(String[] model_params) {

    Dataset para_ds = null;
    LinearLayer[] para_layers = new LinearLayer[model_params.length-2];
    String[] split;
    Function[] function;

    for (int i = 1; i < model_params.length-2; i++) {

      split = split(model_params[i], ":");
      try {
        function = (Function[]) F.getClass().getField(split[1]).get(F);
        para_layers[i-1] = new LinearLayer(int(split[0]), function);
      }
      catch(Exception e) {
        e.printStackTrace();
      }
    }

    Function para_loss = null;

    try {
      Class dsClass = Class.forName(MAIN.getClass().getSimpleName() + "$" + model_params[0]);
      //println(dsClass.getSimpleName(), dsClass.getConstructors()[0]);
      para_ds = (Dataset) dsClass.getConstructors()[0].newInstance(MAIN);

      split = split(model_params[model_params.length-2], " ");
      para_layers[para_layers.length-1] = new LinearLayer(int(split[0]), (Function[]) F.getClass().getField(split[1]).get(F));
      para_loss = (Function) F.getClass().getField(model_params[model_params.length-1]).get(F);
    }
    catch(Exception e) {
      e.printStackTrace();
      println(para_loss, para_ds, para_layers.length);
      System.exit(0);
    }
    build(para_loss, para_ds, para_layers);
  }

  void build(Function loss, Dataset ds, LinearLayer ... layers) {

    this.ds = ds;
    this.loss = loss;

    hiddenLayers = new LinearLayer[layers.length-1];
    for (int i = 0; i < hiddenLayers.length; i++) {
      this.hiddenLayers[i] = layers[i];
    }
    this.outL = layers[layers.length-1];
    connect();
  }

  void printArchitecture() {

    println("---Inputs---");
    printArray(ds.features);

    println("---Hidden Layers---");
    println("Perceptrons Function");
    for (int i = 0; i < hiddenLayers.length; i++) {
      println(hiddenLayers[i].perceptrons.length, F.getFunctionName(hiddenLayers[i].function));
    }

    println("---Output Layer---");
    println("Perceptrons Function");
    println(outL.perceptrons.length, F.getFunctionName(outL.function));
  }

  void connect() {

    for (int i = hiddenLayers.length-1; i >= 0; i--) {
      if (i == 0) {
        hiddenLayers[i].createWeights(ds.features);
      } else {
        hiddenLayers[i].createWeights(hiddenLayers[i-1].perceptrons.length);
      }
    }
    outL.createWeights();
  }


  float[] result;
  float[][] outputsH;

  public void eval() {

    if (lr > 0) {
      // negative lr -> siehe Ableitung der Backpropagation
      lr = -lr;
    }

    load();

    result = new float[outL.perceptrons.length];
    outputsH = new float[hiddenLayers.length][];
    for (int i = 0; i < outputsH.length; i++) {
      outputsH[i] = new float[hiddenLayers[i].perceptrons.length];
    }
  }

  float[] feedForward(float[] input) {

    for (int i = 0; i < hiddenLayers.length; i++) {
      input = hiddenLayers[i].forward(input);
    }
    result = outL.forward(input);
    return result;
  }

  void load() {

    build(loadStrings(getPath(MODEL_NAME + "_model.txt")));
    // printArchitecture();

    float[] weights = weightsEncoder.load()[0];

    int iterator = 0;
    for (int i = 0; i < hiddenLayers.length; i++) {
      for (int j = 0; j < hiddenLayers[i].perceptrons.length; j++) {
        for (int k = 0; k < hiddenLayers[i].perceptrons[j].weights.length; k++) {
          hiddenLayers[i].perceptrons[j].weights[k] = weights[iterator];
          iterator++;
        }
        hiddenLayers[i].perceptrons[j].bias = weights[iterator];
        iterator++;
      }
    }

    for (int i = 0; i < outL.perceptrons.length; i++) {
      for (int j = 0; j < outL.perceptrons[i].weights.length; j++) {
        outL.perceptrons[i].weights[j] = weights[iterator];
        iterator++;
      }
      outL.perceptrons[i].bias = weights[iterator];
      iterator++;
    }
  }
}
