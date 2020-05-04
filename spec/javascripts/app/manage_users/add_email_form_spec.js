import sinon from "sinon";

import {
  setupManageUsersTestDOM,
  tearDownManageUsersTestDOM,
} from "../../support/manage_users/dom";

import { setupAddEmailForm } from "../../../../app/javascript/app/manage_users/add_email_form";

describe("manage_users/add_email_form", () => {
  beforeEach(() => {
    setupManageUsersTestDOM();
  });

  afterEach(() => {
    tearDownManageUsersTestDOM();
  });

  describe(".setupAddEmailForm", () => {
    it("sets up an event listener to add an email address", () => {
      window.manageUserEmailAddresses = ["test1@example.com"];

      setupAddEmailForm();

      const input = document.getElementById("add_email");
      const button = document.getElementById("add_email_button");

      input.value = "test2@example.com";

      button.onclick();

      expect(window.manageUserEmailAddresses).to.deep.equal([
        "test1@example.com",
        "test2@example.com",
      ]);
      expect(document.body.textContent).to.have.string("test1@example.com");
      expect(document.body.textContent).to.have.string("test2@example.com");
    });

    it("does not add empty email addresses to the form", () => {
      window.manageUserEmailAddresses = ["test1@example.com"];

      setupAddEmailForm();

      const input = document.getElementById("add_email");
      const button = document.getElementById("add_email_button");

      input.value = "";

      button.onclick();

      expect(window.manageUserEmailAddresses).to.deep.equal(["test1@example.com"]);
    });

    it("adds a keypress event listener that adds an email on enter pressed", () => {
      window.manageUserEmailAddresses = ["test1@example.com"];

      setupAddEmailForm();

      const input = document.getElementById("add_email");
      const button = document.getElementById("add_email_button");

      input.value = "test2@example.com";
      input.focus();

      const ignoredEvent = { keyCode: 5, preventDefault: sinon.spy() };
      const enterEvent = { keyCode: 13, preventDefault: sinon.spy() };

      input.onkeypress(ignoredEvent);

      expect(ignoredEvent.preventDefault.calledOnce).to.eq(false);
      expect(window.manageUserEmailAddresses).to.deep.equal(["test1@example.com"]);

      input.onkeypress(enterEvent);

      expect(enterEvent.preventDefault.calledOnce).to.eq(true);
      expect(window.manageUserEmailAddresses).to.deep.equal([
        "test1@example.com",
        "test2@example.com",
      ]);
    });
  });
});
