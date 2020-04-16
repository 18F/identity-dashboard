let manageUserEmailAddresses = [];

const loadInitialEmailAddresses = () => {
  const inputs = Array.from(document.querySelectorAll('.user_email_input'));
  manageUserEmailAddresses = inputs.map(el => el.value).sort();
  console.log(manageUserEmailAddresses);
};

const removeEmailFromList = (email) => {
  manageUserEmailAddresses = manageUserEmailAddresses.filter(e => e !== email);
  console.log(manageUserEmailAddresses);
};

const createEmailListRow = (email) => {
  const list = document.createElement('li');
  list.classList = 'margin-top-1';


}

document.addEventListener('DOMContentLoaded', () => {
  loadInitialEmailAddresses();
});
