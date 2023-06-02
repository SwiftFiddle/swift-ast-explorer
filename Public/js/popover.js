"use strict";

import "../css/popover.css";

export class Popover {
  constructor() {
    this.popover = document.createElement("div");
    this.popoverContent = document.createElement("div");
    this.arrow = document.createElement("div");

    this.onmouseover = () => {};
    this.onmouseout = () => {};

    this.init();
  }

  init() {
    this.popover.classList.add("popover", "d-none");
    this.popoverContent.classList.add("popover-content");
    this.arrow.classList.add("arrow");

    this.popover.appendChild(this.popoverContent);
    this.popover.appendChild(this.arrow);
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

  setContent(content) {
    if (this.content === content) {
      return;
    }
    this.content = content;
    this.popoverContent.innerHTML = content;
  }

  show(target, options = {}) {
    const targetRect = options.targetRect || target.getBoundingClientRect();
    const containerRect = options.containerRect || {
      left: 0,
      top: 0,
      width: 0,
      height: 0,
    };
    const offset = options.offset || { x: 0, y: 0 };

    this.popover.classList.remove("d-none");

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
      const popoverTop = bottom - popoverRect.height;
      this.popover.style.top = `${popoverTop}px`;
      this.arrow.style.top = `${targetRect.top - popoverTop + 10 + offset.y}px`;
    } else {
      this.popover.style.top = `${top}px`;
      this.arrow.style.top = "15px";
    }
  }

  hide() {
    this.popover.classList.add("d-none");
  }
}
