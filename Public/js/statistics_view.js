"use strict";

import DataTable from "datatables.net";
import "datatables.net-bs5/css/dataTables.bootstrap5.min.css";

import "../css/table.css";

export class StatisticsView {
  set error(error) {
    this.container.innerHTML = `<div class="alert alert-danger m-3" role="alert">${error}</div>`;
  }

  constructor(container) {
    this.container = container;

    this.onmouseover = () => {};
    this.onmouseout = () => {};
  }

  update(statistics) {
    this.container.innerHTML = `<table class="table table-borderless table-striped table-hover table-sm">
  <thead class="table-light">
    <tr>
      <th scope="col" style="width: 60%;">Syntax</th>
      <th scope="col">Count</th>
    </tr>
  </thead>
  <tbody>
  </tbody>
</table>
`;

    const body = this.container.querySelector(":scope > table > tbody");
    for (const row of statistics) {
      const tr = document.createElement("tr");
      tr.innerHTML = `<td style="font-family: Menlo, Consolas, 'DejaVu Sans Mono', 'Ubuntu Mono', monospace;">${row.text}</td><td><div>${row.ranges.length}</div></td>`;
      body.appendChild(tr);

      tr.addEventListener(
        "mouseover",
        (event) => {
          event.stopPropagation();
          this.onmouseover(event, tr, row.ranges);
        },
        { capture: false, once: false, passive: true }
      );
      tr.addEventListener(
        "mouseout",
        (event) => {
          event.stopPropagation();
          this.onmouseout(event, tr);
        },
        { capture: false, once: false, passive: true }
      );
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
