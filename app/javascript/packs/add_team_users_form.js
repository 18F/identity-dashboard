document.addEventListener('DOMContentLoaded', function () {
  var container = document.getElementById('user-rows');
  var addButton = document.getElementById('add-user-row');

  if (!container || !addButton) return;

  var nextIndex = container.querySelectorAll('.user-row').length;

  addButton.addEventListener('click', function () {
    var rows = container.querySelectorAll('.user-row');
    var lastRow = rows[rows.length - 1];
    var newRow = lastRow.cloneNode(true);
    var newIndex = nextIndex++;

    var emailInput = newRow.querySelector('input[type="email"]');
    emailInput.value = '';
    emailInput.id = 'users_' + newIndex + '_email';
    newRow.querySelector('label[for*="_email"]').setAttribute('for', emailInput.id);

    var select = newRow.querySelector('select');
    select.selectedIndex = 0;
    select.id = 'users_' + newIndex + '_role_name';
    newRow.querySelector('label[for*="_role_name"]').setAttribute('for', select.id);

    newRow.setAttribute('data-row-index', newIndex);

    container.appendChild(newRow);
    updateRemoveButtons();
  });

  container.addEventListener('click', function (event) {
    var removeButton = event.target.closest('.remove-row');
    if (!removeButton) return;

    removeButton.closest('.user-row').remove();
    updateRemoveButtons();
  });

  function updateRemoveButtons() {
    var onlyOneRow = container.querySelectorAll('.user-row').length <= 1;
    container.querySelectorAll('.remove-row').forEach(function (button) {
      button.disabled = onlyOneRow;
    });
  }
});
