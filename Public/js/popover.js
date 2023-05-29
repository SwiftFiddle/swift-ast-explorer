"use strict";

import "../css/popover.css";
import { throttle } from "./throttle.js";

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

    const onmouseover = throttle((event) => {
      this.onmouseover(event);
    });
    const onmouseout = throttle((event) => {
      this.onmouseout(event);
    });

    this.popover.addEventListener(
      "mouseenter",
      (event) => {
        event.stopPropagation();
        onmouseover(event);
      },
      { capture: false, once: false, passive: false }
    );
    this.popover.addEventListener(
      "mouseleave",
      (event) => {
        event.stopPropagation();
        onmouseout(event);
      },
      { capture: false, once: false, passive: false }
    );
  }

  show(target, options = {}) {
    const lowerLimit = options.lowerLimit;
    const offsetX = options.offsetX || 0;

    this.popover.classList.remove("d-none");

    const targetRect = target.getBoundingClientRect();
    const popoverRect = this.popover.getBoundingClientRect();

    const top = targetRect.top - 6;
    if (top + popoverRect.height > lowerLimit) {
      this.popover.style.top = `${lowerLimit - popoverRect.height}px`;
    } else {
      this.popover.style.top = `${top}px`;
    }

    const left = `${targetRect.left - popoverRect.width - offsetX}px`;
    this.popover.style.left = left;
  }

  hide() {
    this.popover.classList.add("d-none");
  }
}
