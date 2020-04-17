import { buildEmailAddressRow } from "../app/manage_users/email_row";

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
  const emailAddressList = document.querySelector("#user_email_list");
  emailAddressList.innerHTML = "";
  window.manageUserEmailAddresses.forEach((email) => {
    const row = buildEmailAddressRow(email, removeEmailFromList);
    emailAddressList.append(row);
  });
};

document.addEventListener("DOMContentLoaded", () => {
  loadInitialEmailAddresses();
  renderEmailList();
});
