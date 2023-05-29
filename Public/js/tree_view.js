"use strict";

import "../css/tree_view.css";
import { throttle } from "./throttle.js";

const downCaret = makeDownCaret();
const rightCaret = makeRightCaret();

export class TreeView {
  constructor(container, tree) {
    this.container = container;
    this.tree = tree;

    this.treeView = document.createElement("div");
    this.state = {};

    this.onmouseover = () => {};
    this.onmouseout = () => {};

    this.init();
  }

  init() {
    this.treeView.classList.add("tree-view");

    const fragment = document.createDocumentFragment();
    this.renderTree(fragment, this.tree);
    this.treeView.appendChild(fragment);

    this.container.appendChild(this.treeView);
  }

  renderTree(container, tree) {
    tree
      .filter(function (node) {
        return node.parent === undefined;
      })
      .forEach((node) => {
        container.appendChild(this.renderNode(node));
      });
  }

  renderNode(node) {
    const ul = document.createElement("ul");

    const li = document.createElement("li");
    li.classList.add("entry");

    const element = document.createElement("div");

    if (this.hasChildren(node.id)) {
      const caret = downCaret.cloneNode(true);
      element.appendChild(caret);

      const div = document.createElement("div");
      div.classList = `${node.type}-syntax`;
      div.innerHTML = node.text;
      element.appendChild(div);
      li.appendChild(element);

      const children = this.getChildren(node.id);
      for (const child of children) {
        li.appendChild(this.renderNode(child));
      }

      element.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();

        if (element.classList.contains("collapsed")) {
          this.expand(node, element, li);
        } else {
          this.collapse(node, element, li);
        }
      });
    } else {
      element.classList.add("token");
      if (node.text.length === 0) {
        element.innerHTML = `<span class="badge">Empty</span>`;
      } else {
        element.innerHTML = node.text;
      }
      li.appendChild(element);
    }

    const onmouseover = throttle((event, element, data) => {
      this.onmouseover(event, element, data);
    });
    const onmouseout = throttle((event, element, data) => {
      this.onmouseout(event, element, data);
    });

    li.addEventListener(
      "mouseover",
      (event) => {
        event.stopPropagation();

        li.classList.add("hover");
        onmouseover(event, element, node);
      },
      { capture: false, once: false, passive: false }
    );
    li.addEventListener(
      "mouseout",
      (event) => {
        event.stopPropagation();

        li.classList.remove("hover");
        onmouseout(event, element, node);
      },
      { capture: false, once: false, passive: false }
    );

    ul.appendChild(li);
    return ul;
  }

  hasChildren(id) {
    return this.tree.some(function (node) {
      return node.parent === id;
    });
  }

  getChildren(id) {
    return this.tree.filter(function (node) {
      return node.parent === id;
    });
  }

  collapse(node, container, containerParent) {
    container.classList.add("collapsed");

    container.removeChild(container.querySelector(".caret"));
    container.insertBefore(rightCaret.cloneNode(true), container.firstChild);

    const children = containerParent.querySelectorAll(":scope > ul");
    for (const child of children) {
      containerParent.removeChild(child);
    }

    this.state[node.id] = children;
  }

  expand(node, container, containerParent) {
    container.classList.remove("collapsed");

    container.removeChild(container.querySelector(".caret"));
    container.insertBefore(downCaret.cloneNode(true), container.firstChild);

    const children = this.state[node.id];
    if (children) {
      for (const child of children) {
        containerParent.appendChild(child);
      }
    } else {
      containerParent.appendChild(this.renderNode(node));
    }
  }
}

function makeDownCaret() {
  const caret = document.createElement("span");
  caret.classList.add(
    "caret",
    "fa-solid",
    "fa-caret-down",
    "fa-xs",
    "fa-fw",
    "p-1"
  );
  return caret;
}

function makeRightCaret() {
  const caret = document.createElement("span");
  caret.classList.add(
    "caret",
    "fa-solid",
    "fa-caret-right",
    "fa-xs",
    "fa-fw",
    "p-1"
  );
  return caret;
}
