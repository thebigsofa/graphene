// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require_tree .

$(document).ready(function() {
  $('pre.viz').each(function(i, el) {
    var viz = new Viz();
    viz.renderSVGElement($(el).text()).then(function(element) {
      $(el).replaceWith(element);
    }).catch(error => {
      console.error(error);
    });
  });

  renderjson.set_show_to_level("all");

  $('pre.json').each(function(i, el) {
    $(el).replaceWith(renderjson($.parseJSON($(el).text())));
  });
});
