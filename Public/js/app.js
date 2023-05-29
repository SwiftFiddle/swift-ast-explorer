"use strict";

import { Tooltip } from "bootstrap";
import { Editor } from "./editor.js";
import { Balloon } from "./balloon.js";
import { StructureView } from "./structure_view.js";
import { SyntaxView } from "./syntax_view.js";
import { StatisticsView } from "./statistics_view.js";
import { WebSocketClient } from "./websocket.js";
import { debounce } from "./debounce.js";

export class App {
  get contentViewHeight() {
    const headerHeight = document.querySelector("header").clientHeight;
    const footerHeight = document.querySelector("footer").clientHeight;
    const viewport = CSS.supports("height", "100svh") ? "100svh" : "100vh";
    return `calc(${viewport} - ${headerHeight}px - ${footerHeight}px)`;
  }

  constructor() {
    this.editor = new Editor(document.getElementById("editor-container"));
    this.balloon = new Balloon();

    this.structureView = new StructureView(
      document.getElementById("structure")
    );
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
    this.editor.on("change", () => {
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

    const onresize = debounce(() => {
      this.onresize();
    }, 200);
    new ResizeObserver(() => {
      onresize();
    }).observe(document.body);

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

        this.onresize();
      })
      .catch((error) => {
        this.structureView.error = error;
        this.syntaxView.error = error;
        this.statisticsView.error = error;
      })
      .finally(() => {
        hideLoading();
        this.editor.focus();
      });
  }

  updateStructure(structureData) {
    this.structureView.update(structureData);

    this.structureView.onmouseover = (event, target, data) => {
      const title = data.token ? "Token" : `${data.text}`;
      const range = data.range;

      this.balloon.content = `<div class="title">${title}</div><div class="range">${range.startRow}:${range.startColumn} - ${range.endRow}:${range.endColumn}</div>`;
      this.balloon.show(this.editor.charCoords(range));

      this.editor.setSelection(range);
    };
    this.structureView.onmouseout = (event, target, data) => {
      this.balloon.hide();
      this.editor.clearSelection();
    };
  }

  updateSyntaxMap(syntaxHTML) {
    this.syntaxView.update(syntaxHTML);
  }

  updateStatistics(statistics) {
    this.statisticsView.update(statistics);

    this.statisticsView.onmouseover = (event, target, ranges) => {
      for (const range of ranges) {
        this.editor.markText(range);
      }
    };
    this.statisticsView.onmouseout = (event, target) => {
      this.editor.clearMarks();
    };
  }

  onresize() {
    document.querySelector(".CodeMirror").style.height = this.contentViewHeight;
    this.editor.refresh();

    document.getElementById("structure").style.height = this.contentViewHeight;
    document.getElementById("syntax-container").style.height =
      this.contentViewHeight;
    document.getElementById("statistics-container").style.height =
      this.contentViewHeight;
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
