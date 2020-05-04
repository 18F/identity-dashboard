import { setupTestDOM, tearDownTestDOM } from "../dom";

const INITIAL_MANAGE_USERS_HTML = `
  <form>
    <div id='user_email_inputs'>
      <input name='user_emails[]' value='email1@example.com' class='user_email_input'/>
      <input name='user_emails[]' value='email2@example.com' class='user_email_input'/>
    </div>
  </form>

  <ul id='user_email_list'></ul>

  <label for='add_email'>Email</label>
  <input type='text' id='add_email'/>
  <button type='button' id='add_email_button'>
    Add user
  </button>
`;

export const setupManageUsersTestDOM = () => {
  setupTestDOM(INITIAL_MANAGE_USERS_HTML);
};

export const tearDownManageUsersTestDOM = () => tearDownTestDOM();
