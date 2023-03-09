static abstract class Window extends PApplet {

  boolean freezed = false;

  // Anordnung der Fenster
  static final int OFFSET_X = 450;
  static final int OFFSET_Y = 250;

  @Override
    void settings() {
    size(950, 400);
  }

  @Override
    abstract void setup();
  @Override
    abstract void draw();

  @Override
    void exit() {
    freeze();
  }

  void freeze() {
    this.surface.setVisible(false);
    freezed = true;
  }

  void deFreeze() {

    if (surface == null) {
      PApplet.runSketch(new String[]{getClass().getSimpleName()}, this);
      return;
    }
    this.surface.setVisible(true);
    freezed = false;
  }
}
