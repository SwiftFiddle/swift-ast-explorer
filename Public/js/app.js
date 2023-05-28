"use strict";

import { Tooltip } from "bootstrap";
import { TreeView } from "./tree_view.js";
import { SyntaxView } from "./syntax_view.js";
import { StatisticsView } from "./statistics_view.js";
import { Popover } from "./popover.js";
import { WebSocketClient } from "./websocket.js";
import { debounce } from "./debounce.js";

import "../css/editor.css";
import "../css/syntax.css";

import "ace-builds/src-min-noconflict/ace";
import "ace-builds/src-min-noconflict/ext-language_tools";
import "ace-builds/src-min-noconflict/mode-swift";
import "ace-builds/src-min-noconflict/theme-xcode";
const Range = ace.require("ace/range").Range;

export class App {
  get contentMaxHeight() {
    const headerHeight = document.querySelector("header").clientHeight;
    const footerHeight = document.querySelector("footer").clientHeight;
    return `calc(100vh - ${headerHeight}px - ${footerHeight}px)`;
  }

  constructor() {
    this.editor = ace.edit("editor-container");
    this.editor.setTheme("ace/theme/xcode");
    this.editor.session.setMode("ace/mode/swift");
    this.editor.$blockScrolling = Infinity;
    this.editor.setOptions({
      tabSize: 2,
      useSoftTabs: true,
      autoScrollEditorIntoView: true,
      fontFamily:
        "Menlo, Consolas, 'DejaVu Sans Mono', 'Ubuntu Mono', monospace",
      fontSize: "11pt",
      showInvisibles: false,
      enableAutoIndent: true,
      enableBasicAutocompletion: true,
      enableSnippets: true,
      enableLiveAutocompletion: true,
      scrollPastEnd: 0.5, // Overscroll
      wrap: "free",
      displayIndentGuides: true,
    });
    this.editor.renderer.setOptions({
      showFoldWidgets: false,
      showPrintMargin: false,
    });

    this.treeViewContainer = document.getElementById("structure");
    this.popover = new Popover();

    this.syntaxView = new SyntaxView(
      document.getElementById("syntax-container")
    );
    this.statisticsView = new StatisticsView(
      document.getElementById("statistics-container")
    );

    this.init();
  }

  init() {
    [].slice
      .call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
      .map((trigger) => {
        return new Tooltip(trigger);
      });

    const updateOnTextChange = debounce(() => {
      this.update();
    }, 400);
    this.editor.on("change", (change) => {
      updateOnTextChange();
    });

    document.getElementById("run-button").addEventListener("click", (event) => {
      event.preventDefault();
      this.update();
    });

    document.getElementById("config-button").classList.remove("disabled");
    document.querySelectorAll(".options-item").forEach((listItem) => {
      listItem.addEventListener("click", (event) => {
        event.preventDefault();
        listItem.classList.toggle("active-tick");
        this.update();
      });
    });

    const formatter = new WebSocketClient("wss://swift-format.com/api/ws");
    formatter.onresponse = (response) => {
      if (!response) {
        return;
      }
      if (response.output) {
        this.editor.setValue(response.output);
        this.editor.clearSelection();
      }
    };
    const formatButton = document.getElementById("format-button");
    formatButton.classList.remove("disabled");
    formatButton.addEventListener("click", (event) => {
      event.preventDefault();
      formatter.send({ code: this.editor.getValue() });
    });

    const dropZone = document.getElementById("editor-container");
    dropZone.addEventListener(
      "dragover",
      (event) => {
        event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect = "copy";
      },
      false
    );
    dropZone.addEventListener(
      "drop",
      (event) => {
        event.stopPropagation();
        event.preventDefault();

        const files = event.dataTransfer.files;
        const reader = new FileReader();
        reader.onload = (event) => {
          this.editor.setValue(event.target.result);
          this.editor.clearSelection();
        };
        reader.readAsText(files[0], "UTF-8");
      },
      false
    );

    this.update();
  }

