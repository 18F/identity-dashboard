import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import {
  removeEmailAddressFromList,
  loadInitialEmailAddresses,
} from "../../../../app/javascript/app/manage_users/actions";

describe("manage_users/actions", () => {
  beforeEach(() => {
    setupManageUsersTestDOM();
  });

  afterEach(() => {
    tearDownManageUsersTestDOM();
  });

  describe(".loadInitialEmailAddresses", () => {
    it("loads the initial email addresses into a global variable", () => {
      loadInitialEmailAddresses();

      expect(window.manageUserEmailAddresses).to.deep.equal([
        "email1@example.com",
        "email2@example.com",
      ]);
    });

    it("renders the initial email addresses in the email list", () => {
      loadInitialEmailAddresses();

      expect(document.body.textContent).to.have.string("email1@example.com");
      expect(document.body.textContent).to.have.string("email2@example.com");
    });
  });

  describe(".removeEmailAddressFromList", () => {
    beforeEach(loadInitialEmailAddresses);

    it("removes an email from the list", () => {
      removeEmailAddressFromList("email1@example.com");

      expect(window.manageUserEmailAddresses).to.deep.equal(["email2@example.com"]);
    });

    it("does nothing if the email is already on the list", () => {
      removeEmailAddressFromList("email3@example.com");

      expect(window.manageUserEmailAddresses).to.deep.equal([
        "email1@example.com",
        "email2@example.com",
      ]);
    });

    it("renders a list without an item for the deleted email", () => {
      removeEmailAddressFromList("email1@example.com");

      expect(document.body.textContent).to.not.have.string("email1@example.com");
      expect(document.body.textContent).to.have.string("email2@example.com");
    });
  });
});
