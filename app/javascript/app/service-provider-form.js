const showElement = (element) => element.classList.remove('display-none');
const hideElement = (element) => element.classList.add('display-none');

function ialOptionSetup() {
  // Selectors
  const ialLevel = document.getElementById('service_provider_ial');
  const ialAttributesCheckboxes = document.querySelectorAll('.ial-attr-wrapper');
  const failureToProofURL = document.querySelector('.service_provider_failure_to_proof_url');
  const ial1Attributes = ['email', 'all_emails', 'x509_subject', 'x509_presented', 'verified_at'];

  // Functions
  const toggleIAL1Options = () => {
    ialAttributesCheckboxes.forEach((checkboxWrapper) => {
      const checkboxInput = checkboxWrapper.querySelector('input');
      if (!ial1Attributes.includes(checkboxInput.value)) {
        hideElement(checkboxWrapper);
        checkboxInput.checked = false;
      }
    });
  };

  const toggleIAL2Options = () => {
    ialAttributesCheckboxes.forEach((checkboxWrapper) => {
      showElement(checkboxWrapper);
    });
  };

  const toggleIALOptions = (ial) => {
    switch (ial) {
      case '1':
        hideElement(failureToProofURL);
        toggleIAL1Options();
        break;
      case '2':
        showElement(failureToProofURL);
        toggleIAL2Options();
        break;
      default:
        showElement(failureToProofURL);
        toggleIAL2Options();
    }
  };

  // Page initialization
  toggleIALOptions(ialLevel.value);

  // Event trigger
  ialLevel.addEventListener("change", (event) => toggleIALOptions(event.target.value));
}

function protocolOptionSetup() {
  const idProtocols = document.querySelectorAll('input[name="service_provider[identity_protocol]"]');
  const activeIdProtocol = document.querySelector('input[name="service_provider[identity_protocol]"]:checked');
  const samlFields = document.querySelectorAll('.saml-fields');
  const oidcFields = document.querySelectorAll('.oidc-fields');
  const returnToSpUrl = document.getElementById('service_provider_return_to_sp_url');

  // Functions
  const toggleSAMLOptions = () => {
    samlFields.forEach(showElement);
    oidcFields.forEach(hideElement);
  };

  const toggleOIDCOptions = () => {
    oidcFields.forEach(showElement);
    samlFields.forEach(hideElement);
  };

  const toggleFormFields = (protocol) => {
    switch (protocol) {
      case 'openid_connect_private_key_jwt':
      case 'openid_connect_pkce':
        toggleOIDCOptions();
        returnToSpUrl.removeAttribute('required');
        break;
      case 'saml':
        toggleSAMLOptions();
        returnToSpUrl.setAttribute('required', 'required');
        break;
      default:
        samlFields.forEach(showElement);
        oidcFields.forEach(showElement);
    }
  };

  // Page initialization
  toggleFormFields(activeIdProtocol.value);

  // Event triggers
  idProtocols.forEach((idProtocol) => {
    idProtocol.addEventListener("change", (event) => toggleFormFields(event.target.value));
  });
}

function serviceProviderForm() {
  if (!document.querySelector('.service-provider-form')) {
    return;
  }

  ialOptionSetup();
  protocolOptionSetup();
}

window.addEventListener('DOMContentLoaded', serviceProviderForm);

$(function () {
  if (!$('.service-provider-form').length) {
    return;
  }

  // Selectors
  const fileContainer = $('#certificate-container');
  const logoInput = $('.input-file');
  const pemInputMessage = $('.js-pem-input-error-message');
  const pemInput = $('.js-pem-input');
  const redirectURI = $('#add-redirect-uri-field');

  // Functions

  const setPemError = (message) => (pemInputMessage[0].textContent = message); // eslint-disable-line

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
