import { updateEmailAddressList } from "../app/manage_users/email_list";

window.manageUserEmailAddresses = [];

const loadInitialEmailAddresses = () => {
  const inputs = Array.from(document.querySelectorAll(".user_email_input"));
  window.manageUserEmailAddresses = inputs.map((el) => el.value).sort();
};

const removeEmailFromList = (email) => {
  window.manageUserEmailAddresses = window.manageUserEmailAddresses.filter((e) => e !== email);
  renderEmailList();
};

const addEmailToList = (email) => {
  window.manageUserEmailAddresses = Array.from(
    new Set(window.manageUserEmailAddresses.concat(email))
  ).sort();
  renderEmailList();
};

const renderEmailList = () => {
  updateEmailAddressList(window.manageUserEmailAddresses, removeEmailFromList);
};

document.addEventListener("DOMContentLoaded", () => {
  loadInitialEmailAddresses();
  renderEmailList();

  const button = document.getElementById("add_email_button");
  button.onclick = () => {
    const email = document.getElementById("add_email").value;
    if (!email) return;
    addEmailToList(email);
    document.getElementById("add_email").value = "";
  };
});
