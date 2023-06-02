"use strict";

import { Tooltip } from "bootstrap";
import { Editor } from "./editor.js";
import { Balloon } from "./balloon.js";
import { StructureView } from "./structure_view.js";
import { LookupView } from "./lookup_view.js";
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

    this.cache = {};

    this.structureView = new StructureView(
      document.getElementById("structure-container")
    );
    this.lookupView = new LookupView(
      document.getElementById("lookup-container")
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

    document.addEventListener("show.bs.tab", (event) => {
      this.updateActiveTab(event.target);
    });
    document.addEventListener("hidden.bs.tab", (event) => {
      const hiddenTab = event.target;
      switch (hiddenTab.dataset.bsTarget) {
        case "#structure-tab-pane":
          document.getElementById("structure-container").innerHTML = "";
          break;
        case "#lookup-tab-pane":
          document.getElementById("lookup-container").innerHTML = "";
          break;
        case "#statistics-tab-pane":
          document.getElementById("statistics-container").innerHTML = "";
          break;
      }
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
    this.invalidateCache();

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
      .then((response) => {
        this.response = response;
        this.structureData = JSON.parse(
          response.syntaxJSON
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/'/g, "&#039;")
        );

        this.updateActiveTab();
      })
      .catch((error) => {
        this.structureView.error = error;
        this.lookupView.error = error;
        this.statisticsView.error = error;
      })
      .finally(() => {
        hideLoading();
        this.editor.focus();
      });
  }

  updateActiveTab(tab) {
    const activeTab = tab || document.querySelector(".nav-link.active");
    switch (activeTab.dataset.bsTarget) {
      case "#structure-tab-pane":
        this.updateStructure();
        break;
      case "#lookup-tab-pane":
        this.updateLookup();
        break;
      case "#statistics-tab-pane":
        this.updateStatistics();
        break;
    }

    this.onresize();
  }

  updateStructure() {
    this.renderWithCache("structure-container", () => {
      if (this.structureData === undefined) {
        return;
      }
      const data = this.structureData;
      this.structureView.update(data);
    });

    this.structureView.onmouseover = (event, target, data) => {
      const title = data.token ? "Token" : `${data.text}`;
      const range = data.range;

      const formatted = formatRange(range);
      this.balloon.setContent(
        `<div class="title">${title}</div><div class="range">${formatted}</div>`
      );
      this.balloon.show(this.editor.charCoords(range), {
        placement: "top",
        offset: { x: 10, y: -6 },
      });

      this.editor.setSelection(range);
    };
    this.structureView.onmouseout = (event, target, data) => {
      this.balloon.hide();
      this.editor.clearSelection();
    };
  }

  updateLookup() {
    this.renderWithCache("lookup-container", () => {
      const data = this.response.syntaxHTML;
      this.lookupView.update(data);
    });
  }

  updateStatistics() {
    this.renderWithCache("statistics-container", () => {
      if (this.structureData === undefined) {
        return;
      }
      const data = this.structureData;

      const statistics = data
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

      this.statisticsView.update(statistics);
    });

    this.statisticsView.onmouseover = (event, target, ranges) => {
      const content = ranges
        .map((range) => {
          return {
            startRow: range.startRow
              .toString()
              .padStart(2, " ")
              .replace(" ", "&nbsp;"),
            startColumn: range.startColumn
              .toString()
              .padEnd(2, " ")
              .replace(" ", "&nbsp;"),
            endRow: range.endRow
              .toString()
              .padStart(2, " ")
              .replace(" ", "&nbsp;"),
            endColumn: range.endColumn
              .toString()
              .padEnd(2, " ")
              .replace(" ", "&nbsp;"),
          };
        })
        .map((range) => {
          return `<div class="range">${formatRange(range)}</div>`;
        })
        .join("");
      this.balloon.setContent(content);

      const tabContainer = document.querySelector(".tab-content");

      const rect = target.getBoundingClientRect();
      this.balloon.show(rect, {
        placement: "top",
        offset: { x: 10, y: -6 },
        containerRect: {
          left: tabContainer.offsetLeft,
          top: tabContainer.offsetTop,
          width: tabContainer.clientWidth,
          height: tabContainer.clientHeight,
        },
      });

      for (const range of ranges) {
        this.editor.markText(range);
      }
    };
    this.statisticsView.onmouseout = (event, target) => {
      this.balloon.hide();
      this.editor.clearMarks();
    };
  }

  onresize() {
    document.querySelector(".CodeMirror").style.height = this.contentViewHeight;
    this.editor.refresh();

    document.getElementById("structure-container").style.height =
      this.contentViewHeight;
    document.getElementById("lookup-container").style.height =
      this.contentViewHeight;
    document.getElementById("statistics-container").style.height =
      this.contentViewHeight;
  }

  renderWithCache(id, render) {
    const container = document.getElementById(id);
    if (this.cache[id]) {
      container.appendChild(this.cache[id]);
      return;
    }
    render();
    this.cache[id] = container.querySelector(":scope > div");
  }

  invalidateCache() {
    this.cache = {};
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

function formatRange(range) {
  return `${range.startRow}:${range.startColumn} - ${range.endRow}:${range.endColumn}`;
}
