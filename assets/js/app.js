// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { Picker } from "../vendor/emoji-picker-element"

let picker = undefined;
let grid = undefined;
let scrollableContent = undefined;
let targetCellId = undefined;

function showEmojiPicker() {
  picker.classList.remove('h-0');
  picker.classList.add('h-96');
  scrollableContent.style.maxHeight = `calc(100vh - ${picker.offsetHeight}px)`;
}

function hideEmojiPicker() {
  picker.classList.remove('h-96');
  picker.classList.add('h-0');
  scrollableContent.style.maxHeight = '100%';
}

let Hooks = {};

Hooks.EmojiGrid = {
  mounted() {
    grid = this.el;
    scrollableContent = document.getElementById("scrollable-content");
    
    this.el.addEventListener("focusin", e => {
      cellIdStr = e.target.id.match(/emo-(.+)/)[1];
      targetCellId = parseInt(cellIdStr, 16);
      showEmojiPicker();
    });

    this.el.addEventListener("focusout", e => {
      if (!picker.contains(e.relatedTarget)) {
        hideEmojiPicker();
      }
    });

    this.handleEvent("update_emoji", ({ i, emoji }) => {
      console.log({i, emoji})
      const hexI = i.toString(16).toUpperCase();
      const emoId = `emo-${hexI}`;

      const emojiButton = document.getElementById(emoId);
      emojiButton.innerText = emoji;
    });
  }
};

Hooks.EmojiPicker = {
  mounted() {
    picker = this.el;
    hideEmojiPicker();
    picker.addEventListener("emoji-click", e => {
      const newEmoji = e.detail.unicode;
      this.pushEvent("change_emoji", { id: targetCellId, value: newEmoji });
      hideEmojiPicker();
    });
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  // longPollFallbackMs: 5000,
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

