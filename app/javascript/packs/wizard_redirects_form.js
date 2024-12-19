const redirectURISetup = () => {
  const redirectURIContainer = document.querySelector('.wizard_step_redirect_uris .usa-input__container');
  const addURIBtn = document.getElementById('add-redirect-uri-input');

  if (!addURIBtn) return;

  const handleRedirectURIClick = () => {
    const lastInput = redirectURIContainer.querySelector('input:last-of-type');
    const newInput = lastInput.cloneNode(true);
    newInput.value = '';
    redirectURIContainer.insertBefore(newInput, addURIBtn);
    newInput.focus();
  };

  addURIBtn.addEventListener('click', handleRedirectURIClick);
}

window.addEventListener('DOMContentLoaded', redirectURISetup);
