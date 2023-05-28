"use strict";

import { TreeView } from "./tree_view.js";
import { Popover } from "./popover.js";

export class StructureView {
  constructor(container) {
    this.container = container;
    this.popover = new Popover();

    this.onmouseover = () => {};

    this.init();
  }

  init() {
    this.body = this.container.querySelector(":scope > table > tbody");
  }

  update(structureData) {
    this.container.innerHTML = "";
    this.treeView = new TreeView(this.container, structureData);

    this.treeView.onmouseover = (event, target, data) => {
      this.onmouseover(event, target, data);

      if (!data.structure.length && !data.token) {
        return;
      }
      if (data.structure.length > 0) {
        const container = document.createElement("div");

        const title = document.createElement("div");
        title.classList.add("title");
        title.innerText = `${data.text}Syntax`;
        container.appendChild(title);

        switch (data.type) {
          case "decl": {
            const label = document.createElement("span");
            label.classList.add("badge", "text-bg-light");
            label.innerText = "DeclSyntax";
            title.appendChild(label);
            break;
          }
          case "expr": {
            const label = document.createElement("span");
            label.classList.add("badge", "text-bg-light");
            label.innerText = "ExprSyntax";
            title.appendChild(label);
            break;
          }
          case "pattern": {
            const label = document.createElement("span");
            label.classList.add("badge", "text-bg-light");
            label.innerText = "PatternSyntax";
            title.appendChild(label);
            break;
          }
          case "type": {
            const label = document.createElement("span");
            label.classList.add("badge", "text-bg-light");
            label.innerText = "TypeSyntax";
            title.appendChild(label);
            break;
          }
          default:
            break;
        }

        const dl = document.createElement("dl");

        const dt = document.createElement("dt");
        const dd = document.createElement("dd");

        dt.innerHTML = "Source Range";
        const range = data.range;
        // prettier-ignore
        dd.innerHTML = `Ln ${range.startRow + 1}, Col ${range.startColumn + 1} - Ln ${range.endRow + 1}, Col ${range.endColumn + 1}`;

        dl.appendChild(dt);
        dl.appendChild(dd);

        for (const property of data.structure) {
          const dt = document.createElement("dt");
          const dd = document.createElement("dd");

          const name = property.name;
          const value = property.value;
          if (value && value.text && value.kind) {
            const text = stripHTMLTag(value.text);
            const kind = stripHTMLTag(value.kind);
            dt.innerHTML = `${name}`;
            dd.innerHTML = `${text}<span class="badge rounded-pill">${kind}</span>`;
          } else if (value && value.text) {
            const text = stripHTMLTag(value.text);
            dt.innerHTML = `${name}`;
            dd.innerHTML = `${text}`;
          }
          dl.appendChild(dt);
          dl.appendChild(dd);
        }
        container.appendChild(dl);

        this.popover.content = container.innerHTML;
      }
      if (data.token) {
        const container = document.createElement("div");

        const title = document.createElement("div");
        title.classList.add("title");
        title.innerText = "TokenSyntax";
        container.appendChild(title);

        const dl = document.createElement("dl");

        {
          const dt = document.createElement("dt");
          const dd = document.createElement("dd");

          dt.innerHTML = "Source Range";
          const range = data.range;
          // prettier-ignore
          dd.innerHTML = `Ln ${range.startRow + 1}, Col ${range.startColumn + 1} - Ln ${range.endRow + 1}, Col ${range.endColumn + 1}`;

          dl.appendChild(dt);
          dl.appendChild(dd);
        }

        {
          const dt = document.createElement("dt");
          dt.innerHTML = "kind";
          dl.appendChild(dt);

          const dd = document.createElement("dd");
          dd.innerHTML = stripHTMLTag(data.token.kind);
          dl.appendChild(dd);
        }
        {
          const dt = document.createElement("dt");
          dt.innerHTML = "leadingTrivia";
          dl.appendChild(dt);

          const dd = document.createElement("dd");
          dd.innerHTML = stripHTMLTag(data.token.leadingTrivia);
          dl.appendChild(dd);
        }
        {
          const dt = document.createElement("dt");
          dt.innerHTML = "text";
          dl.appendChild(dt);

          const dd = document.createElement("dd");
          dd.innerHTML = stripHTMLTag(data.text);
          dl.appendChild(dd);
        }
        {
          const dt = document.createElement("dt");
          dt.innerHTML = "trailingTrivia";
          dl.appendChild(dt);

          const dd = document.createElement("dd");
          dd.innerHTML = stripHTMLTag(data.token.trailingTrivia);

          dl.appendChild(dd);
        }
        container.appendChild(dl);

        this.popover.content = container.innerHTML;
      }

      const tabContainerRect = document
        .querySelector(".tab-content")
        .getBoundingClientRect();

      const parent = target.parentElement;
      const caret = parent.querySelector(":scope > div > .caret");
      this.popover.show(caret || target, {
        lowerLimit: tabContainerRect.top + tabContainerRect.height,
        offsetX: caret ? 0 : 24,
      });
    };

    this.treeView.onmouseout = (event, target, data) => {
      if (!event.relatedTarget.classList.contains("popover-content")) {
        this.popover.hide();
      }
    };

    this.popover.onmouseout = (event) => {
      this.popover.hide();
    };
  }
}

function stripHTMLTag(text) {
  const div = document.createElement("div");
  div.innerHTML = text
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#039;/g, "'")
    .replace(/&amp;/g, "&");
  return escapeHTML(div.textContent || div.innerText || "");
}

function escapeHTML(text) {
  const div = document.createElement("div");
  div.appendChild(document.createTextNode(text));
  return div.innerHTML;
}
