//= require jquery
//= require jquery_ujs
//= require_self

// Add Redirect URI ////////////////////////////////////////////////////////////

$("#add-redirect-uri-field").click(function() {
  $(".service_provider_redirect_uris input:last-child").clone().appendTo(".service_provider_redirect_uris");
});
