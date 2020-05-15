// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}});
liveSocket.connect()


const config = { childList: true, subtree: false };

const callback = function(mutationsList) {
  window.mutations = mutationsList;
	for (const mutation of mutationsList) {
    if (mutation.type == "childList") {
      for (const node of mutation.addedNodes) {
        if (node.classList.contains("card")) {
          var audio = new Audio('/audio/card-place.wav');
          audio.play();
        }
      }
    }
	}
};

const observer = new MutationObserver(callback);
["grid-table-left", "grid-table-right", "grid-table-top", "grid-table-bottom"].forEach((element) =>  {
  const targetNode = document.getElementById(element);
  observer.observe(targetNode, config);
});
