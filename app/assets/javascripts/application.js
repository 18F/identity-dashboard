//= require jquery
//= require jquery_ujs
//= require_self

// Service Providers ///////////////////////////////////////////////////////////

var SERVICE_PROVIDER_ISSUER_TEMPLATE = 'urn:gov:gsa:{protocol}.profiles:sp:sso:{department}:{app}'

$(function(){
  if(!$('.service-provider-form').length){
    return;
  }

  var toggle_form_fields = function(id_protocol){
    switch(id_protocol){
      case 'openid_connect':
        $('.saml-fields').hide();
        $('.oidc-fields').show();
        break;
      case 'saml':
        $('.saml-fields').show();
        $('.oidc-fields').hide();
        break;
      default:
        $('.saml-fields').show();
        $('.oidc-fields').show();
    }
  }

  var issuer_protocol_name = function(id_protocol){
    switch(id_protocol){
      case 'openid_connect':
        return 'openidconnect';
      case 'saml':
        return 'SAML:2.0';
      default:
        return "";
    }
  }

  var id_protocol = function(){
    return $('input[name="service_provider[identity_protocol]"]:checked').val();
  }

  var update_issuer = function() {
    var protocol = issuer_protocol_name(id_protocol());
    var department = $('#service_provider_issuer_department').val();
    var app = $('#service_provider_issuer_app').val();

    var issuer_string = SERVICE_PROVIDER_ISSUER_TEMPLATE
      .replace('{protocol}', protocol)
      .replace('{department}', department)
      .replace('{app}', app);

    $('#service_provider_issuer').val(issuer_string);
  }

  toggle_form_fields(id_protocol());

  $('input[name="service_provider[identity_protocol]"]').click(function(){
    toggle_form_fields(id_protocol());
    update_issuer();
  });

  $('input[name="service_provider[issuer_department]"]').keyup(update_issuer);
  $('input[name="service_provider[issuer_app]"]').keyup(update_issuer);
});


// Utilities ///////////////////////////////////////////////////////////////////

// Removing element from DOM (on click containing appropriate data attribute)
const dismiss = '[data-dismiss="true"]';
$(document).on('click', dismiss, function(e) { $(e.target).parent().remove(); });


// Safari & IE 8/9 do not support client side handling of `required` attribute on
// form inputs; this adds basic messaging and styling fallback for these browsers
$(document).on('ready', function() {
  const message = '<div class="bold mb2">Please fill in all required fields.</div>';

  $('form').on('submit', function(e) {
    const $form = $(this);
    const $fields = $form.find('[required]').filter(function() { return this.value === ''; });

    if ($fields.length) {
      e.preventDefault();
      $form.prepend(message);
      $fields.each(function() { $(this).addClass('border-red'); });
    }
  });
});
