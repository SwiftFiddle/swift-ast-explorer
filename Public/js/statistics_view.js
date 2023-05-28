"use strict";

import DataTable from "datatables.net";
import "datatables.net-bs5/css/dataTables.bootstrap5.min.css";

import "../css/table.css";

export class StatisticsView {
  constructor(container) {
    this.container = container;

    this.onmouseover = () => {};
    this.onmouseout = () => {};

    this.init();
  }

  init() {
    this.body = this.container.querySelector(":scope > table > tbody");
  }

  update(statistics) {
    this.body.innerHTML = "";

    for (const row of statistics) {
      const tr = document.createElement("tr");
      tr.innerHTML = `<td style="font-family: Menlo, Consolas, 'DejaVu Sans Mono', 'Ubuntu Mono', monospace;">${row.text}</td><td><div>${row.ranges.length}</div></td>`;
      this.body.appendChild(tr);

      tr.addEventListener("mouseover", (event) => {
        event.preventDefault();
        event.stopPropagation();

        this.onmouseover(event, tr, row.ranges);
      });
      tr.addEventListener("mouseout", (event) => {
        event.preventDefault();
        event.stopPropagation();

        this.onmouseout(event, tr);
      });
    }

    if (this.dataTable) {
      this.dataTable.destroy();
    }
    this.dataTable = new DataTable(
      this.container.querySelector(":scope > table"),
      {
        autoWidth: false,
        info: false,
        paging: false,
        searching: false,
      }
    );
  }
}
