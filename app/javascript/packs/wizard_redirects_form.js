function redirectURISetup() {
  // Selectors
  const redirectURIContainer = document.querySelector('.wizard_step_redirect_uris .usa-input__container');
  const redirectURI = document.getElementById('add-redirect-uri-input');

  if (!redirectURI) { return; }

  // Functions
  const handleRedirectURIClick = () => {
    const lastInput = redirectURIContainer.querySelector('input:last-child');
    const newInput = lastInput.cloneNode(true);
    newInput.value = '';
    redirectURIContainer.appendChild(newInput);
  };

  // Event triggers
  redirectURI.addEventListener('click', handleRedirectURIClick);
}

window.addEventListener('DOMContentLoaded', redirectURISetup);
