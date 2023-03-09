// TODO: Multithreading
String K_NN(float[] example, float[][] prevExamples, String[] prevLabels, String[] availibleLabels, int depth) {

  int k = depth*availibleLabels.length+1;

  float[] k_Values = new float[k];
  for (int i = 0; i < k_Values.length; i++) {
    k_Values[i] = -1;
  }
  String[] k_labels = new String[k];

search:
  for (int i = 0; i < prevExamples.length; i++) {
    // Abweichung
    float currDelta = 0;
    for (int j = 0; j < prevExamples[i].length; j++) {
      currDelta += abs(example[j]-prevExamples[i][j]);
    }
    for (int j = 0; j < k_Values.length; j++) {
      if (k_Values[j] == -1) {
        k_Values[j] = currDelta;
        k_labels[j] = prevLabels[i];
        continue search;
      }
    }
    for (int j = 0; j < k_Values.length; j++) {
      if (k_Values[j] > currDelta) {
        k_Values[j] = currDelta;
        k_labels[j] = prevLabels[i];
      }
    }
  }

  int[] result = new int[availibleLabels.length];
  for (int i = 0; i < k_labels.length; i++) {
    for (int j = 0; j < availibleLabels.length; j++) {
      if (k_labels[i].equals(availibleLabels[j])) {
        result[j]++;
        break;
      }
    }
  }

  int maxIndex = -1;
  int maxValue = -1;
  for (int i = 0; i < result.length; i++) {
    if (result[i] > maxValue) {
      maxIndex = i;
      maxValue = result[i];
    }
  }

  if (availibleLabels.length == 0)
    return "No existing labels!";

  return availibleLabels[maxIndex];
}

volatile float[] k_Values;
volatile String[] k_labels;

//  String K_NN(final float[] example, final float[][] prevExamples, final String[] prevLabels, final String[] availibleLabels, final int depth) {

//    final int k = depth*availibleLabels.length+1;

//    k_Values = new float[k];

//    for (int i = 0; i < k_Values.length; i++) {
//      k_Values[i] = -1;
//    }
//    k_labels = new String[k];


//    class Worker extends Thread {

//      int start, end;

//      Worker(int start, int end) {
//        this.start = start;
//        this.end = end;
//      }

//      @Override
//        void run() {

//      search:
//        for (int i = start; i < end; i++) {
//          float currDelta = 0;
//          for (int j = 0; j < prevExamples[i].length; j++) {
//            currDelta += abs(example[j]-prevExamples[i][j]);
//          }
//          for (int j = 0; j < k_Values.length; j++) {
//            if (k_Values[j] == -1) {
//              k_Values[j] = currDelta;
//              k_labels[j] = prevLabels[i];
//              continue search;
//            }
//          }
//          for (int j = 0; j < k_Values.length; j++) {
//            if (k_Values[j] > currDelta) {
//              k_Values[j] = currDelta;
//              k_labels[j] = prevLabels[i];
//            }
//          }
//        }
//      }
//    }


//    Worker[] threads;

//    if (CORES-APPLETS.length > 0) {
//      threads = new Worker[CORES-APPLETS.length];
//    } else {
//      threads = new Worker[1];
//    }

//    for (int i = 0; i < threads.length; i++) {
//      float j = prevExamples.length/threads.length;
//      threads[i] = new Worker(int(i*j), int(i*j+j));
//      threads[i].start();
//    }

//    for (Worker w : threads) {
//      try {
//        w.join();
//      }
//      catch(InterruptedException e) {
//        e.printStackTrace();
//      }
//    }

//  search:
//    for (int i = 0; i < prevExamples.length; i++) {
//      float currDelta = 0;
//      for (int j = 0; j < prevExamples[i].length; j++) {
//        currDelta += abs(example[j]-prevExamples[i][j]);
//      }
//      for (int j = 0; j < k_Values.length; j++) {
//        if (k_Values[j] == -1) {
//          k_Values[j] = currDelta;
//          k_labels[j] = prevLabels[i];
//          continue search;
//        }
//      }
//      for (int j = 0; j < k_Values.length; j++) {
//        if (k_Values[j] > currDelta) {
//          k_Values[j] = currDelta;
//          k_labels[j] = prevLabels[i];
//        }
//      }
//    }

//    int[] result = new int[availibleLabels.length];
//    for (int i = 0; i < k_labels.length; i++) {
//      for (int j = 0; j < availibleLabels.length; j++) {
//        if (k_labels[i].equals(availibleLabels[j])) {
//          result[j]++;
//          break;
//        }
//      }
//    }

//    int maxIndex = -1;
//    int maxValue = -1;
//    for (int i = 0; i < result.length; i++) {
//      if (result[i] > maxValue) {
//        maxIndex = i;
//        maxValue = result[i];
//      }
//    }

//    if (availibleLabels.length == 0)
//      return "No existing labels!";

//    return availibleLabels[maxIndex];
//  }


//  // stable_softmax
//  public float[] softmax(float[] outputs) {

//    float shift = max(outputs);
//    for (int i = 0; i < outputs.length; i++)
//      outputs[i] -= shift;


//    float sum = 0;
//    for (int i=0; i < outputs.length; i++)
//      sum += exp(outputs[i]);

//    for (int i=0; i < outputs.length; i++)
//      outputs[i] = exp(outputs[i])/sum;

//    return outputs;
//  }
