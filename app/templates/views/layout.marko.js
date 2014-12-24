module.exports = function create(__helpers) {
  var str = __helpers.s,
      empty = __helpers.e,
      notEmpty = __helpers.ne,
      marko_node_modules_marko_layout_placeholder_tag = require("marko/node_modules/marko-layout/placeholder-tag"),
      _tag = __helpers.t,
      attr = __helpers.a;

  return function render(data, out) {
    out.w('<!DOCTYPE html> <html><head><meta charset="utf-8"><title>');
    _tag(out,
      marko_node_modules_marko_layout_placeholder_tag,
      {
        "name": "title",
        "content": data.layoutContent
      });

    out.w(' | E.A.K.</title><link rel="stylesheet" href="/static/style.css"></head><body>');

    if (data.showHeader) {
      out.w('<header><div class="container"><h1>');
      _tag(out,
        marko_node_modules_marko_layout_placeholder_tag,
        {
          "name": "title",
          "content": data.layoutContent
        });

      out.w(' - E.A.K.</h1></div></header>');
    }

    out.w('<div class="container"><div' +
      attr("class", data.containerClass) +
      '>');
    _tag(out,
      marko_node_modules_marko_layout_placeholder_tag,
      {
        "name": "body",
        "content": data.layoutContent
      });

    out.w('</div></div></body></html>');
  };
}