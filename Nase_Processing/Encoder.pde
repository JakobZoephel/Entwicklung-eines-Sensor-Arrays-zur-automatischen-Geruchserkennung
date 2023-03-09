class Encoder {

  /*
   * Ein Algorithmus, der einen 2D-Array speichert.
   * Für genauere Datenwerte müssten die floats mit doubles und die ints mit longs ersetzt werden.
   */

  Encoder(String file) {
    fileName = file;
  }

  // alle Paramter, die zum Speichern + Laden gebraucht werden

  String fileName = "";
  byte[] bytes;

  int ARRAY_LENGTH = 0;
  int EXAMPLE_SIZE = 0;

  int GLOBAL_SIGNED = 0;
  int GLOBAL_MAX_DEC = 0;
  int GLOBAL_MAX_ZEROS = 0;
  int GLOBAL_MAX_VALUE = 0;

  int HEADER_VARIABLES = -1;
  int DECIMAL_SIZE = 0;
  int ZEROS_SIZE = 0;
  int VALUE_SIZE = 0;

  int VALUES = 0;
  int BLOCK_SIZE = 0;
  int DATA_BITS = 0;
  int OFFSET = 0;

  void printDebug() {
    // muss ich mich nicht immer durch den Debugger klicken
    println(ARRAY_LENGTH, EXAMPLE_SIZE);
    println(GLOBAL_SIGNED, GLOBAL_MAX_DEC, GLOBAL_MAX_ZEROS, GLOBAL_MAX_VALUE);
    println(HEADER_VARIABLES, DECIMAL_SIZE, ZEROS_SIZE, VALUE_SIZE);
    println(VALUES, BLOCK_SIZE, DATA_BITS, OFFSET);
    println();
  }

  String intValue = "";

  void save(float[][] array) {

    /*
     Dies ist eine Funktion, die einen Array aus floats binär speichert.
     Bei der Speicherung wird keine Komprimierung angewandt. Das wäre eine Idee
     für die Zukunft, indem man beispielsweise die Huffman-Kodierung implementiert.
     */

    /*
     Bei der Speicherung von floats wird der floating point entfernt.
     Dadurch wird aus z.B. 0.8 08, was dann als 8 interpretiert wird.
     Bei dem Laden würde dann aus der 8 eine 8.0 werden, was falsch ist.
     Daher num_zeros, wie viele Nullen am Anfang angehangen werden müssen.
     */

    // Ermittlung der benötigten Werte und jeweiliger Größe in Bits //

    ARRAY_LENGTH = array.length;
    EXAMPLE_SIZE = array[0].length;

    for (int i = 0; i < ARRAY_LENGTH; i++) {
      for (int j = 0; j < EXAMPLE_SIZE; j++) {
        float value = array[i][j];

        if (GLOBAL_SIGNED == 0 && value < 0) {
          GLOBAL_SIGNED = 1;
        }
        value = abs(value);

        int decimalIndex = getDeciamlIndex(value);
        if (decimalIndex > GLOBAL_MAX_DEC) {
          GLOBAL_MAX_DEC = decimalIndex;
        }
        String strValue = eraseDecimalPoint(value);

        int numZeros = getZerosNum(strValue);
        if (numZeros > GLOBAL_MAX_ZEROS) {
          GLOBAL_MAX_ZEROS = numZeros;
        }
        value = int(strValue);

        if (value > GLOBAL_MAX_VALUE) {
          GLOBAL_MAX_VALUE = int(value);
        }
      }
    }

    DECIMAL_SIZE = GLOBAL_MAX_DEC == 0 ? 0 : value2Base(GLOBAL_MAX_DEC, 2, -1).length();
    ZEROS_SIZE = GLOBAL_MAX_ZEROS == 0 ? 0 : value2Base(GLOBAL_MAX_ZEROS, 2, -1).length();
    VALUE_SIZE = value2Base(GLOBAL_MAX_VALUE, 2, -1).length();
    VALUES = ARRAY_LENGTH*EXAMPLE_SIZE;

    // Umwandlung der Werte von Bytes zu Bits //

    BLOCK_SIZE = GLOBAL_SIGNED + DECIMAL_SIZE + ZEROS_SIZE + VALUE_SIZE;
    DATA_BITS = VALUES*BLOCK_SIZE;
    OFFSET = 8-DATA_BITS%8;
    //  offset: 8-DATA_BITS%8, falls die Anzahl an Bits kein Vielfaches von 8 ist
    byte[] bits = new byte[DATA_BITS + OFFSET];

    float value;
    // eine Einheit aus singed+decimalIndex+zeros+value
    String block;

    for (int i = 0; i < ARRAY_LENGTH; i++) {
      for (int j = 0; j < EXAMPLE_SIZE; j++) {

        value = array[i][j];
        block = "";

        if (GLOBAL_SIGNED == 1) {
          block += abs(value) == value ? 0 : 1;
          value = abs(value);
        }

        String strValue = removeScientificNotation(value);
        if (GLOBAL_MAX_DEC > 0) {
          block += value2Base(getDeciamlIndex(value), 2, DECIMAL_SIZE);
          strValue = eraseDecimalPoint(value);
        }

        if (GLOBAL_MAX_ZEROS > 0) {
          block += value2Base(getZerosNum(strValue), 2, ZEROS_SIZE);
        }
        value = int(strValue);

        block += value2Base(int(value), 2, VALUE_SIZE);

        for (int c = 0; c < BLOCK_SIZE; c++) {
          bits[i*EXAMPLE_SIZE*BLOCK_SIZE + j*BLOCK_SIZE + c] = byte(int(str((block.charAt(c)))));
        }
      }
    }

    // meta-header
    ArrayList<Integer> header = new ArrayList<Integer>();

    // wird später gesetzt
    header.add(0);
    header.add(GLOBAL_SIGNED);
    header.add(DECIMAL_SIZE);
    header.add(ZEROS_SIZE);
    header.add(VALUE_SIZE);

    // damit die Länge des Arrays nicht auf max. 255 beschränkt ist
    intValue = value2Base(ARRAY_LENGTH, 2, 4*8);
    for (int i = 0; i < intValue.length(); i += 8) {
      header.add(toDezimal(intValue, i, i+8, 2));
    }

    intValue = value2Base(EXAMPLE_SIZE, 2, 4*8);
    for (int i = 0; i < intValue.length(); i += 8) {
      header.add(toDezimal(intValue, i, i+8, 2));
    }

    HEADER_VARIABLES = header.size();
    header.set(0, HEADER_VARIABLES);

    // -128, damit die Werte alle unsigned sind. Dadurch ergibt sich ein größerer möglicher Wertebereich
    for (int i = 0; i < header.size(); i++) {
      header.set(i, header.get(i)-128);
    }

    // die generierten Bits als Bytes speichern
    bytes = new byte[HEADER_VARIABLES + int(bits.length/8)];

    for (int i = 0; i < header.size(); i++) {
      bytes[i] = byte(header.get(i));
    }

    for (int i = 0; i < bits.length; i += 8) {
      bytes[header.size()+i/8] = byte(toDezimal(bits, i, i+8, 2));
    }
    saveBytes(fileName, bytes);
  }

  byte[] loadMetaData() {

    if (bytes == null) {
      bytes = loadBytes(fileName);
    }

    HEADER_VARIABLES = bytes[0]+128;
    GLOBAL_SIGNED = bytes[1]+128;
    DECIMAL_SIZE = bytes[2]+128;
    ZEROS_SIZE = bytes[3]+128;
    VALUE_SIZE = bytes[4]+128;

    intValue = "";
    for (int i = 0; i < 4; i++) {
      intValue += value2Base(bytes[(HEADER_VARIABLES-8)+i]+128, 2, 8);
    }
    ARRAY_LENGTH = toDezimal(intValue, 0, intValue.length(), 2);

    intValue = "";
    for (int i = 0; i < 4; i++) {
      intValue += value2Base(bytes[(HEADER_VARIABLES-4)+i]+128, 2, 8);
    }
    EXAMPLE_SIZE = toDezimal(intValue, 0, intValue.length(), 2);

    BLOCK_SIZE = GLOBAL_SIGNED + DECIMAL_SIZE + ZEROS_SIZE + VALUE_SIZE;

    VALUES = ARRAY_LENGTH*EXAMPLE_SIZE;
    DATA_BITS = VALUES*BLOCK_SIZE;
    OFFSET = 8-DATA_BITS%8;

    byte[] bits = new byte[DATA_BITS + OFFSET];

    String currByte;
    for (int i = HEADER_VARIABLES; i < bytes.length; i++) {
      currByte = binary(bytes[i], 8);
      for (int j = 0; j < 8; j++) {
        bits[(i-HEADER_VARIABLES)*8+j] = byte(int(str(currByte.charAt(j))));
      }
    }
    return bits;
  }

  float[][] loadThreads(final int THREADS) {
    return loadThreads(THREADS, 0);
  }

  float[][] loadThreads(int customSize, final int THREADS) {

    byte[] bits = loadMetaData();
    float[][] array = new float[customSize <= 0 ? ARRAY_LENGTH : customSize][VALUES/ARRAY_LENGTH];

    Worker[] workers = new Worker[THREADS];
    final int LEN = ARRAY_LENGTH/workers.length;

    int begin, end;
    for (int thread = 0; thread < workers.length; thread++) {

      begin = thread*LEN;
      end = begin+LEN;
      if (thread == workers.length-1) {
        end += ARRAY_LENGTH%workers.length;
      }

      workers[thread] = new Worker(begin * (VALUES/ARRAY_LENGTH) * BLOCK_SIZE, end * (VALUES/ARRAY_LENGTH) * BLOCK_SIZE, BLOCK_SIZE,
        (i) -> {
        if ((i/BLOCK_SIZE)/(VALUES/ARRAY_LENGTH) >= array.length) {
          return;
        }
        array[(i/BLOCK_SIZE)/(VALUES/ARRAY_LENGTH)][(i/BLOCK_SIZE)%(VALUES/ARRAY_LENGTH)] = makeValue(i, bits);
      }
      );
      workers[thread].start();
    }

    try {
      for (Worker thread : workers) {
        thread.join();
      }
    }
    catch(InterruptedException e) {
      for (Worker thread : workers) {
        thread.interrupt();
      }
      e.printStackTrace();
    }

    return array;
  }

  float[][] load() {
    return load(0);
  }

  float[][] load(int customSize) {

    byte[] bits = loadMetaData();
    float[][] array = new float[customSize <= 0 ? ARRAY_LENGTH : customSize][VALUES/ARRAY_LENGTH];

    for (int i = 0; i < bits.length-OFFSET; i += BLOCK_SIZE) {
      // wenn bereits customSize Beispiele geladen wurden
      if ((i/BLOCK_SIZE)/(VALUES/ARRAY_LENGTH) >= array.length) {
        break;
      }
      array[(i/BLOCK_SIZE)/(VALUES/ARRAY_LENGTH)][(i/BLOCK_SIZE)%(VALUES/ARRAY_LENGTH)] = makeValue(i, bits);
    }
    return array;
  }


  float[] loadElement(int index) {

    byte[] bits = loadMetaData();
    float[] array = new float[VALUES/ARRAY_LENGTH];

    for (int i = index*(VALUES/ARRAY_LENGTH)*BLOCK_SIZE; i < (index+1)*(VALUES/ARRAY_LENGTH)*BLOCK_SIZE; i += BLOCK_SIZE) {
      array[(i/BLOCK_SIZE)%(VALUES/ARRAY_LENGTH)] = makeValue(i, bits);
    }
    return array;
  }

  float makeValue(int i, byte[] bits) {

    String block = "";
    for (int j = 0; j < BLOCK_SIZE; j++) {
      block += str(bits[i+j]);
    }

    byte signed = 0;
    int deciamlIndex = 0;
    int zeros = 0;
    float value;

    if (GLOBAL_SIGNED == 1) {
      signed = byte(int(str(block.charAt(0))));
    }

    String buffBlock = "";
    if (DECIMAL_SIZE > 0) {
      for (int j = 0; j < DECIMAL_SIZE; j++) {
        buffBlock += block.charAt(GLOBAL_SIGNED+j);
      }
      deciamlIndex = toDezimal(buffBlock);
    }

    if (ZEROS_SIZE > 0) {
      buffBlock = "";
      for (int j = 0; j < ZEROS_SIZE; j++) {
        buffBlock += block.charAt(GLOBAL_SIGNED+DECIMAL_SIZE+j);
      }
      zeros = toDezimal(buffBlock);
    }

    String valueBlock = "";
    for (int j = 0; j < VALUE_SIZE; j++) {
      valueBlock += block.charAt(GLOBAL_SIGNED+DECIMAL_SIZE+ZEROS_SIZE+j);
    }

    String strValue = removeScientificNotation(toDezimal(valueBlock));
    strValue = addZeros(strValue, zeros);
    value = addDecimalPoint(strValue, deciamlIndex);
    value *= signed == 1 ? -1 : 1;
    return value;
  }


  String removeScientificNotation(float f) {

    String s;
    if (int(f) == f) {
      s = str(int(f));
    } else {
      s = str(f);
    }

    String[] split = split(s, "E-");
    if (split.length == 1) {
      return s;
    }
    return "0." + addZeros(split[0].replace(".", ""), int(split[1])-1);
  }

  String eraseDecimalPoint(float f) {

    String s = removeScientificNotation(f);
    if (int(f) == f)
      return s;
    return s.replace(".", "");
  }

  float addDecimalPoint(String s, int index) {

    if (index == 0)
      return float(s);

    s = s.substring(0, index) + "." + s.substring(index, s.length());
    return float(s);
  }

  int getDeciamlIndex(float num) {

    String text = removeScientificNotation(num);
    if (split(text, ".").length == 1)
      return 0;

    int number = 0;
    if (match(text, "E") != null) {
      number = text.replace(".", "").split("E")[0].length();
    } else
      number = split(text, ".")[0].length();

    return number;
  }

  String addZeros(String s, int num) {
    for (int i = 0; i < num; i++) {
      s = "0" + s;
    }
    return s;
  }

  int getZerosNum(String text) {

    int num = 0;
    for (int i = 0; i < text.length(); i++) {
      if (text.charAt(i) == '0') {
        num++;
      } else {
        break;
      }
    }
    return num;
  }

  String value2Base(int value, final int BASE, final int MAX_CHARS) {

    // nur bis base 36 (Hexatrigesimal)
    if (BASE > 36)
      return "";


    String buffer = "";
    boolean done = true;

    if (MAX_CHARS == -1) {

      while (true) {
        if (value >= BASE) {
          buffer = getNumeralSystemChar(value % BASE) + buffer;
          value /= BASE;
        } else if (done) {
          buffer = getNumeralSystemChar(value) + buffer;
          done = false;
        } else
          break;
      }
    } else {
      for (int i = 0; i < MAX_CHARS; i++) {
        if (value >= BASE) {
          buffer = getNumeralSystemChar(value % BASE) + buffer;
          value /= BASE;
        } else if (done) {
          buffer = getNumeralSystemChar(value) + buffer;
          done = false;
        } else
          buffer = "0" + buffer;
      }
    }
    return(buffer);
  }

  char getNumeralSystemChar(int index) {

    if (index < 0 ||  index >= 36)
      return char(-1);

    if (index < 10)
      return char(48+index);
    else
      return char(55+index);
  }

  int toDezimal(String number) {
    return toDezimal(number, 2);
  }

  int toDezimal(String number, final int BASE) {
    return Integer.parseInt(number, BASE);
  }

  int toDezimal(byte[] arr, int begin, int end, final int BASE) {

    int val = 0;
    int len = end-begin;

    for (int i = len-1; i >= 0; i--) {
      val += int(removeScientificNotation(arr[begin+i])) * pow(BASE, len-i-1);
    }
    return val;
  }

  int toDezimal(String str, int begin, int end, final int BASE) {

    int val = 0;
    int len = end-begin;

    for (int i = len-1; i >= 0; i--) {
      val += int(str(str.charAt(begin+i))) * pow(BASE, len-i-1);
    }
    return val;
  }

  void testWorking(float[][] testArray) {
    String prevFilename = fileName;
    fileName = "DELETEME";
    save(testArray);
    float[][] loaded = load();

    for (int i = 0; i < testArray.length; i++) {
      for (int j = 0; j < testArray[i].length; j++) {
        if (testArray[i][j] != loaded[i][j]) {
          println(testArray[i][j], "!=", loaded[i][j]);
        }
      }
    }
    fileName = prevFilename;
  }

  void legacy_save(float[][] array, String fileName) {

    PrintWriter w = createWriter((fileName));
    w.println(array.length);
    w.println(array[0].length);

    for (int i = 0; i < array.length; i++) {
      for (int j = 0; j < array[i].length; j++) {
        w.println(array[i][j]);
      }
    }
    w.flush();
    w.close();
  }

  float[][] legacy_load(String fileName) {

    String[] data = loadStrings((fileName));
    float[][] array = new float[int(data[0])][int(data[1])];

    int index = 2;
    for (int i = 0; i < array.length; i++) {
      for (int j = 0; j < array[i].length; j++) {

        array[i][j] = float(data[index]);
        index++;
      }
    }
    return array;
  }
}
