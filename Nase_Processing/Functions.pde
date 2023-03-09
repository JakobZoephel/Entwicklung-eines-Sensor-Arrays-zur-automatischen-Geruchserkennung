import java.lang.reflect.Field;

class Functions {

  public Function[] relu = {
    // f(x)
    x -> x[0] < 0 ?  0 : x[0],
    // f'(x)
    x -> x[0] < 0 ? 0 : 1
  };

  public Function[] sigmoid = {
    x -> 1/(1+exp(-x[0])),
    x -> 1/(1+exp(-x[0])) * (1-1/(1+exp(-x[0]))),
  };

  public Function[] tanh = {
    x -> (exp(x[0])-exp(-x[0])) / (exp(x[0])+exp(-x[0])),
    x -> 1 - pow((exp(x[0])-exp(-x[0])) / (exp(x[0])+exp(-x[0]))-1, 2)
  };
  
  public Function[] softmax = {
    // das Ergebnis der Funtion wird erst später berechnet
    x -> x[0],
    x -> x[0]
  };

  // stable_softmax
  public float[] softmax(float[] outputs) {

    float shift = max(outputs);
    for (int i = 0; i < outputs.length; i++)
      outputs[i] -= shift;


    float sum = 0;
    //outptus sind in diesem Fall immer noch das Gleiche wie der netzinput
    for (int i=0; i < outputs.length; i++)
      sum += exp(outputs[i]);

    for (int i=0; i < outputs.length; i++)
      outputs[i] = exp(outputs[i])/sum;

    return outputs;
  }

  public float[] softmaxDerivative(float[] netzinput) {

    netzinput = softmax(netzinput);
    for (int i=0; i < netzinput.length; i++)
      // netzinput[i] = netzinput[i] - pow(netzinput[i], 2);
      netzinput[i] = netzinput[i] * (1 - netzinput[i]);

    return netzinput;
  }

  //x[0] = net_output, x[1] = label

  // half MSE
  public Function MSE = x -> x[0] - x[1];

  public Function XEntropy = x -> {
    // 1/0 == ArithmeticException
    x[0] += 1E-20;// 1E-45
    return -x[1]/x[0];
  };

  // public Function BinaryXEntropy = x -> (x[0]-x[1])/(x[0]-x[0]*x[0]);
  // bzw.
  // public Function BinaryXEntropy = x -> -x[1]/x[0]+(1-x[1])/(1-x[0]);
  // bzw.
  public Function BinaryXEntropy = x -> XEntropy.f(x) + XEntropy.f(x[0]-1, 1-x[0]);


  String getFunctionName(Function f) {
    return getFunctionName(split(f.toString(), "/")[1], '/');
  }

  String getFunctionName(Function[] f) {
    return getFunctionName(split(f.toString(), ";")[1], ';');
  }

  String getFunctionName(String fPointer, char type) {

    Field[] fields = F.getClass().getDeclaredFields();
    // Adresse des Pointers
    String pointer;

    for (Field field : fields) {
      try {
        pointer = split(field.get(F).toString(), type)[1];
        if (pointer.equals(fPointer)) {
          return field.getName();
        }
      }
      catch(Exception e) {
      }
    }
    return null;
  }

  float[][] toFloatArray(ArrayList<float[]> list) {

    float[][] array = new float[list.size()][list.get(0).length];
    for (int i = 0; i < list.size(); i++) {
      for (int j = 0; j < list.get(i).length; j++) {
        array[i][j] = list.get(i)[j];
      }
    }
    return array;
  }

  String[] toStringArray(ArrayList<String> list) {

    String[] array = new String[list.size()];
    for (int i = 0; i < list.size(); i++) {
      array[i] = list.get(i);
    }
    return array;
  }

  ArrayList<float[]> toFloatList(float[][] array) {

    ArrayList<float[]> list = new ArrayList<float[]>(array.length);

    for (int i = 0; i < array.length; i++) {
      list.add(array[i]);
    }
    return list;
  }

  ArrayList<String> toStringList(String[] array) {

    ArrayList<String> list = new ArrayList<String>(array.length);

    for (int i = 0; i < array.length; i++) {
      list.add(array[i]);
    }
    return list;
  }

  int max_pool_index(float[] array) {
    float a = max(array);
    for (int i = 0; i < array.length; i++) {
      if (array[i] == a) {
        return i;
      }
    }
    return -1;
  }
}
