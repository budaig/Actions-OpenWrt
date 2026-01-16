"use strict";
"require view";
"require fs";
"require ui";

// Function to reload log via RPC
function reloadLog() {
  fs.read_direct("/var/log/simplexray.log")
    .catch(function (e) {
      if (e.toString().includes("NotFoundError")) {
        return _("Log file not found.");
      }
      document.getElementById("log_viewer").value = _("Unknown error: %s").format(e);
    })
    .then(function (log) {
      document.getElementById("log_viewer").value = log;
    });
}

function clearLog() {
  fs.exec("/bin/sh", ["/usr/share/simple-xray/clear_log.sh"])
    .catch(function (e) {
      ui.addNotification(null, E("p", [e]));
    })
    .then(function () {
      reloadLog();
    });
}

return view.extend({
  render: function () {
    var container = E("div", { class: "cbi-section" }, [
      E("div", [
        E(
          "button",
          {
            style: "margin-top: 1em; margin-bottom: 1em;",
            class: "cbi-button",
            click: clearLog,
          },
          _("Clear Log")
        ),
      ]),
      E(
        "textarea",
        {
          id: "log_viewer",
          class: "cbi-input-textarea",
          readonly: true,
          style: "width: 100%; height: 1000px;",
        },
        ""
      ),
    ]);

    // Initial load and set refresh interval
    reloadLog();
    setInterval(reloadLog, 2000);

    return container;
  },

  handleSaveApply: null,
  handleSave: null,
  handleReset: null,
});
