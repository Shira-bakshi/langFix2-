document.getElementById("fix").addEventListener("click", () => {
  const input = document.getElementById("input").value;
  const output = fixTheWord(input);
  document.getElementById("output").value = output;
});

document.getElementById("shortcut-settings").addEventListener("click", () => {
  const isEdge = navigator.userAgent.includes("Edg/");
  const settingsUrl = isEdge
    ? "edge://extensions/shortcuts"
    : "chrome://extensions/shortcuts";
  chrome.tabs.create({ url: settingsUrl });
});
