"use strict";

import "../css/trivia.css";
import { Popover } from "./popover.js";

export class TriviaView {
  set error(error) {
    this.container.innerHTML = `<div class="alert alert-danger m-3" role="alert">${error}</div>`;
  }

  constructor(container) {
    this.container = container;
    this.popover = new Popover();
  }

  update(syntaxHTML) {
    this.container.innerHTML = "";

    const contentView = document.createElement("div");
    contentView.innerHTML = syntaxHTML;

    this.container.appendChild(contentView);

    this.container.querySelectorAll(".token").forEach((token) => {
      token.addEventListener("mouseover", (event) => {
        event.stopPropagation();

        this.createDOMRectElement(token.getBoundingClientRect());

        const parent = token.parentElement;
        let isLeadingTrivia = true;

        const leadingTrivias = [];
        const trailingTrivias = [];

        for (const child of Array.from(parent.childNodes)) {
          if (child === token) {
            isLeadingTrivia = false;
            continue;
          }

          if (child.nodeType === Node.TEXT_NODE) {
            const span = document.createElement("span");
            span.textContent = child.textContent;
            parent.replaceChild(span, child);

            if (isLeadingTrivia) {
              span.classList.add("leading-trivia");
              leadingTrivias.push(
                span.textContent
                  .replace(/\s/g, `<span style="color: #a3a3a3;">␣`)
                  .replace(/\n/g, `<span style="color: #a3a3a3;">↲`)
              );
            } else {
              span.classList.add("trailing-trivia");
              trailingTrivias.push(
                span.textContent
                  .replace(/\s/g, `<span style="color: #a3a3a3;">␣`)
                  .replace(/\n/g, `<span style="color: #a3a3a3;">↲`)
              );
            }
          } else if (child.nodeType === Node.ELEMENT_NODE) {
            if (isLeadingTrivia) {
              child.classList.add("leading-trivia");
              if (child.tagName === "BR") {
                leadingTrivias.push(`<span style="color: #a3a3a3;">↲</span>`);
              } else {
                leadingTrivias.push(
                  child.textContent
                    .replace(/\s/g, `<span style="color: #a3a3a3;">␣</span>`)
                    .replace(/\n/g, `<span style="color: #a3a3a3;">↲</span>`)
                );
              }
            } else {
              child.classList.add("trailing-trivia");
              if (child.tagName === "BR") {
                trailingTrivias.push(`<span style="color: #a3a3a3;">↲</span>`);
              } else {
                trailingTrivias.push(
                  child.textContent
                    .replace(/\s/g, `<span style="color: #a3a3a3;">␣</span>`)
                    .replace(/\n/g, `<span style="color: #a3a3a3;">↲</span>`)
                );
              }
            }
          }
        }

        const tabContainer = document.querySelector(".tab-content");

        const containerRect = tabContainer.getBoundingClientRect();
        const elementRect = token.getBoundingClientRect();
        const offset = {
          x: containerRect.left - elementRect.left - 16,
          y: -2,
        };

        const leadingTrivia = leadingTrivias.join("");
        const trailingTrivia = trailingTrivias.join("");
        this.popover.setContent(
          `<dl>
  <dt class="text-truncate" style="max-width: calc(40vw - 20px);"><span class="font-monospace">${token.dataset.title}</span></dt>
  <dt class="text-truncate" style="max-width: calc(40vw - 20px);"><span class="font-monospace">${token.dataset.content}</span></dt>
  <dt class="text-truncate" style="max-width: calc(40vw - 20px); margin-top: 8px;"><span class="badge annotation text-body" style="width: auto; text-align: start;"><svg width="12" height="10" xmlns="http://www.w3.org/2000/svg"><circle stroke="#c8e1c8" fill="#c8e1c8" cx="4" cy="4" r="3.5" fill-rule="evenodd"/></svg>Leading Trivia</span><div style="padding-left: 12px;"><span class="font-monospace">${leadingTrivia}</span></div></dt>
  <dt class="text-truncate" style="max-width: calc(40vw - 20px); margin-top: 8px;"><span class="badge annotation text-body" style="width: auto; text-align: start;"><svg width="12" height="10" xmlns="http://www.w3.org/2000/svg"><circle stroke="#ffd8a8" fill="#ffd8a8" cx="4" cy="4" r="3.5" fill-rule="evenodd"/></svg>Trailing Trivia</span><div style="padding-left: 12px;"><span class="font-monospace">${trailingTrivia}</span></div></dt>
  <dt class="text-truncate" style="max-width: calc(40vw - 20px); margin-top: 8px;"><span class="badge annotation" style="width: auto; text-align: start;"><span class="fa-regular fa-circle-info"></span><span class="mx-1">Trivia Attribution Rule</span></dt>
  <dt style="max-width: calc(40vw - 20px);"><ol style="font-weight: normal; margin-bottom: 4px;"><li>A token owns all of its trailing trivia up to, but not including, the next newline character.</li><li>Looking backward in the text, a token owns all of the leading trivia up to and including the first contiguous sequence of newlines characters.</li></ol></dt>
</dl>`
        );
        this.popover.show(token, {
          containerRect: containerRect,
          offset: offset,
        });
      });

      token.addEventListener("mouseout", (event) => {
        event.stopPropagation();

        this.removeDOMRectElement();

        const parent = token.parentElement;
        for (const child of Array.from(parent.childNodes)) {
          if (child.nodeType === Node.ELEMENT_NODE) {
            child.classList.remove("leading-trivia");
            child.classList.remove("trailing-trivia");
          }
        }

        this.popover.hide();
      });
    });
  }

  createDOMRectElement(domRect) {
    const className = "dom-rect";
    let rectElements = this.container.getElementsByClassName(className);
    for (let i = 0, l = rectElements.length; l > i; i++) {
      rectElements[0].parentNode.removeChild(rectElements[0]);
    }

    let rectElement = document.createElement("div");
    rectElement.className = className;
    rectElement.style.left = domRect.x + "px";
    rectElement.style.top = domRect.y + "px";
    rectElement.style.width = domRect.width + "px";
    rectElement.style.height = domRect.height + "px";
    rectElement.style.pointerEvents = "none";
    rectElement.style.position = "absolute";
    rectElement.style.border = "1px solid rgb(100, 149, 237)";
    this.container.appendChild(rectElement);
  }

  removeDOMRectElement() {
    let rectElements = this.container.getElementsByClassName("dom-rect");
    for (let i = 0, l = rectElements.length; l > i; i++) {
      rectElements[0].parentNode.removeChild(rectElements[0]);
    }
  }
}
