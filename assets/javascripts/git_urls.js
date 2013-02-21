jQuery(function($) {
  var lists = $(".git-url-list");
  lists.each(function(i, e) {
    var list = $(e),
      field_id = list.attr("id") + "-field",
      container = $("<div>").insertAfter(list).addClass("git-url-list"),

      copy_div = $("<div>").addClass("copy").appendTo(container),
      copy = $("<button>").attr({"data-clipboard-target": field_id})
        .text("Copy to Clipboard").appendTo(copy_div)
        .button({text: false, icons: {primary: "ui-icon-clipboard"}}),

      bset = $("<div>").addClass("protocol").appendTo(container),

      field_div = $("<div>").addClass("url").appendTo(container);
      field = $("<input>").attr({id: field_id, readonly: "readonly"}).appendTo(field_div);
      
    list.children("dt").each(function(j, dt) {
      var $dt = $(dt), 
        label = $dt.text(), 
        url = $dt.next().text(), 
        name = "url_button_" + i,
        id = "url-button-" + i + "-" + j,
        checked = j == 0,
        input_attrs = {id: id, name: name, type: "radio", checked: checked};
      $("<input>").attr(input_attrs).val(url).appendTo(bset).change(function() {
        field.val($(this).val());
      });
      $("<label>").attr({for: id}).text(label).appendTo(bset);
    });
    bset.buttonset();
    field.val($(":checked", bset).val());

    list.hide();
    var zc = new ZeroClipboard(copy, {
      hoverClass: "ui-state-hover", activeClass: "ui-state-active"
    });
    zc.on("noflash", function(client, args) {
      $(".git-url-list .copy").hide();
    });
  });
});