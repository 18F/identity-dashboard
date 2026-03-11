const teamMembershipSetup = () => {
  addFieldsetSetup();
  removeFieldsetSetup();
};

const addFieldsetSetup = () => {
  const fieldsetsContainer = document.querySelector('.new_user .usa-input__container');
  const addFieldsetButton = document.getElementById('add-team-membership-input');

  if (!addFieldsetButton) return;

  const handleAddFieldsetClick = () => {
    const lastFieldset = fieldsetsContainer.querySelector('.usa-fieldset:last-of-type');
    const newFieldset = lastFieldset.cloneNode(true);
    newFieldset.querySelector('input').value = '';
    newFieldset.querySelector('select').value = '';
    fieldsetsContainer.appendChild(newFieldset);
    newFieldset.querySelector('input').focus();
  }

  addFieldsetButton.addEventListener('click', handleAddFieldsetClick);
};

const removeFieldsetSetup = () => {

};

window.addEventListener('DOMContentLoaded', teamMembershipSetup);
