class badClass {
  dynamic data;
  String
      veryLongMethodNameThatViolatesNamingConventionsAndMakesCodeHardToReadAndMaintain() {
    const x = 1;
    const y = 2;
    const z = 3;
    const a = 4;
    const b = 5;
    const c = 6;
    const d = 7;
    const e = 8;
    const f = 9;
    const g = 10;
    const h = 11;
    const i = 12;
    const j = 13;
    const k = 14;
    const l = 15;
    const m = 16;
    const n = 17;
    const o = 18;
    const p = 19;
    const q = 20;
    const r = 21;
    const s = 22;
    const t = 23;
    const u = 24;
    const v = 25;
    const w = 26;
    // Use all variables to avoid warnings
    const sum = x +
        y +
        z +
        a +
        b +
        c +
        d +
        e +
        f +
        g +
        h +
        i +
        j +
        k +
        l +
        m +
        n +
        o +
        p +
        q +
        r +
        s +
        t +
        u +
        v +
        w;
    if (sum > 0) {
      return 'deeply nested';
    }
    return 'bad';
  }

  void methodWithoutDocumentation() {
    print('no docs');
  }
}

String badWidget() {
  return 'This line is way too long and violates the 80 character limit rule that is commonly used in Dart projects';
}
