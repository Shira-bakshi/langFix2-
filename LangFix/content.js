function getDeepActiveElement() {
  let activeElement = document.activeElement;

  while (activeElement?.shadowRoot?.activeElement) {
    activeElement = activeElement.shadowRoot.activeElement;
  }

  return activeElement;
}

function getTextControl(element) {
  if (!(element instanceof HTMLInputElement) && !(element instanceof HTMLTextAreaElement)) {
    return null;
  }

  if (element instanceof HTMLInputElement &&
      !["text", "search", "tel", "url"].includes(element.type)) {
    return null;
  }

  if (element.selectionStart === null || element.selectionEnd === null) {
    return null;
  }

  return element;
}

function getEditableHost(element) {
  let host = null;

  while (element) {
    if (element.isContentEditable) {
      host = element;
    }
    element = element.parentElement || element.getRootNode()?.host || null;
  }

  return host;
}

function getWordRange(text, caretOffset) {
  const prefix = text.slice(0, caretOffset);
  const match = /([\p{L}\p{N}_'’]+)[^\p{L}\p{N}_'’]*$/u.exec(prefix);

  if (!match) {
    return null;
  }

  const start = match.index;
  return { start, end: start + match[1].length, text: match[1] };
}

function getTextControlTarget(element) {
  const { selectionStart, selectionEnd, value } = element;
  if (selectionStart !== selectionEnd) {
    return {
      element,
      start: selectionStart,
      end: selectionEnd,
      text: value.slice(selectionStart, selectionEnd),
      wasSelected: true,
      selectionDirection: element.selectionDirection
    };
  }

  const word = getWordRange(value, selectionStart);
  if (!word) {
    return null;
  }

  return {
    element,
    start: word.start,
    end: word.end,
    text: word.text,
    wasSelected: false,
    selectionDirection: element.selectionDirection
  };
}

function setNativeValue(element, value) {
  const prototype = element instanceof HTMLTextAreaElement
    ? HTMLTextAreaElement.prototype
    : HTMLInputElement.prototype;
  const setter = Object.getOwnPropertyDescriptor(prototype, "value")?.set;

  if (!setter) {
    throw new Error("This text field does not expose a native value setter.");
  }

  setter.call(element, value);
}

function replaceTextControlTarget(target, replacement) {
  const { element, start, end, text, wasSelected, selectionDirection } = target;
  const value = element.value;
  const updatedValue = value.slice(0, start) + replacement + value.slice(end);
  setNativeValue(element, updatedValue);
  element.dispatchEvent(new InputEvent("input", {
    bubbles: true,
    composed: true,
    inputType: "insertReplacementText",
    data: replacement
  }));

  const replacementEnd = start + replacement.length;
  element.setSelectionRange(
    wasSelected ? start : replacementEnd,
    replacementEnd,
    selectionDirection || "none"
  );
}

function getRangeBeforeCaret(root, caretRange, characterCount) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  const textNodes = [];
  let node;

  while ((node = walker.nextNode())) {
    textNodes.push(node);
  }

  let remaining = characterCount;
  for (let index = textNodes.length - 1; index >= 0; index--) {
    node = textNodes[index];
    let available;

    if (node === caretRange.startContainer) {
      available = caretRange.startOffset;
    } else {
      const relation = caretRange.comparePoint(node, node.length);
      if (relation > 0) {
        continue;
      }
      available = node.length;
    }

    if (available === 0) {
      continue;
    }

    const take = Math.min(remaining, available);
    const result = document.createRange();
    result.setStart(node, available - take);
    result.setEnd(caretRange.startContainer, caretRange.startOffset);
    remaining -= take;
    if (remaining === 0) {
      return result;
    }
  }

  return null;
}

