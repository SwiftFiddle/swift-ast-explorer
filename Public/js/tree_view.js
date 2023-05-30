"use strict";

import "../css/tree_view.css";

export class TreeView {
  constructor(container, tree) {
    this.container = container;
    this.tree = tree;

    this.scrollable = document.createElement("div");
    this.treeView = document.createElement("div");

    this.state = {};

    this.onmouseover = () => {};
    this.onmouseout = () => {};

    requestAnimationFrame(() => {
      this.init();
    });
  }

  init() {
    this.treeView.classList.add("tree-view");
    this.scrollable.classList.add("scrollable");

    this.computeDimensions();

    const fragment = document.createDocumentFragment();
    this.renderTree(fragment, this.tree);
    this.treeView.appendChild(fragment);

    this.scrollable.appendChild(this.treeView);
    this.container.appendChild(this.scrollable);

    let ticking = false;
    this.scrollable.addEventListener(
      "scroll",
      (event) => {
        event.stopPropagation();
        if (!ticking) {
          requestAnimationFrame(() => {
            this.onscroll();
            ticking = false;
          });
          ticking = true;
        }
      },
      { capture: false, once: false, passive: true }
    );
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

    const content = document.createElement("div");
    content.style.height = `${this.rowHeight}px`;

    if (this.hasChildren(node.id)) {
      // content.appendChild(makeMarker());

      content.addEventListener("click", (event) => {
        this.onclick(event, node, li);
      });

      const div = document.createElement("div");
      div.classList.add(`${node.type}-syntax`);
      div.innerHTML = node.text;

      // content.appendChild(div);
      li.appendChild(content);

      const children = this.getChildren(node.id);
      for (const child of children) {
        li.classList.add("opened");
        li.appendChild(this.renderNode(child));
      }
    } else {
      content.classList.add("token");
      // content.innerHTML =
      //   node.text.length === 0 ? `<span class="badge">Empty</span>` : node.text;
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

    const div = li.querySelector(":scope > div");
    div.removeChild(div.querySelector(".marker"));
    div.insertBefore(makeMarker(), div.firstChild);

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

    const div = li.querySelector(":scope > div");
    div.removeChild(div.querySelector(".marker"));
    div.insertBefore(makeMarker(), div.firstChild);

    const children = li.querySelectorAll(":scope > ul");
    for (const child of children) {
      li.removeChild(child);
    }

    this.state[node.id] = children;
  }

  computeDimensions() {
    this.viewportHeight = this.container.getBoundingClientRect().height;

    this.treeView.innerHTML = `<ul><li class="entry"><div class="token">SourceFile</div></li></ul>`;
    this.treeView.style.visibility = "hidden";
    document.body.appendChild(this.treeView);

    this.rowHeight = this.treeView
      .querySelector(":scope > ul > li")
      .getBoundingClientRect().height;

    this.treeView.innerHTML = "";
    document.body.removeChild(this.treeView);
    this.treeView.style.visibility = "visible";
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

  onscroll() {}
}

function makeMarker() {
  const marker = document.createElement("span");
  marker.classList.add("marker");
  return marker;
}
