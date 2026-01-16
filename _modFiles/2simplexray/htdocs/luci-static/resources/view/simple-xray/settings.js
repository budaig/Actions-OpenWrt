"use strict";
"require view";
"require form";
"require poll"; // Allows periodic polling.
"require rpc"; // Facilitates communication with backend services.
"require uci"; // Manages the configuration system.
"require fs"; // module to handle file reading/writing
"require ui";

// An RPC method is declared that calls the backend's service.list method.
// It expects to pass a parameter called 'name' and will return a result (structured as an object).
var callServiceList = rpc.declare({
  object: "service",
  method: "list",
  params: ["name"],
  expect: { "": {} },
});

function getServiceStatus() {
  return L.resolveDefault(callServiceList("simple-xray"), {}).then(function (res) {
    var isRunning = false;
    try {
      isRunning = res["simple-xray"]["instances"]["simple-xray"]["running"];
    } catch (e) {}
    return isRunning;
  });
}

function renderStatus(isRunning) {
  var spanTemp = '<span style="color:%s"><strong>%s %s</strong></span>';
  var renderHTML;
  if (isRunning) {
    renderHTML = spanTemp.format("green", _("xray"), _("RUNNING"));
  } else {
    renderHTML = spanTemp.format("red", _("xray"), _("NOT RUNNING"));
  }
  return renderHTML;
}

return view.extend({
  load: function () {
    return Promise.all([uci.load("simple-xray")]);
  },

  render: function () {
    let m, s, o;

    m = new form.Map("simple-xray", _("simple-xray"), _("A simple luci interface for xray."));

    s = m.section(form.TypedSection);
    s.anonymous = true;
    s.render = function () {
      poll.add(function () {
        return L.resolveDefault(getServiceStatus()).then(function (res) {
          var view = document.getElementById("service_status");
          view.innerHTML = renderStatus(res);
        });
      });

      return E("div", { class: "cbi-section", id: "status_bar" }, [
        E("p", { id: "service_status" }, _("Collecting data…")),
      ]);
    };

    s = m.section(form.NamedSection, "config", _("Basic Setting"));

    o = s.option(form.Flag, "enabled", _("Enabled"));
    o = s.option(form.Value, "config_file", _("Configuration File"));
    o.readonly = true;
    o.default = "/etc/simplexray/config.json";
    o.rmempty = false;

    return m.render();
  },
});
