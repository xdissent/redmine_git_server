(function($) {
  var format_sel = $("#repository_extra_url_format"),
    repo_url = $("#repository_url"),
    repo_id = $("#repository_identifier"),

    update_url = function() {
      if (format_sel.val() == "custom") {
        repo_url.removeAttr("readonly");
      } else {
        repo_url.attr("readonly", "readonly").val(calculate_url());
      }
    },

    calculate_url = function() {
      var id = repo_id.val(), ph = window.project_hierarchy;
      return (format_sel.val() == "flat" ? ph[ph.length - 1] : ph.join("/")) + (id == "" ? ".git" : "/" + id + ".git");
    };

  format_sel.change(update_url);
  repo_id.keyup(update_url);
  update_url();

})(jQuery);