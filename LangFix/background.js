chrome.runtime.onInstalled.addListener(() => {
  console.info("LangFix installed. Use Alt+X to convert text in the focused browser editor.");
});

chrome.commands.onCommand.addListener((command) => {
  if (command !== "fix-text") {
    return;
  }

  chrome.tabs.query({ active: true, lastFocusedWindow: true }, (tabs) => {
    if (chrome.runtime.lastError) {
      console.error("LangFix could not find the active tab:", chrome.runtime.lastError.message);
      return;
    }

    const activeTab = tabs[0];
    if (!activeTab?.id) {
      console.error("LangFix could not find an active browser tab.");
      return;
    }

    chrome.tabs.sendMessage(activeTab.id, { action: "fixText" }, () => {
      if (chrome.runtime.lastError) {
        console.warn(
          "LangFix could not reach an editor on this page. The page may be restricted, " +
          "or the shortcut may need to be changed in the browser's extension shortcut settings.",
          chrome.runtime.lastError.message
        );
      }
    });
  });
});
