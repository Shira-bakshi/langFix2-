#!/usr/bin/env node
// Simple CLI that reads stdin, fixes the keyboard-swapped Hebrew/Latin text and writes to stdout
process.stdin.setEncoding('utf8');
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  const langMap = {
    "a": "ש", "b": "נ", "c": "ב", "d": "ג", "e": "ק", "f": "כ", "g": "ע",
    "h": "י", "i": "ן", "j": "ח", "k": "ל", "l": "ך", "m": "צ", "n": "מ",
    "o": "ם", "p": "פ", "q": "/", "r": "ר", "s": "ד", "t": "א", "u": "ו",
    "v": "ה", "w": "'", "x": "ס", "y": "ט", "z": "ז",
    "A": "ש", "B": "נ", "C": "ב", "D": "ג", "E": "ק", "F": "כ", "G": "ע",
    "H": "י", "I": "ן", "J": "ח", "K": "ל", "L": "ך", "M": "צ", "N": "מ",
    "O": "ם", "P": "פ", "Q": "/", "R": "ר", "S": "ד", "T": "א", "U": "ו",
    "V": "ה", "W": "'", "X": "ס", "Y": "ט", "Z": "ז", " ": " ", ",": "ת", ".": "ץ",
    "/": ".",
    "ש": "a", "נ": "b", "ב": "c", "ג": "d", "ק": "e", "כ": "f", "ע": "g",
    "י": "h", "ן": "i", "ח": "j", "ל": "k", "ך": "l", "צ": "m", "מ": "n",
    "ם": "o", "פ": "p", "/": "q", "ר": "r", "ד": "s", "א": "t", "ו": "u",
    "ה": "v", "'": "w", "ס": "x", "ט": "y", "ז": "z",
    " ": " ", "ת": ",", "ץ": ".", ".": "/"
  };

  function fixTheWord(text) {
    let result = "";
    for (const ch of text) {
      result += (langMap[ch] !== undefined ? langMap[ch] : ch);
    }
    return result;
  }

  const out = fixTheWord(input);
  process.stdout.write(out);
});
