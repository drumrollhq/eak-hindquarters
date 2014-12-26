module.exports = function create(__helpers) {
  var str = __helpers.s,
      empty = __helpers.e,
      notEmpty = __helpers.ne,
      ___layout_marko = __helpers.l(require.resolve("../layout.marko")),
      marko_node_modules_marko_layout_use_tag = require("marko/node_modules/marko-layout/use-tag"),
      _tag = __helpers.t,
      marko_node_modules_marko_layout_put_tag = require("marko/node_modules/marko-layout/put-tag");

  return function render(data, out) {
    _tag(out,
      marko_node_modules_marko_layout_use_tag,
      {
        "template": ___layout_marko,
        "*": {
          "showHeader": true
        }
      },
      function(_layout) {
        _tag(out,
          marko_node_modules_marko_layout_put_tag,
          {
            "into": "title",
            "layout": _layout
          },
          function(out) {
            out.w('Sign Up');
          });
        _tag(out,
          marko_node_modules_marko_layout_put_tag,
          {
            "into": "body",
            "layout": _layout
          },
          function(out) {
            out.w('<h3>What are you into?</h3><div class="two-up"><div><h3>Social sign in excitement?!</h3><ul class="sso"><li><a href="/v1/auth/google?redirect=/v1/auth/register/oauth" class="sso-button sso-button-google">Sign up with <strong>Google</strong></a></li><li><a href="/v1/auth/facebook?redirect=/v1/auth/register/oauth" class="sso-button sso-button-facebook">Sign up with <strong>Facebook</strong></a></li></ul></div><div><h3>Or, these crazy text fields!? <span class="sub">Real talk: they\'re mostly not text fields</span></h3><form method="POST" url="/v1/users/register"><div class="feedback-area"></div><label class="text-field"><h4>What\'s your first name?</h4><input type="text" name="firstName" placeholder="e.g. Tarquin"></label><div class="radio-group"><h4>Are you aged 13 or over?</h4><div class="radio-group-radios"><input id="ay" type="radio" name="overThirteen" value="true"><label for="ay">Yes</label><input id="an" type="radio" name="overThirteen" value="false"><label for="an">No</label></div></div><button type="submit" class="button-smaller">Onwards!</button></form></div></div><script>\n      function $(selector, ctx) {\n        return (ctx || document).querySelector(selector);\n      }\n\n      function $$(selector, ctx) {\n        return Array.prototype.slice.apply((ctx || document).querySelectorAll(selector));\n      }\n\n      function hideFeedback() {\n        form.classList.remove(\'has-errors\');\n        $$(\'form .has-error\').forEach(function(el) {\n          el.classList.remove(\'has-error\');\n        });\n      }\n\n      function showFeedback(msg, el) {\n        form.classList.add(\'has-errors\');\n        feedbackArea.innerHTML = msg;\n        if (el) el.classList.add(\'has-error\');\n      }\n\n      var form = $(\'form\'),\n        feedbackArea = $(\'.feedback-area\');\n\n      $(\'button\').addEventListener(\'submit\', function(e) {\n        var name = form.firstName.value.trim(),\n          overThirteen = form.overThirteen.value;\n\n        hideFeedback();\n\n        if (!name) {\n          showFeedback(\'Please enter your name!\', form.firstName.labels[0]);\n          e.preventDefault();\n          return false;\n        }\n\n        if (!overThirteen) {\n          showFeedback(\'You need to say if you\\\'re over thirteen!\', $(\'h4\', form.overThirteen[0].parentNode.parentNode));\n          e.preventDefault();\n          return false;\n        }\n\n        return true;\n      }, false);\n    </script>');
          });
      });
  };
}