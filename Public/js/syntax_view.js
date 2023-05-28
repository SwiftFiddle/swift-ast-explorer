"use strict";

import { Popover } from "./popover.js";
import "../css/syntax.css";

export class SyntaxView {
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
    this.container.innerHTML = syntaxHTML;

    const popover = this.popover;

    const tabContainerRect = document
      .querySelector(".tab-content")
      .getBoundingClientRect();

    $(this.container)
      .find("span")
      .each(function () {
        $(this).mouseover(function (event) {
          event.preventDefault();
          event.stopPropagation();

          const contents = [];

          $(this)
            .parents("span")
            .each(function (index, element) {
              createDOMRectElement(element.getBoundingClientRect());
              contents.push([element.dataset.title, element.dataset.content]);
              if (index > 0) {
                return false;
              }
            });

          let element = event.target;
          element.style.backgroundColor = "rgba(81, 101, 255, 0.5)";

          contents.reverse();
          contents.push([element.dataset.title, element.dataset.content]);

          const dl = `<dl>${contents
            .map((content) => {
              return `<dt>${content[0]}</dt><dd>${content[1]}</dd>`;
            })
            .join("")}</dl>`;
          popover.content = dl;

          popover.show(element, {
            lowerLimit: tabContainerRect.top + tabContainerRect.height,
            offsetX: 40,
          });
        });

        $(this).mouseout(function (event) {
          event.preventDefault();
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
