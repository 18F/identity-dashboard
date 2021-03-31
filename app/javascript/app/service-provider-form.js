// Note: We've temporarily disabled validation of the issuer. Calls to
// `update_issuer` have been commented out.

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
    // update_issuer();
  });

  // $('input[name="service_provider[issuer_department]"]').keyup(update_issuer);
  // $('input[name="service_provider[issuer_app]"]').keyup(update_issuer);

  // Add another Redirect URI
  $("#add-redirect-uri-field").click(function() {
    $(".service_provider_redirect_uris input:last-child").clone().appendTo(".service_provider_redirect_uris");
  });

  // This will need to change if we start uploading more files, e.g. certs, etc.
  const input = document.querySelector('.input-file');
  const preview = document.querySelector('.input-preview');
  if (input) {
    input.addEventListener('change', function () {
      logo_file = input.files[0];
      preview.textContent = logo_file.name;
    });
  }

  /**
   * @param {string?} message
   */
  function setPemError(message) {
    var pemInputMessage = document.querySelector('.js-pem-input-error-message');
    pemInputMessage.innerText = message;
  }

  var pemInput = document.querySelector('.js-pem-input');
  if (pemInput) {
    pemInput.addEventListener('change', function(event) {
      var file = event.target.files[0];

      document.querySelector('.js-pem-file-name').innerText = file ? file.name : null;

      if (file) {
        file.text().then(function(content) {
          if (content.includes('PRIVATE')) {
            setPemError('This is a private key, upload the public key instead');
          } else if (!content.includes('-----BEGIN CERTIFICATE-----')) {
            setPemError('This file does not appear to be PEM encoded');
          } else {
            setPemError(null);
          }
        });
      } else {
        setPemError(null);
      }
    });
  }
});
