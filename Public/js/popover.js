"use strict";

import "../css/popover.css";

export class Popover {
  set maxWidth(value) {
    this.popover.style.maxWidth = value;
  }

  set content(value) {
    this.popoverContent.innerHTML = value;
  }

  constructor() {
    this.popover = document.createElement("div");
    this.popoverContent = document.createElement("div");

    this.onmouseover = () => {};
    this.onmouseout = () => {};

    this.init();
  }

  init() {
    this.popover.classList.add("popover", "d-none");
    this.popoverContent.classList.add("popover-content");

    this.popover.appendChild(this.popoverContent);
    document.body.appendChild(this.popover);

    this.popover.addEventListener(
      "mouseenter",
      (event) => {
        event.stopPropagation();
        this.onmouseover(event);
      },
      { capture: false, once: false, passive: true }
    );
    this.popover.addEventListener(
      "mouseleave",
      (event) => {
        event.stopPropagation();
        this.onmouseout(event);
      },
      { capture: false, once: false, passive: true }
    );
  }

  show(target, options = {}) {
    const offset = options.offset || { x: 0, y: 0 };
    const containerRect = options.containerRect || {
      left: 0,
      top: 0,
      width: 0,
      height: 0,
    };

    this.popover.classList.remove("d-none");

    const targetRect = target.getBoundingClientRect();
    const popoverRect = {
      left: 0,
      top: 0,
      width: this.popover.clientWidth,
      height: this.popover.clientHeight,
    };

    const left = `${targetRect.left - popoverRect.width + offset.x}px`;
    this.popover.style.left = left;

    const bottom = containerRect.top + containerRect.height;
    const top = targetRect.top - 6 + offset.y;
    if (top + popoverRect.height > bottom) {
      this.popover.style.top = `${bottom - popoverRect.height}px`;
    } else {
      this.popover.style.top = `${top}px`;
    }
  }

  hide() {
    this.popover.classList.add("d-none");
  }
}