function getContentEditableTarget(host, selection) {
  if (!selection || selection.rangeCount === 0) {
    return null;
  }

  const currentRange = selection.getRangeAt(0);
  if (!host.contains(currentRange.commonAncestorContainer)) {
    return null;
  }

  if (!currentRange.collapsed) {
    const text = currentRange.toString();
    if (!text) {
      return null;
    }
    return { host, range: currentRange.cloneRange(), text, wasSelected: true };
  }

  const prefixRange = document.createRange();
  prefixRange.selectNodeContents(host);
  prefixRange.setEnd(currentRange.startContainer, currentRange.startOffset);
  const word = getWordRange(prefixRange.toString(), prefixRange.toString().length);
  if (!word) {
    return null;
  }

  const wordRange = getRangeBeforeCaret(host, currentRange, word.text.length);
  return wordRange
    ? { host, range: wordRange, text: word.text, wasSelected: false }
    : null;
}

function dispatchEditableInput(host, text) {
  host.dispatchEvent(new InputEvent("input", {
    bubbles: true,
    composed: true,
    inputType: "insertReplacementText",
    data: text
  }));
}

function replaceContentEditableTarget(target, replacement) {
  const { host, range, wasSelected } = target;
  host.focus();
  const selection = window.getSelection();
  selection.removeAllRanges();
  selection.addRange(range);

  if (!document.execCommand("insertText", false, replacement)) {
    const insertedText = document.createTextNode(replacement);
    range.deleteContents();
    range.insertNode(insertedText);

    const caret = document.createRange();
    caret.setStartAfter(insertedText);
    caret.collapse(true);
    selection.removeAllRanges();
    selection.addRange(caret);
    dispatchEditableInput(host, replacement);
  }

  if (wasSelected) {
    const caret = selection.rangeCount > 0 ? selection.getRangeAt(0) : null;
    if (caret?.collapsed) {
      const insertedRange = getRangeBeforeCaret(host, caret, replacement.length);
      if (insertedRange) {
        selection.removeAllRanges();
        selection.addRange(insertedRange);
      }
    }
  }
}

function showStatus(message, isError = false) {
  let status = document.getElementById("langfix-status");
  if (!status) {
    status = document.createElement("div");
    status.id = "langfix-status";
    Object.assign(status.style, {
      position: "fixed",
      zIndex: "2147483647",
      right: "16px",
      bottom: "16px",
      padding: "10px 14px",
      borderRadius: "8px",
      color: "#fff",
      background: "#333",
      font: "14px/1.4 sans-serif",
      boxShadow: "0 2px 10px rgba(0,0,0,.25)",
      pointerEvents: "none",
      direction: "rtl"
    });
    document.documentElement.append(status);
  }

  status.textContent = message;
  status.style.background = isError ? "#9b2525" : "#333";
  clearTimeout(Number(status.dataset.hideTimer));
  status.dataset.hideTimer = String(setTimeout(() => status.remove(), 2200));
}

function fixActiveEditor() {
  const activeElement = getDeepActiveElement();
  const textControl = getTextControl(activeElement);
  const activeEditableHost = getEditableHost(activeElement);

  if (!textControl && !activeEditableHost) {
    return;
  }

  let target = textControl ? getTextControlTarget(textControl) : null;
  if (!target && activeEditableHost) {
    const selection = window.getSelection();
    target = getContentEditableTarget(activeEditableHost, selection);
  }

  if (!target || !target.text.trim()) {
    showStatus("סמני טקסט או הציבי את הסמן אחרי מילה לעריכה.", true);
    return;
  }

  try {
    const fixedText = fixTheWord(target.text);
    if (fixedText === target.text) {
      showStatus("לא נמצאה מילה בעברית או באנגלית להמרה.", true);
      return;
    }

    if (target.element) {
      replaceTextControlTarget(target, fixedText);
    } else {
      replaceContentEditableTarget(target, fixedText);
    }
    showStatus("הטקסט הומר.");
  } catch (error) {
    console.error("LangFix could not convert the current editor text.", error);
    showStatus("לא ניתן להמיר את הטקסט בשדה הזה.", true);
  }
}

chrome.runtime.onMessage.addListener((request) => {
  if (request.action === "fixText") {
    fixActiveEditor();
  }
});
