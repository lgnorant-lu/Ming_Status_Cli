import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class badClass {
  var data;
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
    // Removed unused variables x2, y2, z2, a2 to fix dart analyze warnings
    if (x > 0) {
      if (y > 0) {
        if (z > 0) {
          if (a > 0) {
            if (b > 0) {
              if (c > 0) {
                if (d > 0) {
                  if (e > 0) {
                    if (f > 0) {
                      if (g > 0) {
                        return 'deeply nested';
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return 'bad';
  }

  void methodWithoutDocumentation() {
    print('no docs');
  }
}

Widget badWidget() {
  return Container(
    child: Column(
      children: [
        Text(
          'This line is way too long and violates the 80 character limit rule that is commonly used in Dart projects',
        ),
        Container(
          child: Container(
            child: Container(
              child: Text('nested containers'),
            ),
          ),
        ),
      ],
    ),
  );
}
