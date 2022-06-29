import { loadInitialEmailAddresses } from "../app/manage_users/actions";
import { setupAddEmailForm } from "../app/manage_users/add_email_form";

document.addEventListener("DOMContentLoaded", () => {
  loadInitialEmailAddresses();
  setupAddEmailForm();
});
