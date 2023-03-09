static class Worker extends Thread {

  @FunctionalInterface
    interface Executing {
    void f(int i);
  }

  final int BEGIN, END, INCREMENT;
  final Executing func;

  Worker(final int BEGIN, final int END, final int INCREMENT, final Executing func) {
    this.func = func;
    this.BEGIN = BEGIN;
    this.END = END;
    this.INCREMENT = INCREMENT;
  }

  @Override
    void run() {

    for (int i = BEGIN; i < END; i += INCREMENT) {
      func.f(i);
    }
  }
}
