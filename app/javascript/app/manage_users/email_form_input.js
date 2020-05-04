export const buildEmailAddressFormInput = (email) => {
  const input = document.createElement("input");
  input.type = "hidden";
  input.name = "user_emails[]";
  input.className = "user_email_input";
  input.value = email;
  return input;
};