  update() {
    showLoading();

    const options = configurations();

    const code = this.editor.getValue();
    const json = {
      code,
      options,
    };
    fetch("/update", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(json),
    })
      .then((response) => response.json())
      .then((data) => {
        const structureData = JSON.parse(
          data.syntaxJSON
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/'/g, "&#039;")
        );

        this.updateStructure(structureData);
        this.updateSyntaxMap(data.syntaxHTML);

        const statistics = structureData
          .filter((node) => node.token === undefined)
          .reduce((acc, item) => {
            const existingItem = acc.find((a) => a.text === item.text);
            if (existingItem) {
              existingItem.ranges.push(item.range);
            } else {
              acc.push({ text: item.text, ranges: [item.range] });
            }
            return acc;
          }, []);
        this.updateStatistics(statistics);

        document.getElementById("structure").style.maxHeight =
          this.contentMaxHeight;
        document.getElementById("syntax-container").style.maxHeight =
          this.contentMaxHeight;
        document.getElementById("statistics-container").style.maxHeight =
          this.contentMaxHeight;
      })
      .catch((error) => {
        if (error.status == 413) {
          alert("Payload Too Large");
        } else {
          alert("Something went wrong");
        }
      })
      .finally(() => {
        hideLoading();
        this.editor.focus();
      });
  }

  updateStructure(structureData) {
    this.treeViewContainer.innerHTML = "";
    this.treeView = new TreeView(this.treeViewContainer, structureData);

    let mouseoverCancel = undefined;
    this.treeView.onmouseover = (event, target, data) => {
      this.editor.selection.setRange(
        new Range(
          data.range.startRow,
          data.range.startColumn,
          data.range.endRow,
          data.range.endColumn
        )
      );

      if (mouseoverCancel) {
        cancelAnimationFrame(mouseoverCancel);
      }
      mouseoverCancel = requestAnimationFrame(() => {
        if (!data.structure.length && !data.token) {
          return;
        }
        if (data.structure.length > 0) {
          const container = document.createElement("div");

          const title = document.createElement("div");
          title.classList.add("title");
          title.innerText = `${data.text}Syntax`;
          container.appendChild(title);

          switch (data.type) {
            case "decl": {
              const label = document.createElement("span");
              label.classList.add("badge", "text-bg-light");
              label.innerText = "DeclSyntax";
              title.appendChild(label);
              break;
            }
            case "expr": {
              const label = document.createElement("span");
              label.classList.add("badge", "text-bg-light");
              label.innerText = "ExprSyntax";
              title.appendChild(label);
              break;
            }
            case "pattern": {
              const label = document.createElement("span");
              label.classList.add("badge", "text-bg-light");
              label.innerText = "PatternSyntax";
              title.appendChild(label);
              break;
            }
            case "type": {
              const label = document.createElement("span");
              label.classList.add("badge", "text-bg-light");
              label.innerText = "TypeSyntax";
              title.appendChild(label);
              break;
            }
            default:
              break;
          }

          const dl = document.createElement("dl");

          const dt = document.createElement("dt");
          const dd = document.createElement("dd");

          dt.innerHTML = "Source Range";
          const range = data.range;
          // prettier-ignore
          dd.innerHTML = `Ln ${range.startRow + 1}, Col ${range.startColumn + 1} - Ln ${range.endRow + 1}, Col ${range.endColumn + 1}`;

          dl.appendChild(dt);
          dl.appendChild(dd);

          for (const property of data.structure) {
            const dt = document.createElement("dt");
            const dd = document.createElement("dd");

            const name = property.name;
            const value = property.value;
            if (value && value.text && value.kind) {
              const text = stripHTMLTag(value.text);
              const kind = stripHTMLTag(value.kind);
              dt.innerHTML = `${name}`;
              dd.innerHTML = `${text}<span class="badge rounded-pill">${kind}</span>`;
            } else if (value && value.text) {
              const text = stripHTMLTag(value.text);
              dt.innerHTML = `${name}`;
              dd.innerHTML = `${text}`;
            }
            dl.appendChild(dt);
            dl.appendChild(dd);
          }
          container.appendChild(dl);

          this.popover.content = container.innerHTML;
        }
        if (data.token) {
          const container = document.createElement("div");

          const title = document.createElement("div");
          title.classList.add("title");
          title.innerText = "TokenSyntax";
          container.appendChild(title);

          const dl = document.createElement("dl");

          {
            const dt = document.createElement("dt");
            const dd = document.createElement("dd");

            dt.innerHTML = "Source Range";
            const range = data.range;
            // prettier-ignore
            dd.innerHTML = `Ln ${range.startRow + 1}, Col ${range.startColumn + 1} - Ln ${range.endRow + 1}, Col ${range.endColumn + 1}`;

            dl.appendChild(dt);
            dl.appendChild(dd);
          }

          {
            const dt = document.createElement("dt");
            dt.innerHTML = "kind";
            dl.appendChild(dt);

            const dd = document.createElement("dd");
            dd.innerHTML = stripHTMLTag(data.token.kind);
            dl.appendChild(dd);
          }
          {
            const dt = document.createElement("dt");
            dt.innerHTML = "leadingTrivia";
            dl.appendChild(dt);

            const dd = document.createElement("dd");
            dd.innerHTML = stripHTMLTag(data.token.leadingTrivia);
            dl.appendChild(dd);
          }
          {
            const dt = document.createElement("dt");
            dt.innerHTML = "text";
            dl.appendChild(dt);

            const dd = document.createElement("dd");
            dd.innerHTML = stripHTMLTag(data.text);
            dl.appendChild(dd);
          }
          {
            const dt = document.createElement("dt");
            dt.innerHTML = "trailingTrivia";
            dl.appendChild(dt);

            const dd = document.createElement("dd");
            dd.innerHTML = stripHTMLTag(data.token.trailingTrivia);

            dl.appendChild(dd);
          }
          container.appendChild(dl);

          this.popover.content = container.innerHTML;
        }

        const tabContainerRect = document
          .querySelector(".tab-content")
          .getBoundingClientRect();

        const parent = target.parentElement;
        const caret = parent.querySelector(":scope > div > .caret");
        this.popover.show(caret || target, {
          lowerLimit: tabContainerRect.top + tabContainerRect.height,
          offsetX: caret ? 0 : 24,
        });
      });
    };

    let mouseoutCancel = undefined;
    this.treeView.onmouseout = (event, target, data) => {
      if (mouseoutCancel) {
        cancelAnimationFrame(mouseoutCancel);
      }
      mouseoutCancel = requestAnimationFrame(() => {
        if (!event.relatedTarget.classList.contains("popover-content")) {
          this.popover.hide();
        }
      });
    };

    let mouseoutCancel2 = undefined;
    this.popover.onmouseout = (event) => {
      if (mouseoutCancel2) {
        cancelAnimationFrame(mouseoutCancel2);
      }
      mouseoutCancel2 = requestAnimationFrame(() => {
        this.popover.hide();
      });
    };
  }

  updateSyntaxMap(syntaxHTML) {
    this.syntaxView.update(syntaxHTML);
  }

  updateStatistics(statistics) {
    this.statisticsView.update(statistics);

    this.statisticsView.onmouseover = (event, target, ranges) => {
      for (const range of ranges) {
        this.editor.session.addMarker(
          new Range(
            range.startRow,
            range.startColumn,
            range.endRow,
            range.endColumn
          ),
          "editor-marker",
          "text"
        );
      }
    };
    this.statisticsView.onmouseout = (event, target) => {
      const markers = this.editor.session.getMarkers();
      for (const [key, value] of Object.entries(markers)) {
        this.editor.session.removeMarker(value.id);
      }
    };
  }
}

function configurations() {
  const options = [];
  document.querySelectorAll(".options-item").forEach((listItem) => {
    if (listItem.classList.contains("active-tick")) {
      options.push(listItem.dataset.value);
    }
  });
  return options;
}

function showLoading() {
  document.getElementById("run-button").classList.add("disabled");
  document.getElementById("run-button-icon").classList.add("d-none");
  document.getElementById("run-button-spinner").classList.remove("d-none");
}

function hideLoading() {
  document.getElementById("run-button").classList.remove("disabled");
  document.getElementById("run-button-icon").classList.remove("d-none");
  document.getElementById("run-button-spinner").classList.add("d-none");
}

function stripHTMLTag(text) {
  const div = document.createElement("div");
  div.innerHTML = text
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#039;/g, "'")
    .replace(/&amp;/g, "&");
  return escapeHTML(div.textContent || div.innerText || "");
}

function escapeHTML(text) {
  const div = document.createElement("div");
  div.appendChild(document.createTextNode(text));
  return div.innerHTML;
}
