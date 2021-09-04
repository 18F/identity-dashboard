$(function(){
  if(!$('.service-provider-form').length){
    return;
  }

  // Selectors
  const idProtocol = $('input[name="service_provider[identity_protocol]"]');
  const ialLevel = $('#service_provider_ial');
  const samlFields = $('.saml-fields');
  const oidcFields = $('.oidc-fields');
  const ialAttributes = $('.ial-attr-wrapper')
  const fileInput = $('.input-file');
  const filePreview = $('.input-preview');
  const pemInput = $('.js-pem-input');
  const pemInputMessage = $('.js-pem-input-error-message');
  const redirectURI = $("#add-redirect-uri-field");
  const failureToProofInput = $('.service_provider_failure_to_proof_url');

  // Functions
  const toggleFormFields = (idProtocol) => {
    switch(idProtocol) {
      case 'openid_connect_private_key_jwt':
      case 'openid_connect_pkce':
        samlFields.hide();
        oidcFields.show();
        break;
      case 'saml':
        samlFields.show();
        oidcFields.hide();
        break;
      default:
        samlFields.show();
        oidcFields.show();
    }
  }

  const toggleIALOptions = (ial) => {
    ialAttributes.each((idx, el) => console.log(el))
    switch(ial) {
      case '1':
        failureToProofInput.hide();
        break;
      case '2':
        failureToProofInput.show();
        break;
      default:
        failureToProofInput.show();
    }
  }

  const setPemError = message => pemInputMessage.innerText = message;

  // Page initialization
  toggleFormFields(idProtocol.val());
  toggleIALOptions(ialLevel.val());

  // Event triggers
  idProtocol.change(evt => toggleFormFields(evt.target.value));

  ialLevel.change(evt => toggleIALOptions(evt.target.value));

  redirectURI.click(() => $(".service_provider_redirect_uris input:last-child")
      .clone()
      .appendTo(".service_provider_redirect_uris")
  );

  // This will need to change if we start uploading more files, e.g. certs, etc.
  fileInput.change(() => {
    const logo_file = filePreview.files[0];
    filePreview.textContent = logo_file.name;
  });

  pemInput.change((event) => {
    const file = event.target.files[0];

    $('.js-pem-file-name').innerText = file ? file.name : null;

    if (file && file.text) {
      file.text().then((content) => {
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
});
