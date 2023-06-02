"use strict";

import "../css/tree_view.css";

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
    const content = document.createElement("div");

    if (this.hasChildren(node.id)) {
      content.classList.add("marker");
      content.addEventListener("click", (event) => {
        this.onclick(event, node, li);
      });

      const div = document.createElement("div");
      div.classList.add(`${node.type}-syntax`);
      div.innerHTML = node.text;

      content.appendChild(div);
      li.appendChild(content);

      const children = this.getChildren(node.id);
      for (const child of children) {
        li.classList.add("opened");
        li.appendChild(this.renderNode(child));
      }
    } else {
      content.classList.add("token");
      content.innerHTML =
        node.text.length === 0 ? `<span class="badge">Empty</span>` : node.text;
      li.appendChild(content);
    }

    li.addEventListener(
      "mouseover",
      (event) => {
        event.stopPropagation();
        li.classList.add("hover");
        this.onmouseover(event, content, node);
      },
      { capture: false, once: false, passive: true }
    );
    li.addEventListener(
      "mouseout",
      (event) => {
        event.stopPropagation();
        li.classList.remove("hover");
        this.onmouseout(event, content, node);
      },
      { capture: false, once: false, passive: true }
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

  open(node, li) {
    li.classList.add("opened");
    li.classList.remove("collapsed");

    const children = this.state[node.id];
    if (children) {
      for (const child of children) {
        li.appendChild(child);
      }
    } else {
      const children = this.getChildren(node.id);
      for (const child of children) {
        li.classList.add("opened");
        li.appendChild(this.renderNode(child));
      }
    }
  }

  collapse(node, li) {
    li.classList.add("collapsed");
    li.classList.remove("opened");

    const children = li.querySelectorAll(":scope > ul");
    for (const child of children) {
      li.removeChild(child);
    }

    this.state[node.id] = children;
  }

  onclick(event, node, li) {
    event.preventDefault();
    event.stopPropagation();

    if (li.classList.contains("opened")) {
      this.collapse(node, li);
    } else {
      this.open(node, li);
    }
  }
}
