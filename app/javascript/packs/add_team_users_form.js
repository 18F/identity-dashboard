document.addEventListener('DOMContentLoaded', function () {
  const container = document.getElementById('user-rows');
  const addButton = document.getElementById('add-user-row');

  if (!container || !addButton) { return; }

  const form = container.closest('form');

  form.setAttribute('novalidate', 'true');

  function showError(input, errorEl, message) {
    input.classList.add('usa-input--error');
    input.setAttribute('aria-invalid', 'true');
    errorEl.textContent = message;
    errorEl.classList.remove('display-none');
  }

  function clearError(input, errorEl) {
    input.classList.remove('usa-input--error');
    input.setAttribute('aria-invalid', 'false');
    errorEl.textContent = '';
    errorEl.classList.add('display-none');
  }

  const submitButton = form.querySelector('input[type="submit"]');

  function updateSubmitButton() {
    const missingRole = Array.from(container.querySelectorAll('.user-row')).some(function (row) {
      return !row.querySelector('select').value;
    });
    submitButton.disabled = missingRole;
  }

  function updateRemoveButtons() {
    const onlyOneRow = container.querySelectorAll('.user-row').length <= 1;
    container.querySelectorAll('.remove-row').forEach(function (button) {
      button.disabled = onlyOneRow;
    });
  }

  form.addEventListener('submit', function (event) {
    let hasErrors = false;

    container.querySelectorAll('.user-row').forEach(function (row) {
      const emailInput = row.querySelector('input[type="email"]');
      const emailError = emailInput.parentElement.querySelector('.usa-error-message');
      const select = row.querySelector('select');
      const selectError = select.parentElement.querySelector('.usa-error-message');

      clearError(emailInput, emailError);
      clearError(select, selectError);

      if (!emailInput.value.trim()) {
        showError(emailInput, emailError, 'Email is required');
        hasErrors = true;
      } else if (!emailInput.value.match(/^[^@\s]+@[^@\s]+$/)) {
        showError(emailInput, emailError, 'Enter a valid email address');
        hasErrors = true;
      }

      if (!select.value) {
        showError(select, selectError, 'Access level is required');
        hasErrors = true;
      }
    });

    if (hasErrors) {
      event.preventDefault();
      event.stopPropagation();
    }
  });

  let nextIndex = container.querySelectorAll('.user-row').length;

  addButton.addEventListener('click', function () {
    const rows = container.querySelectorAll('.user-row');
    const lastRow = rows[rows.length - 1];
    const newRow = lastRow.cloneNode(true);
    const newIndex = nextIndex++;

    const emailInput = newRow.querySelector('input[type="email"]');
    emailInput.value = '';
    emailInput.id = `users_${newIndex}_email`;
    newRow.querySelector('label[for*="_email"]').setAttribute('for', emailInput.id);

    const select = newRow.querySelector('select');
    select.selectedIndex = 0;
    select.id = `users_${newIndex}_role_name`;
    newRow.querySelector('label[for*="_role_name"]').setAttribute('for', select.id);

    newRow.setAttribute('data-row-index', newIndex);

    newRow.querySelectorAll('.usa-error-message').forEach(function (el) {
      el.textContent = '';
      el.classList.add('display-none');
    });
    newRow.querySelectorAll('.usa-input--error').forEach(function (el) {
      el.classList.remove('usa-input--error');
      el.setAttribute('aria-invalid', 'false');
    });

    container.appendChild(newRow);
    updateRemoveButtons();
    updateSubmitButton();
  });

  container.addEventListener('click', function (event) {
    const removeButton = event.target.closest('.remove-row');
    if (!removeButton) { return; }

    removeButton.closest('.user-row').remove();
    updateRemoveButtons();
    updateSubmitButton();
  });

  container.addEventListener('change', function (event) {
    if (event.target.matches('select')) {
      updateSubmitButton();
    }
  });

  updateSubmitButton();
});
