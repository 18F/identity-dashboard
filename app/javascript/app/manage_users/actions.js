export const loadInitialEmailAddresses = () => {
  const inputs = Array.from(document.querySelectorAll(".user_email_input"));
  window.manageUserEmailAddresses = inputs.map((el) => el.value).sort();
};

export const addEmailAddressToList = (email) => {
  window.manageUserEmailAddresses = Array.from(
    new Set(window.manageUserEmailAddresses.concat(email))
  ).sort();
};

export const removeEmailAddressFromList = (email) => {
  window.manageUserEmailAddresses = window.manageUserEmailAddresses.filter((e) => e !== email);
};
