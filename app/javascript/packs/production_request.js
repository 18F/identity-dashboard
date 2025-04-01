const prodRequestInputs = document.querySelectorAll('.prod-request-input');
const submitButton = document.getElementById('submit-prod-request');

function toggleSubmitButton() {
  let submitDisabled = false;
  prodRequestInputs.forEach((input) => {
    if (input.value === '' || input.value === input.defaultValue) {
      submitDisabled = true;
    }
  });
  submitButton.disabled = submitDisabled;
}

function productionRequestModal() {
  prodRequestInputs.forEach((input) => {
    input.addEventListener('change', toggleSubmitButton);
  });
}

window.addEventListener('DOMContentLoaded', productionRequestModal);
