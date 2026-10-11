const englishToHebrew = {
  a: "ש", b: "נ", c: "ב", d: "ג", e: "ק", f: "כ", g: "ע",
  h: "י", i: "ן", j: "ח", k: "ל", l: "ך", m: "צ", n: "מ",
  o: "ם", p: "פ", q: "/", r: "ר", s: "ד", t: "א", u: "ו",
  v: "ה", w: "'", x: "ס", y: "ט", z: "ז",
  " ": " ", ",": "ת", ".": "ץ", "/": "."
};

const hebrewToEnglish = {
  "ש": "a", "נ": "b", "ב": "c", "ג": "d", "ק": "e", "כ": "f",
  "ע": "g", "י": "h", "ן": "i", "ח": "j", "ל": "k", "ך": "l",
  "צ": "m", "מ": "n", "ם": "o", "פ": "p", "/": "q", "ר": "r",
  "ד": "s", "א": "t", "ו": "u", "ה": "v", "'": "w", "ס": "x",
  "ט": "y", "ז": "z", " ": " ", "ת": ",", "ץ": ".", ".": "/"
};

function fixTheWord(text) {
  const hebrewCount = (text.match(/[\u05D0-\u05EA]/g) || []).length;
  const englishCount = (text.match(/[a-z]/gi) || []).length;

  if (hebrewCount === 0 && englishCount === 0) {
    return text;
  }

  const mapping = hebrewCount > englishCount ? hebrewToEnglish : englishToHebrew;
  return Array.from(text, (character) => {
    const key = /^[A-Z]$/.test(character) ? character.toLowerCase() : character;
    return Object.prototype.hasOwnProperty.call(mapping, key)
      ? mapping[key]
      : character;
  }).join("");
}
