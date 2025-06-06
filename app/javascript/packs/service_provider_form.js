const showElement = (element) => element.classList.remove('display-none');
const hideElement = (element) => element.classList.add('display-none');

function ialOptionSetup() {
  // Selectors
  const ialLevel = document.getElementById('service_provider_ial');
  const ialAttributesCheckboxes = document.querySelectorAll('.ial-attr-wrapper');
  const failureToProofURL = document.querySelector('.service_provider_failure_to_proof_url');
  const ial1Attributes = ['email', 'all_emails', 'x509_subject', 'x509_presented', 'verified_at'];
  const failureToProofURLInput = failureToProofURL && failureToProofURL.querySelector('input');

  if (!failureToProofURL) { return; }

  // Functions
  const toggleIAL1Options = () => {
    ialAttributesCheckboxes.forEach((checkboxWrapper) => {
      const checkboxInput = checkboxWrapper.querySelector('input');
      if (!ial1Attributes.includes(checkboxInput.value)) {
        hideElement(checkboxWrapper);
        checkboxInput.checked = false;
      }
      failureToProofURLInput.removeAttribute('required');
    });
  };

  const toggleIAL2Options = () => {
    ialAttributesCheckboxes.forEach((checkboxWrapper) => {
      showElement(checkboxWrapper);
    });
    failureToProofURLInput.setAttribute('required', 'required');
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
  const spAcsUrl = document.getElementById('service_provider_acs_url');
  const returnToSpUrl = document.getElementById('service_provider_return_to_sp_url');

  if (idProtocols.length < 1) { return; }

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
        spAcsUrl.removeAttribute('required');
        returnToSpUrl.removeAttribute('required');
        break;
      case 'saml':
        toggleSAMLOptions();
        spAcsUrl.setAttribute('required', 'required');
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

function certificateUploadSetup() {
  // Selectors
  const pemInputMessage = document.querySelector('.js-pem-input-error-message');
  const pemInput = document.querySelector('.js-pem-input') || document.getElementById('pem-input');
  const pemFilename = document.querySelector('.js-pem-file-name');

  if (!pemInput) { return; }

  // Functions
  const setPemError = (message) => {
    pemInputMessage.textContent = message;
    if (message) {
      pemInputMessage.classList.add('usa-error-message');
    } else {
      pemInputMessage.classList.remove('usa-error-message');
    }
  };

  const handleUploadedCert = () => {
    const file = pemInput.files[0];

    pemFilename.textContent = file ? file.name : null;

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
  };

  // Event triggers
  pemInput.addEventListener('change', handleUploadedCert);
}

function logoUploadSetup() {
  // Selectors
  const logoInput = document.querySelector('.logo-input-file');
  const logoPreview = document.querySelector('.input-preview') || document.querySelector('.logo-preview');

  if (!logoInput) {
    return;
  }

  // Functions
  const handleUploadedLogo = () => {
    const logoFile = logoInput.files[0];

    logoPreview.textContent = (logoFile && logoFile.name) || '';
  };

  // Event triggers
  logoInput.addEventListener('change', handleUploadedLogo);
}

function redirectURISetup() {
  // Selectors
  const redirectURIContainer = document.querySelector('.service_provider_redirect_uris');
  const redirectURI = document.getElementById('add-redirect-uri-field');

  if (!redirectURI) { return; }

  // Functions
  const handleRedirectURIClick = () => {
    const lastInput = document.querySelector('.service_provider_redirect_uris input:last-child');
    const newInput = lastInput.cloneNode(true);
    newInput.value = '';
    redirectURIContainer.appendChild(newInput);
  };

  // Event triggers
  redirectURI.addEventListener('click', handleRedirectURIClick);
}

function serviceProviderForm() {
  ialOptionSetup();
  protocolOptionSetup();
  certificateUploadSetup();
  logoUploadSetup();
  redirectURISetup();
}

window.addEventListener('DOMContentLoaded', serviceProviderForm);
