public class Events {

  Events() {
    registerMethod("mouseEvent", this);
    registerMethod("keyEvent", this);
  }

  void ignore(boolean ignore) {

    if (ignore) {
      unregisterMethod("mouseEvent", this);
      unregisterMethod("keyEvent", this);
    } else {
      registerMethod("mouseEvent", this);
      registerMethod("keyEvent", this);
    }
  }

  void mouseEvent(final MouseEvent evt) {
    switch(evt.getAction()) {
    case MouseEvent.PRESS:
      mousePressed();
      break;
    case MouseEvent.RELEASE:
      mouseReleased();
      break;
    case MouseEvent.MOVE:
      mouseMoved();
      break;
    case MouseEvent.DRAG:
      mouseDragged();
      break;
    case MouseEvent.WHEEL:
      mouseWheel(evt);
    }
  }
  void mouseWheel(MouseEvent evt) {
  }
  void mousePressed() {
  }
  void mouseReleased() {
  }
  void mouseMoved() {
  }
  void mouseDragged() {
  }

  void keyEvent(final KeyEvent evt) {
    switch(evt.getAction()) {
    case KeyEvent.PRESS:
      keyPressed();
      break;
    case KeyEvent.RELEASE:
      keyReleased();
      break;
    case KeyEvent.TYPE:
      keyTyped();
      break;
    }
  }

  void keyPressed() {
  }
  void keyReleased() {
  }
  void keyTyped() {
  }
}
