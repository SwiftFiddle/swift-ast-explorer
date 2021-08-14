"use strict";

import "./logger.js";
import { SwiftFormat } from "./swift_format.js";

ace.require("ace/ext/language_tools");
const Range = ace.require("ace/range").Range;

const editor = ace.edit("editor-container");
editor.setTheme("ace/theme/xcode");
editor.session.setMode("ace/mode/swift");
editor.$blockScrolling = Infinity;
editor.setOptions({
  tabSize: 2,
  useSoftTabs: true,
  autoScrollEditorIntoView: true,
  fontFamily: "Menlo,sans-serif,monospace",
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
editor.renderer.setOptions({
  showFoldWidgets: false,
  showPrintMargin: false,
});

const results = $("#results");
let tree = null;

setTimeout(() => {
  update(editor);
}, 400);

const updateOnTextChange = $.debounce(400, (editor) => {
  update(editor);
});
editor.on("change", (change, editor) => {
  updateOnTextChange(editor);
});

$("#run-button").on("click", (e) => {
  e.preventDefault();
  update(editor);
});

function update(editor) {
  showLoading();

  const code = editor.getValue();
  const json = {
    code: code,
  };
  $.post("/update", json)
    .done(function (data, xhr) {
      results.html(data.syntaxHTML);

      if (tree) {
        tree.destroy();
      }
      tree = $("#structure").tree({
        dataSource: JSON.parse(
          data.syntaxJSON
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/'/g, "&#039;")
        ),
      });

      const children = tree.getChildren(tree);
      for (let i = 0, len = children.length; i < Math.min(len, 100); i++) {
        tree.expand(tree.getNodeById(children[i]));
      }

      updateStructureTree();
      updateSyntaxSourceMap();
      updateStatisticsTable(data.statistics);
    })
    .fail(function (response) {
      if (response.status == 413) {
        alert("Payload Too Large");
      } else {
        alert("Something went wrong");
      }
    })
    .always(function () {
      hideLoading();
      editor.focus();
    });
}

function updateStructureTree() {
  $("#structure")
    .find("li")
    .each(function (i, element) {
      const id = $(element).attr("data-id");
      const data = tree.getDataById(id);
      if (data.token) {
        element.style.fontWeight = "bold";
      }

      $(this).mouseover(function (event) {
        const id = $(this).attr("data-id");

        const node = tree.getNodeById(id);
        tree.select(node);
        if (data.token) {
          const target = $(this).find("[data-role='display']");
          if (!target.attr("__tippy")) {
            const kind = `<span class='tooltip-title'>kind:</span><span style='font-family: "Menlo", sans-serif, monospace;'> ${data.token.kind}</span>`;
            const leadingTrivia = `<span class='tooltip-title'>leadingTrivia:</span><span style='font-family: "Menlo", sans-serif, monospace;'> ${data.token.leadingTrivia}</span>`;
            const text = `<span class='tooltip-title'>text:</span><span style='font-family: "Menlo", sans-serif, monospace;'> ${data.text}</span>`;
            const trailingTrivia = `<span class='tooltip-title'>trailingTrivia:</span><span style='font-family: "Menlo", sans-serif, monospace;'> ${data.token.trailingTrivia}</span>`;
            const content = `${kind}<br>${leadingTrivia}<br>${text}<br>${trailingTrivia}`;
            tippy($(this).find("[data-role='display']")[0], {
              content: content,
              allowHTML: true,
              placement: "auto",
              theme: "light-border",
            });
            target.attr("__tippy", true);
          }
        }

        editor.selection.setRange(
          new Range(
            data.range.startRow,
            data.range.startColumn,
            data.range.endRow,
            data.range.endColumn
          )
        );

        event.stopPropagation();
      });

      $(this).mouseout(function (e) {
        tree.unselectAll();
      });
    });
}

function updateSyntaxSourceMap() {
  let visibleTooltips = [];

  $("#results")
    .find("span")
    .each(function (i, e) {
      $(this).mouseover(function (e) {
        let element = e.target;
        element.style.backgroundColor = "rgba(81, 101, 255, 0.5)";

        if (!element.getAttribute("__tippy")) {
          const title = `<span class='tooltip-title'>${element.dataset.tooltipTitle}</span>`;
          const content = `<span style='font-family: "Menlo", sans-serif, monospace;'>${element.dataset.tooltipContent}</span>`;
          tippy(element, {
            content: `${title}: ${content}`,
            allowHTML: true,
            placement: "left",
            theme: "light-border",
            onShow(instance) {
              visibleTooltips.push(instance);
            },
            onHidden(instance) {
              visibleTooltips = visibleTooltips.filter((e) => e !== instance);
            },
          });
          element.setAttribute("__tippy", true);
        }

        $(this)
          .parents("span")
          .each(function (i, e) {
            if (!e.getAttribute("__tippy")) {
              const title = `<span class='tooltip-title'>${e.dataset.tooltipTitle}</span>`;
              const content = `<span style='font-family: "Menlo", sans-serif, monospace;'>${e.dataset.tooltipContent}</span>`;
              const tooltip = tippy(element, {
                content: `${title}: ${content}`,
                allowHTML: true,
                placement: "left",
                theme: "light-border",
                onShow(instance) {
                  visibleTooltips.push(instance);
                  const placements = ["left", "bottom", "right"];
                  visibleTooltips.forEach((tooltip, i) => {
                    tooltip.setProps({
                      placement: placements[i % placements.length],
                      offset: [0 + 20 * ((i / placements.length) ^ 0), 20],
                    });
                  });
                },
                onHidden(instance) {
                  visibleTooltips = visibleTooltips.filter(
                    (e) => e !== instance
                  );
                },
              });
              e.setAttribute("__tippy", true);
              tooltip.show();
            }

            createDOMRectElement(e.getBoundingClientRect());
            if (i > 0) {
              return false;
            }

            function createDOMRectElement(domRect) {
              let rectElements = document.getElementsByClassName("dom-rect");
              for (let i = 0, l = rectElements.length; l > i; i++) {
                rectElements[0].parentNode.removeChild(rectElements[0]);
              }

              let rectElement = document.createElement("div");
              rectElement.className = "dom-rect";
              rectElement.style.left = domRect.x - 1 + "px";
              rectElement.style.top = domRect.y - 1 + "px";
              rectElement.style.width = domRect.width + "px";
              rectElement.style.height = domRect.height + "px";
              rectElement.style.pointerEvents = "none";
              rectElement.style.position = "absolute";
              rectElement.style.border = "1px solid rgb(81, 101, 255)";
              rectElement.style.backgroundColor = "rgba(81, 101, 255, 0.25)";
              document.body.appendChild(rectElement);
            }
          });

        e.stopPropagation();
      });

      $(this).mouseout(function (e) {
        let element = e.target;
        element.style.backgroundColor = "";

        let rectElements = document.getElementsByClassName("dom-rect");
        for (let i = 0, l = rectElements.length; l > i; i++) {
          rectElements[0].parentNode.removeChild(rectElements[0]);
        }
      });
    });
}

function updateStatisticsTable(statistics) {
  $("#statistics > tbody").empty();

  statistics.forEach((row) => {
    const ranges = JSON.stringify(row.ranges);
    $("#statistics > tbody").append(
      `<tr data-ranges='${ranges}'><td style="font-family: 'Menlo', sans-serif, monospace;">${row.syntax}</td><td><div>${row.ranges.length}</div></td></tr>`
    );
  });

  $("#statistics > tbody tr").mouseover(function () {
    const ranges = $(this).data("ranges");
    ranges.forEach((range) => {
      editor.session.addMarker(
        new Range(
          range.startRow,
          range.startColumn,
          range.endRow,
          range.endColumn
        ),
        "editor-marker",
        "text"
      );
    });
  });

  $("#statistics > tbody tr").mouseout(function () {
    const markers = editor.session.getMarkers();
    Object.entries(markers).forEach(([key, value]) => {
      editor.session.removeMarker(value.id);
    });
  });

  $("#statistics").tablesorter({ theme: "bootstrap" });
  $("#statistics").trigger("update");
}

function showLoading() {
  $("#run-button").addClass("disabled");
  $("#run-button-icon").hide();
  $("#run-button-spinner").show();
}

function hideLoading() {
  $("#run-button").removeClass("disabled");
  $("#run-button-icon").show();
  $("#run-button-spinner").hide();
}

function handleFileSelect(event) {
  event.stopPropagation();
  event.preventDefault();

  const files = event.dataTransfer.files;
  const reader = new FileReader();
  reader.onload = (event) => {
    const editor = ace.edit("editor-container");
    editor.setValue(event.target.result);
    editor.clearSelection();
  };
  reader.readAsText(files[0], "UTF-8");
}

function handleDragOver(event) {
  event.stopPropagation();
  event.preventDefault();
  event.dataTransfer.dropEffect = "copy";
}

const dropZone = document.getElementById("editor-container");
dropZone.addEventListener("dragover", handleDragOver, false);
dropZone.addEventListener("drop", handleFileSelect, false);

const formatterService = new SwiftFormat("wss://swift-format.com/api/ws");
formatterService.onresponse = (response) => {
  if (!response) {
    return;
  }
  if (response.output) {
    editor.setValue(response.output);
    editor.clearSelection();
  }
};

[].slice
  .call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  .map((trigger) => {
    return new bootstrap.Tooltip(trigger);
  });

$("#format-button").removeClass("disabled");
$("#format-button").on("click", (e) => {
  e.preventDefault();
  formatterService.format(editor.getValue());
});
