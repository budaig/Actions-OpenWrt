"use strict";
"require view";
"require form";
"require uci"; // Manages the configuration system.
"require fs"; // module to handle file reading/writing
"require ui";

return view.extend({
  render: function () {
    let m, s, o;

    m = new form.Map("simple-xray", _("Config"), _("Xray configuration."));

    s = m.section(form.TypedSection);
    s.anonymous = true;

    o = s.option(form.TextValue, "configuration");
    o.rows = 50;
    o.load = function (section) {
      // Use current UCI value for file path, default if not set
      let filePath = uci.get("simple-xray", "config", "config_file") || "/etc/simplexray/config.json";
      return fs.read_direct(filePath).catch(function (e) {
        if (e.toString().includes("NotFoundError")) {
          return fs
            .read_direct("/etc/simplexray/config.json.example", "text")
            .then(function (content) {
              return content ?? "";
            })
            .catch(function (e) {
              return "";
            });
        }
        ui.addNotification(null, E("p", e.message));
        return "";
      });
    };
    o.write = function (section, value) {
      // At the time of writing, we want to ensure the UCI field was already updated.
      // One approach: commit UCI changes first, then use the new file path.
      let filePath = uci.get("simple-xray", "config", "config_file") || "/etc/simplexray/config.json";
      return fs.write(filePath, value).catch(function (e) {
        ui.addNotification(null, E("p", e.message));
      });
    };

    return m.render();
  },
  handleSaveApply: function (ev, mode) {
    return this.handleSave(ev).then(function () {
      return L.resolveDefault(fs.exec_direct("/etc/init.d/simple-xray", ["restart"]), null);
    });
  },
});
