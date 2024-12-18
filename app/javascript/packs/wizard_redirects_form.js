const createAddURIBtn = container => {
  const button = document.createElement('button');
  button.setAttribute('type', 'button');
  button.id = 'add-redirect-uri-input';
  button.classList.add('usa-button', 'usa-button--unstyled');
  button.innerText = 'Add another URI';

  container.appendChild(button);
  return button;
}

const redirectURISetup = () => {
  const redirectURIContainer = document.querySelector('.wizard_step_redirect_uris .usa-input__container');
  const addURIBtn = document.getElementById('add-redirect-uri-input')
    || createAddURIBtn(redirectURIContainer);

  const handleRedirectURIClick = () => {
    const lastInput = redirectURIContainer.querySelector('input:last-of-type');
    const newInput = lastInput.cloneNode(true);
    newInput.value = '';
    redirectURIContainer.insertBefore(newInput, addURIBtn);
  };

  addURIBtn.addEventListener('click', handleRedirectURIClick);
}

window.addEventListener('DOMContentLoaded', redirectURISetup);
