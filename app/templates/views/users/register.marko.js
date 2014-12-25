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
            out.w('<h3>What are you into?</h3><div class="two-up"><div><h3>Social sign in excitement?!</h3><ul class="sso"><li><a href="/v1/auth/google" class="sso-button sso-button-google">Sign up with <strong>Google</strong></a></li><li><a href="/v1/auth/facebook" class="sso-button sso-button-facebook">Sign up with <strong>Facebook</strong></a></li></ul></div><div><h3>Or, these crazy text fields!?</h3><form method="POST" url="/v1/users/register"><label><h4>First Name</h4><input type="text" name="firstName" placeholder="e.g. Tarquin"></label><label><h4>Age</h4><input type="number" name="age"></label><label><h4>Gender</h4><input type="text" name="gender" placeholder="e.g. Brocolli"></label></form></div></div>');
          });
      });
  };
}