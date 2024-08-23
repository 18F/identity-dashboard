const showElement = (element) => element.classList.remove('display-none');
const hideElement = (element) => element.classList.add('display-none');

function ialWizardOptionSetup() {
  // Selectors
  const ialLevels =  document.querySelectorAll('input[name="wizard_step[ial]"]');
  const ialLevelSelected = document.querySelector('input[name="wizard_step[ial]"][checked]')?.value || "1";
  const ialAttributesCheckboxes = document.querySelectorAll('input[name="wizard_step[attribute_bundle][]"][type="checkbox"]');
  const ial1Attributes = ['email', 'all_emails', 'x509_subject', 'x509_presented', 'verified_at'];

  if (ialAttributesCheckboxes.length < 1 || ialLevels.length < 1) { return; }

  // Functions
  const toggleIAL1Options = () => {
    ialAttributesCheckboxes.forEach((checkboxInput) => {
      if (!ial1Attributes.includes(checkboxInput.value)) {
        hideElement(checkboxInput.parentElement);
        checkboxInput.checked = false;
      }
    });
  };

  const toggleIAL2Options = () => {
    ialAttributesCheckboxes.forEach((checkboxInput) => {
      showElement(checkboxInput.parentElement);
    });
  };

  const toggleIALOptions = (ial) => {
    switch (ial) {
      case '1':
        toggleIAL1Options();
        break;
      case '2':
        toggleIAL2Options();
        break;
      default:
        toggleIAL2Options();
    }
  };

  // Page initialization
  toggleIALOptions(ialLevelSelected);

  // Event trigger
  ialLevels.forEach((element) => {
    element.addEventListener("change", (event) => {
      toggleIALOptions(event.target.value);
    })
  })
}

window.addEventListener('DOMContentLoaded', ialWizardOptionSetup)
