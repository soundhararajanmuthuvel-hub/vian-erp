// Stub for platforms that don't support dart:js (like mobile)
class StubJsContext {
  dynamic operator [](dynamic key) => null;
  void callMethod(String name, [List? args]) {}
}

final context = StubJsContext();
