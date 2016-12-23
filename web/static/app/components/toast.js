import { u } from "umbrellajs";

const duration = 1500;

export default class Toast {
  static text(text) {
    u(".toast").text(text).addClass("toast--show");
    setTimeout(() => {
      u(".toast").removeClass("toast--show");
    }, duration);
  }

  static image(name) {
    u(".toast").text("").addClass(`toast--show toast--${name}`);
    setTimeout(() => {
      u(".toast").removeClass(`toast--show toast--${name}`);
    }, duration);
  }
}
