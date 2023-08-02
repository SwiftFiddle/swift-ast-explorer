"use strict";

import { TreeView } from "./tree_view.js";
import { Popover } from "./popover.js";

export class StructureView {
  set error(error) {
    this.container.innerHTML = `<div class="alert alert-danger m-3" role="alert">${error}</div>`;
  }

  constructor(container) {
    this.container = container;
    this.popover = new Popover();

    this.onmouseover = () => {};
    this.onmouseout = () => {};

    this.init();
  }

  init() {
    this.body = this.container.querySelector(":scope > table > tbody");
  }

  update(structureData) {
    this.container.innerHTML = "";
    const treeView = new TreeView(this.container, structureData);

    treeView.onmouseover = (event, target, data) => {
      this.onmouseover(event, target, data);
      if (!data.structure.length && !data.token) {
        return;
      }
      if (data.structure.length > 0) {
        this.popover.setContent(makeSyntaxPopoverContent(data));
      }
      if (data.token) {
        this.popover.setContent(makeTokenPopoverContent(data));
      }
      const tabContainer = document.querySelector(".tab-content");
      const containerRect = tabContainer.getBoundingClientRect();

      this.popover.show(target, {
        containerRect: containerRect,
        offset: { x: -10, y: 1 },
      });
    };

    treeView.onmouseout = (event, target, data) => {
      this.onmouseout(event, target, data);

      if (!event.relatedTarget) {
        return;
      }
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

  makeDescriptionList("kind", data.token.kind, dl);
  makeDescriptionList("leadingTrivia", data.token.leadingTrivia, dl);
  makeDescriptionList("text", data.text, dl);
  makeDescriptionList("trailingTrivia", data.token.trailingTrivia, dl);

  container.appendChild(dl);

  return container.innerHTML;
}

function makeSourceRangePopoverContent(data, list) {
  const range = data.range;
  const details = `${range.startRow}:${range.startColumn} ... ${range.endRow}:${range.endColumn}`;
  makeDescriptionList("Source Range", details, list);
}

function makePropertyPopoverContent(property, list) {
  const details = (() => {
    const value = property.value;
    if (property.ref) {
      return `<span class="badge ref">${property.ref}</span>`;
    } else if (value && value.text && value.kind) {
      const text = value.text;
      const kind = value.kind;
      return `${text}<span class="badge rounded-pill">${kind}</span>`;
    } else if (value && value.text) {
      return value.text;
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
    case "collection": {
      badge.innerText = "SyntaxCollection";
      break;
    }
    default:
      break;
  }
  return badge;
}
