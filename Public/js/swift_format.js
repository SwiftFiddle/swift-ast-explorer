"use strict";

export class SwiftFormat {
  constructor(endpoint) {
    this.connection = this.createConnection(endpoint);

    this.onconnect = () => {};
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

    const connection = new ReconnectingWebSocket(endpoint, [], {
      maxReconnectionDelay: 10000,
      minReconnectionDelay: 1000,
      reconnectionDelayGrowFactor: 1.3,
      connectionTimeout: 10000,
      maxRetries: Infinity,
      debug: false,
    });
    connection.bufferType = "arraybuffer";

    connection.onopen = () => {
      this.onconnect();
    };

    connection.onerror = (event) => {
      connection.close();
    };

    connection.onmessage = (event) => {
      this.onresponse(JSON.parse(event.data));
    };

    return connection;
  }
}
