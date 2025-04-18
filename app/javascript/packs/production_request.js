const prodRequestInputs = document.querySelectorAll('.prod-request-input');
const zendeskSubmitButton = document.getElementById('submit-prod-request');

function toggleZendeskSubmitButton() {
  let zendeskSubmitDisabled = false;
  prodRequestInputs.forEach((input) => {
    if (input.value === '' || input.value === input.defaultValue) {
      zendeskSubmitDisabled = true;
    }
  });
  zendeskSubmitButton.disabled = zendeskSubmitDisabled;
}

function productionRequestModal() {
  prodRequestInputs.forEach((input) => {
    input.addEventListener('keyup', toggleZendeskSubmitButton);
  });
}

window.addEventListener('DOMContentLoaded', productionRequestModal);
