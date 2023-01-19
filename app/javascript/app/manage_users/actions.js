import { updateEmailAddressList } from "./email_list";

export const loadInitialEmailAddresses = () => {
  const inputs = Array.from(document.querySelectorAll(".user_email_input"));
  window.manageUserEmailAddresses = inputs.map((el) => el.value).sort();
  updateEmailAddressList();
};

export const removeEmailAddressFromList = (email) => {
  window.manageUserEmailAddresses = window.manageUserEmailAddresses.filter((e) => e !== email);
  updateEmailAddressList();
};
