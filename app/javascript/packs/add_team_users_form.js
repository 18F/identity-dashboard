document.addEventListener('DOMContentLoaded', function () {
  var container = document.getElementById('user-rows');
  var addButton = document.getElementById('add-user-row');

  if (!container || !addButton) return;

  addButton.addEventListener('click', function () {
    var rows = container.querySelectorAll('.user-row');
    var lastRow = rows[rows.length - 1];
    var newRow = lastRow.cloneNode(true);
    var newIndex = rows.length;

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
    var rows = container.querySelectorAll('.user-row');
    var buttons = container.querySelectorAll('.remove-row');
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].disabled = rows.length <= 1;
    }
  }
});
