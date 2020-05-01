import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import {
  addEmailAddressToList,
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

    it("renders the initial email addresses in the email list");
  });

  describe(".addEmailAddressToList", () => {
    beforeEach(loadInitialEmailAddresses);

    it("adds a new email to the list", () => {
      addEmailAddressToList("email3@example.com");

      expect(window.manageUserEmailAddresses).to.deep.equal([
        "email1@example.com",
        "email2@example.com",
        "email3@example.com",
      ]);
    });

    it("does not add duplicate emails to the list", () => {
      addEmailAddressToList("email2@example.com");

      expect(window.manageUserEmailAddresses).to.deep.equal([
        "email1@example.com",
        "email2@example.com",
      ]);
    });

    it("renders a list item with the added email address");
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

    it("renders a list without an item for the deleted email");
  });
});
