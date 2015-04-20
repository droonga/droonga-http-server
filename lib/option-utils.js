var LIST_SEPARATOR_MATCHER = /\s*[,|]\s*/;

function normalizeStringArray(values) {
  if (Array.isArray(values))
    return values;

  values = values.trim();
  if (!values)
    return [];

  if (LIST_SEPARATOR_MATCHER.test(values))
    return values.split(LIST_SEPARATOR_MATCHER);
  else
    return values.split(/\s+/);
}
exports.normalizeStringArray = normalizeStringArray;


function intOption(newValue, oldValue) {
  return parseInt(newValue);
}
exports.intOption = intOption;

function floatOption(newValue, oldValue) {
  return parseFloat(newValue);
}
exports.floatOption = floatOption;

function stringsOption(newValue, oldValue) {
  return normalizeStringArray(newValue);
}
exports.stringsOption = stringsOption;

function pluginsOption(newValue, oldValue) {
  return normalizeStringArray(newValue).map(function (plugin) {
    return require(plugin);
  });
}
exports.pluginsOption = pluginsOption;
