document.addEventListener('DOMContentLoaded', function () {
  const container = document.getElementById('user-rows');
  const addButton = document.getElementById('add-user-row');

  if (!container || !addButton) { return; }

  function updateRemoveButtons() {
    const onlyOneRow = container.querySelectorAll('.user-row').length <= 1;
    container.querySelectorAll('.remove-row').forEach(function (button) {
      button.disabled = onlyOneRow;
    });
  }

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

    container.appendChild(newRow);
    updateRemoveButtons();
  });

  container.addEventListener('click', function (event) {
    const removeButton = event.target.closest('.remove-row');
    if (!removeButton) { return; }

    removeButton.closest('.user-row').remove();
    updateRemoveButtons();
  });
});
