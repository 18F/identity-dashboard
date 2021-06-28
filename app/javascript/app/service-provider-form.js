// Note: We've temporarily disabled validation of the issuer. Calls to
// `update_issuer` have been commented out.

var SERVICE_PROVIDER_ISSUER_TEMPLATE = 'urn:gov:gsa:{protocol}.profiles:sp:sso:{department}:{app}'

$(function(){
  if(!$('.service-provider-form').length){
    return;
  }

  var toggle_form_fields = function(id_protocol){
    switch(id_protocol){
      case 'openid_connect_private_key_jwt':
        $('.saml-fields').hide();
        $('.oidc-fields').show();
        break;
      case 'openid_connect_pkce':
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

  var id_protocol = function(){
    return $('input[name="service_provider[identity_protocol]"]:checked').val();
  }

  toggle_form_fields(id_protocol());

  $('input[name="service_provider[identity_protocol]"]').click(function(){
    toggle_form_fields(id_protocol());
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

      if (file && file.text) {
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
