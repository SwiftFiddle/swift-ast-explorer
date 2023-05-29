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
    this.balloon.classList.add("d-none", "balloon-content");
    document.body.appendChild(this.balloon);
  }

  show(position) {
    this.balloon.classList.remove("d-none");
    const bounds = this.balloon.getBoundingClientRect();

    this.balloon.style.top = `${position.top - bounds.height - 4}px`;
    this.balloon.style.left = `${position.left + 10}px`;
  }

  hide() {
    this.balloon.classList.add("d-none");
  }
}
