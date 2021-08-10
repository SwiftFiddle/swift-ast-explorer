"use strict";

export class SwiftFormat {
  constructor(endpoint) {
    this.connection = this.createConnection(endpoint);

    this.onconnect = () => {};
    this.onready = () => {};
    this.onresponse = () => {};
  }

  get isReady() {
    return this.connection.readyState === 1;
  }

  format(code) {
    const encoder = new TextEncoder();
    this.connection.send(encoder.encode(JSON.stringify({ code: code })));
  }

  createConnection(endpoint) {
    if (
      this.connection &&
      (this.connection.readyState === 0 || this.connection.readyState === 1)
    ) {
      return this.connection;
    }

    console.log(`Connecting to ${endpoint}`);
    const connection = new WebSocket(endpoint);
    connection.bufferType = "arraybuffer";

    connection.onopen = () => {
      console.log(`SwiftFormat service connected (${connection.readyState}).`);
      this.onconnect();

      document.addEventListener("visibilitychange", () => {
        switch (document.visibilityState) {
          case "hidden":
            break;
          case "visible":
            this.connection = this.createConnection(connection.url);
            break;
        }
      });
    };

    connection.onclose = (event) => {
      console.log(`SwiftFormat service disconnected (${event.code}).`);
      if (event.code !== 1006) {
        return;
      }
      setTimeout(() => {
        this.connection = this.createConnection(connection.url);
      }, 1000);
    };

    connection.onerror = (event) => {
      console.error(`SwiftFormat service error: ${event}`);
      connection.close();
    };

    connection.onmessage = (event) => {
      this.onresponse(JSON.parse(event.data));
    };
    return connection;
  }
}
