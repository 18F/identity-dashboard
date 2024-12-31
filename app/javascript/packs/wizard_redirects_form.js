const redirectURISetup = () => {
  const redirectURIContainer = document.querySelector('.wizard_step_redirect_uris .usa-input__container');
  const addURIButton = document.getElementById('add-redirect-uri-input');

  if (!addURIButton) { return; }

  const handleRedirectURIClick = () => {
    const lastInput = redirectURIContainer.querySelector('input:last-of-type');
    const newInput = lastInput.cloneNode(true);
    newInput.value = '';
    redirectURIContainer.insertBefore(newInput, addURIButton);
    newInput.focus();
  };

  addURIButton.addEventListener('click', handleRedirectURIClick);
};

window.addEventListener('DOMContentLoaded', redirectURISetup);
