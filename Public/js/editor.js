"use strict";

import "../css/editor.css";

import {
  EditorView,
  keymap,
  lineNumbers,
  drawSelection,
  Decoration,
} from "@codemirror/view";
import {
  EditorState,
  StateField,
  StateEffect,
  EditorSelection,
} from "@codemirror/state";
import {
  defaultKeymap,
  history,
  historyKeymap,
  indentWithTab,
} from "@codemirror/commands";
import {
  StreamLanguage,
  bracketMatching,
  indentUnit,
  syntaxHighlighting,
  defaultHighlightStyle,
} from "@codemirror/language";
import { closeBrackets, closeBracketsKeymap } from "@codemirror/autocomplete";
import { swift } from "@codemirror/legacy-modes/mode/swift";

const addMarksEffect = StateEffect.define();
const clearMarksEffect = StateEffect.define();

const markDecoration = Decoration.mark({ class: "editor-marker" });

const markField = StateField.define({
  create() {
    return Decoration.none;
  },
  update(marks, transaction) {
    marks = marks.map(transaction.changes);
    for (const effect of transaction.effects) {
      if (effect.is(addMarksEffect)) {
        marks = marks.update({ add: effect.value, sort: true });
      } else if (effect.is(clearMarksEffect)) {
        marks = Decoration.none;
      }
    }
    return marks;
  },
  provide: (field) => EditorView.decorations.from(field),
});

export class Editor {
  constructor(container) {
    this.container = container;
    this.changeListeners = [];
    this.init();
  }

  init() {
    const dropHandler = EditorView.domEventHandlers({
      drop: (event) => {
        event.preventDefault();
        event.stopPropagation();

        const files = event.dataTransfer.files;
        if (files.length === 0) {
          return;
        }
        const reader = new FileReader();
        reader.onload = (event) => {
          this.setValue(event.target.result);
        };
        reader.readAsText(files[0], "UTF-8");
      },
    });

    const changeNotifier = EditorView.updateListener.of((update) => {
      if (update.docChanged) {
        for (const listener of this.changeListeners) {
          listener();
        }
      }
    });

    this.view = new EditorView({
      doc: this.container.value,
      parent: this.container.parentElement,
      extensions: [
        lineNumbers(),
        history(),
        drawSelection(),
        EditorView.lineWrapping,
        bracketMatching(),
        closeBrackets(),
        indentUnit.of("  "),
        EditorState.tabSize.of(2),
        syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
        StreamLanguage.define(swift),
        keymap.of([
          ...closeBracketsKeymap,
          ...defaultKeymap,
          ...historyKeymap,
          indentWithTab,
        ]),
        markField,
        changeNotifier,
        dropHandler,
        EditorView.contentAttributes.of({
          "aria-label": "Source code editor",
        }),
      ],
    });
  }

  position(row, column) {
    const lineCount = this.view.state.doc.lines;
    const lineNumber = Math.min(Math.max(row, 1), lineCount);
    const line = this.view.state.doc.line(lineNumber);
    return Math.min(line.from + Math.max(column, 0), line.to);
  }

  getValue() {
    return this.view.state.doc.toString();
  }

  setValue(value) {
    this.view.dispatch({
      changes: { from: 0, to: this.view.state.doc.length, insert: value },
    });
  }

  setSelection(range) {
    const anchor = this.position(range.startRow, range.graphemeStartColumn - 1);
    const head = this.position(range.endRow, range.graphemeEndColumn - 1);
    this.view.dispatch({
      selection: EditorSelection.range(anchor, head),
      scrollIntoView: false,
    });
  }

  markText(range) {
    const from = this.position(range.startRow, range.graphemeStartColumn - 1);
    const to = this.position(range.endRow, range.graphemeEndColumn - 1);
    if (from >= to) {
      return;
    }
    this.view.dispatch({
      effects: addMarksEffect.of([markDecoration.range(from, to)]),
    });
  }

  clearMarks() {
    this.view.dispatch({ effects: clearMarksEffect.of(null) });
  }

  charCoords(range, mode = "page") {
    const pos = this.position(range.startRow, range.startColumn - 1);
    const coords = this.view.coordsAtPos(pos);
    if (!coords) {
      return { left: 0, top: 0, right: 0, bottom: 0 };
    }
    if (mode === "local") {
      // CodeMirror 5's "local" origin is the content area (gutter excluded),
      // so measure relative to .cm-content rather than the scroller. The scroll
      // offset is present in both rects and cancels out in the subtraction.
      const contentRect = this.view.contentDOM.getBoundingClientRect();
      return {
        left: coords.left - contentRect.left,
        top: coords.top - contentRect.top,
        right: coords.right - contentRect.left,
        bottom: coords.bottom - contentRect.top,
      };
    }
    return {
      left: coords.left + window.scrollX,
      top: coords.top + window.scrollY,
      right: coords.right + window.scrollX,
      bottom: coords.bottom + window.scrollY,
    };
  }

  focus() {
    this.view.focus();
  }

  refresh() {
    this.view.requestMeasure();
  }

  on(event, callback) {
    if (event === "change") {
      this.changeListeners.push(callback);
    }
  }
}
