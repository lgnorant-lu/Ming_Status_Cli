import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class badClass {
  var data;
  String veryLongMethodNameThatViolatesNamingConventionsAndMakesCodeHardToReadAndMaintain() {
    final x = 1;
    final y = 2;
    final z = 3;
    final a = 4;
    final b = 5;
    final c = 6;
    final d = 7;
    final e = 8;
    final f = 9;
    final g = 10;
    final h = 11;
    final i = 12;
    final j = 13;
    final k = 14;
    final l = 15;
    final m = 16;
    final n = 17;
    final o = 18;
    final p = 19;
    final q = 20;
    final r = 21;
    final s = 22;
    final t = 23;
    final u = 24;
    final v = 25;
    final w = 26;
    final x2 = 27;
    final y2 = 28;
    final z2 = 29;
    final a2 = 30;
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
        Text('This line is way too long and violates the 80 character limit rule that is commonly used in Dart projects'),
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
