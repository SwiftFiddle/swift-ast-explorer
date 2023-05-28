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
        this.popover.content = makeSyntaxPopoverContent(data);
      }
      if (data.token) {
        this.popover.content = makeTokenPopoverContent(data);
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

function makeSyntaxPopoverContent(data) {
  const container = document.createElement("div");

  const title = document.createElement("div");
  title.classList.add("title");
  title.innerText = `${data.text}Syntax`;
  title.appendChild(makeSyntaxTypeBadge(data.type));

  container.appendChild(title);

  const dl = document.createElement("dl");

  makeSourceRangePopoverContent(data, dl);

  for (const property of data.structure) {
    makePropertyPopoverContent(property, dl);
  }
  container.appendChild(dl);

  return container.innerHTML;
}

function makeTokenPopoverContent(data) {
  const container = document.createElement("div");

  const title = document.createElement("div");
  title.classList.add("title");
  title.innerText = "TokenSyntax";

  container.appendChild(title);

  const dl = document.createElement("dl");

  makeSourceRangePopoverContent(data, dl);

  makeDescriptionList("kind", stripHTMLTag(data.token.kind), dl);
  makeDescriptionList(
    "leadingTrivia",
    stripHTMLTag(data.token.leadingTrivia),
    dl
  );
  makeDescriptionList("text", stripHTMLTag(data.text), dl);
  makeDescriptionList(
    "trailingTrivia",
    stripHTMLTag(data.token.trailingTrivia),
    dl
  );

  container.appendChild(dl);

  return container.innerHTML;
}

function makeSourceRangePopoverContent(data, list) {
  const range = data.range;
  // prettier-ignore
  const details = `Ln ${range.startRow + 1}, Col ${range.startColumn + 1} - Ln ${range.endRow + 1}, Col ${range.endColumn + 1}`;
  makeDescriptionList("Source Range", details, list);
}

function makePropertyPopoverContent(property, list) {
  const details = (() => {
    const value = property.value;
    if (value && value.text && value.kind) {
      const text = stripHTMLTag(value.text);
      const kind = stripHTMLTag(value.kind);
      return `${text}<span class="badge rounded-pill">${kind}</span>`;
    } else if (value && value.text) {
      return stripHTMLTag(value.text);
    }
  })();
  makeDescriptionList(property.name, details, list);
}

function makeDescriptionList(term, details, list) {
  const dt = document.createElement("dt");
  dt.innerHTML = term;

  const dd = document.createElement("dd");
  dd.innerHTML = details;

  list.appendChild(dt);
  list.appendChild(dd);
}

function makeSyntaxTypeBadge(type) {
  const badge = document.createElement("span");
  badge.classList.add("badge", "text-bg-light");
  switch (type) {
    case "decl": {
      badge.innerText = "DeclSyntax";
      break;
    }
    case "expr": {
      badge.innerText = "ExprSyntax";
      break;
    }
    case "pattern": {
      badge.innerText = "PatternSyntax";
      break;
    }
    case "type": {
      badge.innerText = "TypeSyntax";
      break;
    }
    default:
      break;
  }
  return badge;
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
