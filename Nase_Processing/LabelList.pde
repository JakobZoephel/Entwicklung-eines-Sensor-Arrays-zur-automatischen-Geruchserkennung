class LabelList extends Events {

  PVector pos = new PVector();
  final PVector SIZE = new PVector(200, 40);
  PVector size = SIZE.copy();
  float maxTextWidth = SIZE.x;
  final int RAND_X = 10;
  final int RAND_Y = 8;

  String variableInput = "";
  boolean onInputBox = false;
  // oberstes Element der Liste
  int labelIndex = 0;
  int selectedLabel = -1;
  final int MAX_SHOWN_LABELS = int((height-SIZE.y)/SIZE.y);
  final int MAX_MOUSE_SPEED = 50;

  LabelList() {

    textSize(25);

    for (String s : classNames) {
      if (textWidth(s) > maxTextWidth) {
        maxTextWidth = textWidth(s);
      }
    }
    size.x = maxTextWidth + 10;
  }

  void show() {

    push();

    fill(200);
    strokeWeight(3);
    textAlign(LEFT, TOP);
    textSize(25);
    rectMode(CORNER);
    pos.set(0, 0);

    // textBox
    if (onInputBox && !started) {
      stroke(120, 120, 255);
    } else {
      stroke(150);
    }
    rect(pos.x, pos.y, size.x, size.y);

    fill(TEXT_COLOR);
    if (size.x > maxTextWidth) {
      text(variableInput, pos.x + RAND_X, pos.y + RAND_Y);
    }

    stroke(255);
    for (int i = 0; i < min(classNames.size(), MAX_SHOWN_LABELS); i++) {
      pos.y = i*size.y + SIZE.y + 3; // +3 wegen strokeWeight

      if (selectedLabel == i+labelIndex) {
        if (started) {
          fill(200, 150, 150);
        } else {
          fill(180, 230, 180);
        }
      } else {
        fill(200);
      }

      rect(pos.x, pos.y, size.x, size.y);

      fill(TEXT_COLOR);
      if (size.x > maxTextWidth) {
        text(classNames.get((i+labelIndex)), pos.x + RAND_X, pos.y + RAND_Y);
      }
    }
    pop();
  }

  @Override
    void mouseDragged() {

    // wenn size.x geändert weden soll (kann man wenn man an der rechten senkrechten Kante zieht)
    if (mousePressed && mouseX < size.x+MAX_MOUSE_SPEED && mouseY < (classNames.size()+1)*size.y) {
      size.x = mouseX;
      size.x = constrain(size.x, RAND_X*2, width-RAND_X*2);
    }
  }

  @Override
    void mouseWheel(MouseEvent evt) {

    if (classNames.size() < MAX_SHOWN_LABELS)
      return;

    labelIndex += evt.getCount();
    labelIndex = constrain(labelIndex, 0, classNames.size()-MAX_SHOWN_LABELS);
  }

  @Override
    void mouseReleased() {

    // pos auf input box
    pos.set(0, 0);
    if (onObject(mouseX, mouseY)) {
      onInputBox = true;
    } else {
      onInputBox = false;
    }

    for (int i = 0; i < min(classNames.size(), MAX_SHOWN_LABELS); i++) {
      pos.y = i*size.y + SIZE.y + 3;

      if (onObject(mouseX, mouseY) && !started) {
        selectedLabel = i+labelIndex;
      }
    }
    println(getLabel());
  }

  @Override
    void keyTyped() {

    if (!onInputBox || started)
      return;

    if (variableInput.length() < 20 && (key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z')) {
      variableInput = variableInput + key;
    } else if (key == BACKSPACE && variableInput.length() > 0) {
      variableInput = variableInput.substring(0, variableInput.length()-1);
    } else if (key == ENTER) {
      addVariable();
    }
  }

  boolean onObject(float x, float y) {
    return x <= pos.x+size.x &&
      x >= pos.x &&
      y <= pos.y+size.y &&
      y >= pos.y;
  }

  void addVariable() {

    String lowerCase = variableInput.toLowerCase();
    if (lowerCase.trim().equals("")) {
      return;
    }

    for (int i = 0; i < classNames.size(); i++) {
      if (classNames.get(i).toLowerCase().equals(lowerCase)) {
        return;
      }
    }

    classNames.add(variableInput);
    if (textWidth(variableInput) > maxTextWidth) {
      maxTextWidth = textWidth(variableInput);
    }
    if (classNames.size() >= MAX_SHOWN_LABELS) {
      labelIndex = classNames.size()-MAX_SHOWN_LABELS;
    }
    selectedLabel = classNames.size()-1;
    variableInput = "";
  }

  String getLabel() {
    if (selectedLabel == -1)
      return null;
    return classNames.get(selectedLabel);
  }
}
