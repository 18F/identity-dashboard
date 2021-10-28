$(function () {
  if (!$('.service-provider-form').length) {
    return;
  }

  // Selectors
  const idProtocol = $('input[name="service_provider[identity_protocol]"]');
  const ialLevel = $('#service_provider_ial');
  const samlFields = $('.saml-fields');
  const oidcFields = $('.oidc-fields');
  const ialAttributesCheckboxes = $('.ial-attr-wrapper');
  const fileContainer = $('#certificate-container');
  const logoInput = $('.input-file');
  const pemInputMessage = $('.js-pem-input-error-message');
  const pemInput = $('.js-pem-input');
  const redirectURI = $('#add-redirect-uri-field');
  const failureToProofURL = $('.service_provider_failure_to_proof_url');

  const ial1Attributes = ['email', 'x509_subject', 'x509_presented', 'verified_at'];

  // Functions
  const toggleIAL1Options = () => {
    ialAttributesCheckboxes.each((idx, attr) => {
      const element = $(attr).find('input');

      if (!ial1Attributes.includes(element.val())) {
        $(attr).hide();
        element.prop('checked', false);
      }
    });
  };

  const toggleIAL2Options = () => {
    ialAttributesCheckboxes.each((idx, attr) => $(attr).show());
  };

  const toggleSAMLOptions = () => {
    samlFields.show();
    oidcFields.hide();
  };

  const toggleOIDCOptions = () => {
    oidcFields.show();
    samlFields.hide();
  };

  const setPemError = (message) => (pemInputMessage[0].textContent = message); // eslint-disable-line

  const toggleFormFields = (protocol) => {
    switch (protocol) {
      case 'openid_connect_private_key_jwt':
      case 'openid_connect_pkce':
        toggleOIDCOptions();
        break;
      case 'saml':
        toggleSAMLOptions();
        break;
      default:
        samlFields.show();
        oidcFields.show();
    }
  };

  const toggleIALOptions = (ial) => {
    switch (ial) {
      case '1':
        failureToProofURL.hide();
        failureToProofURL.find('input').val('');
        toggleIAL1Options();
        break;
      case '2':
        failureToProofURL.show();
        toggleIAL2Options();
        break;
      default:
        failureToProofURL.show();
        toggleIAL2Options();
    }
  };

  // Page initialization
  toggleFormFields(idProtocol.filter(":checked").val());
  toggleIALOptions(ialLevel.filter(":checked").val());

  // Event triggers
  idProtocol.change((evt) => toggleFormFields(evt.target.value));

  ialLevel.change((evt) => toggleIALOptions(evt.target.value));

  redirectURI.click(() =>
      $('.service_provider_redirect_uris input:last-child')
          .clone()
          .val('')
          .appendTo('.service_provider_redirect_uris')
  );

  logoInput.change(() => {
    const logoFile = logoInput[0].files[0];
    const filePreview = $('.input-preview');

    filePreview.text((logoFile && logoFile.name) || '');
  });

  fileContainer.on('change', pemInput, () => {
    // Handles a single certificate file currently
    const file = pemInput[0].files[0];
    const pemFilename = $('.js-pem-file-name');

    pemFilename[0].textContent = file ? file.name : null;

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
