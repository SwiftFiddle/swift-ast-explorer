"use strict";

import Plausible from "plausible-tracker";

const { enableAutoPageviews } = Plausible({
  domain: "swift-ast-explorer.com",
});
enableAutoPageviews();

import "./scss/default.scss";
import "./css/common.css";

import "./js/icon.js";

import { App } from "./js/app.js";
new App();

document.querySelector("header").classList.remove("invisible");
document.querySelector("main").classList.remove("invisible");
document.querySelector("footer").classList.remove("invisible");
