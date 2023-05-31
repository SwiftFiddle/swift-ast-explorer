"use strict";

import "../css/balloon.css";

export class Balloon {
  set content(value) {
    this.balloon.innerHTML = value;
  }

  constructor() {
    this.balloon = document.createElement("div");
    this.init();
  }

  init() {
    this.balloon.classList.add("d-none", "balloon");
    document.body.appendChild(this.balloon);
  }

  show(rect, options = {}) {
    let placement = options.placement || "top";
    const containerRect = options.containerRect || {
      left: 0,
      top: 0,
      width: 0,
      height: 0,
    };

    this.balloon.classList.remove("d-none");

    const width = this.balloon.clientWidth;
    const height = this.balloon.clientHeight;

    const top = containerRect.top;
    const bottom = containerRect.top + containerRect.height;

    let fallbackOcurred = 1;
    switch (placement) {
      case "top":
        if (rect.top - height < top) {
          placement = "bottom";
          fallbackOcurred = -1;
        }
        break;
      case "bottom":
        if (rect.top + height > bottom) {
          placement = "top";
          fallbackOcurred = -1;
        }
        break;
      case "left":
        if (rect.left - width < containerRect.left) {
          placement = "right";
          fallbackOcurred = -1;
        }
        break;
      case "right":
        if (rect.left + width > containerRect.left + containerRect.width) {
          placement = "left";
          fallbackOcurred = -1;
        }
        break;
      default:
        break;
    }

    this.balloon.classList.remove("top", "bottom", "left", "right");
    this.balloon.classList.add(placement);

    const offset = (() => {
      const offset = options.offset || { x: 0, y: 0 };
      switch (placement) {
        case "top":
          return { x: offset.x, y: offset.y * fallbackOcurred - height };
        case "bottom":
          return { x: offset.x, y: offset.y * fallbackOcurred + rect.height };
        case "left":
          return { x: offset.x * fallbackOcurred - width, y: offset.y };
        case "right":
          return { x: offset.x * fallbackOcurred + rect.width, y: offset.y };
        default:
          return { x: offset.x, y: offset.y };
      }
    })();

    this.balloon.style.left = `${rect.left + offset.x}px`;
    this.balloon.style.top = `${rect.top + offset.y}px`;
  }

  hide() {
    this.balloon.classList.add("d-none");
  }
}
