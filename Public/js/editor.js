"use strict";

import "codemirror/lib/codemirror.css";
import "../css/editor.css";

import CodeMirror from "codemirror";
import "codemirror/mode/swift/swift";
import "codemirror/addon/edit/matchbrackets";
import "codemirror/addon/edit/closebrackets";

export class Editor {
  constructor(container) {
    this.container = container;
    this.init();
  }

  init() {
    this.editor = CodeMirror.fromTextArea(this.container, {
      autoCloseBrackets: true,
      lineNumbers: true,
      lineWrapping: true,
      matchBrackets: true,
      mode: "swift",
      screenReaderLabel: "Source code editor",
      tabSize: 2,
    });
    this.editor.setSize("100%", "100%");

    this.editor.on("drop", (editor, event) => {
      event.preventDefault();
      event.stopPropagation();

      const files = event.dataTransfer.files;
      if (files.length === 0) {
        return;
      }
      const reader = new FileReader();
      reader.onload = (event) => {
        this.editor.setValue(event.target.result);
      };
      reader.readAsText(files[0], "UTF-8");
    });
  }

  getValue() {
    return this.editor.getValue();
  }

  setValue(value) {
    this.editor.setValue(value);
  }

  setSelection(range) {
    this.editor.setSelection(
      { ch: range.startColumn - 1, line: range.startRow - 1 },
      { ch: range.endColumn - 1, line: range.endRow - 1 },
      { scroll: false }
    );
  }

  markText(range) {
    return this.editor.markText(
      { ch: range.startColumn - 1, line: range.startRow - 1 },
      { ch: range.endColumn - 1, line: range.endRow - 1 },
      {
        className: "editor-marker",
        startStyle: "editor-marker-start",
        endStyle: "editor-marker-end",
      }
    );
  }

  clearMarks() {
    this.editor.getAllMarks().forEach((mark) => {
      mark.clear();
    });
  }

  charCoords(range) {
    return this.editor.charCoords(
      { ch: range.startColumn - 1, line: range.startRow - 1 },
      "page"
    );
  }

  focus() {
    this.editor.focus();
  }

  refresh() {
    this.editor.refresh();
  }

  on(event, callback) {
    this.editor.on(event, callback);
  }
}
