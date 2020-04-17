import { updateEmailAddressList } from "../app/manage_users/email_list";

window.manageUserEmailAddresses = [];

const loadInitialEmailAddresses = () => {
  const inputs = Array.from(document.querySelectorAll(".user_email_input"));
  window.manageUserEmailAddresses = inputs.map((el) => el.value).sort();
};

const removeEmailFromList = (email) => {
  window.manageUserEmailAddresses = manageUserEmailAddresses.filter((e) => e !== email);
  renderEmailList();
};

const renderEmailList = () => {
  updateEmailAddressList(window.manageUserEmailAddresses, removeEmailFromList);
};

document.addEventListener("DOMContentLoaded", () => {
  loadInitialEmailAddresses();
  renderEmailList();
});
