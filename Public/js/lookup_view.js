"use strict";

import "../css/lookup.css";
import { Popover } from "./popover.js";

export class LookupView {
  set error(error) {
    this.container.innerHTML = `<div class="alert alert-danger m-3" role="alert">${error}</div>`;
  }

  constructor(container) {
    this.container = container;
    this.popover = new Popover();

    this.onmouseover = () => {};
    this.onmouseout = () => {};
  }

  update(syntaxHTML) {
    this.container.innerHTML = "";

    const contentView = document.createElement("div");
    contentView.innerHTML = syntaxHTML;

    this.container.appendChild(contentView);

    const popover = this.popover;

    $(this.container)
      .find("span")
      .each(function () {
        $(this).mouseover(function (event) {
          event.stopPropagation();

          const contents = [];

          $(this)
            .parents("span")
            .each(function (index, element) {
              createDOMRectElement(element.getBoundingClientRect());
              contents.push({
                title: element.dataset.title,
                content: element.dataset.content,
                type: element.dataset.type,
                range: element.dataset.range,
              });
              if (index > 0) {
                return false;
              }
            });

          let element = event.target;
          element.style.backgroundColor = "rgba(81, 101, 255, 0.5)";

          contents.reverse();
          contents.push({
            title: element.dataset.title,
            content: element.dataset.content,
            type: element.dataset.type,
            range: element.dataset.range,
          });

          const list = contents
            .filter(
              (item, index, self) =>
                index ===
                self.findIndex(
                  (t) =>
                    t.title === item.title &&
                    t.content === item.content &&
                    t.range === item.range
                )
            )
            .map((item) => {
              const title = escapeHTML(item.title);
              const type = escapeHTML(item.type);
              const content = escapeHTML(item.content);
              if (item.range) {
                const range = JSON.parse(item.range);
                const sourceRange = `${range.startRow}:${range.startColumn} - ${range.endRow}:${range.endColumn}`;
                return `<dt class="text-truncate" style="max-width: calc(40vw - 20px);">
  <span class="badge annotation" style="width: auto; text-align: start;">Text</span><span class="font-monospace">${title}</span>
</dt>
<dd><div><span class="badge annotation">Range</span>${sourceRange}</div><div><span class="badge annotation">${type}</span>${content}</div></dd>`;
              } else {
                return `<dt class="text-truncate" style="max-width: calc(40vw - 20px);">
  <span class="badge annotation" style="width: auto; text-align: start;">Text</span><span class="font-monospace">${title}</span>
</dt>
<dd><div><span class="badge annotation">${type}</span>${content}</div></dd>`;
              }
            })
            .join("");
          const dl = `<dl>${list}</dl>`;
          popover.setContent(dl);

          const tabContainer = document.querySelector(".tab-content");
          const containerRect = tabContainer.getBoundingClientRect();

          popover.show(element, {
            containerRect: containerRect,
            offset: { x: -16, y: -2 },
          });
        });

        $(this).mouseout(function (event) {
          event.stopPropagation();

          let element = event.target;
          element.style.backgroundColor = "";

          let rectElements = document.getElementsByClassName("dom-rect");
          for (let i = 0, l = rectElements.length; l > i; i++) {
            rectElements[0].parentNode.removeChild(rectElements[0]);
          }

          popover.hide();
        });
      });
  }
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

function escapeHTML(text) {
  const div = document.createElement("div");
  div.appendChild(document.createTextNode(text));
  return div.innerHTML;
}
