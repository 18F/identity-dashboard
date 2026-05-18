document.addEventListener('DOMContentLoaded', function () {
  const form = document.querySelector('#filter form');

  if (!form) { return; }

  form.querySelectorAll('select').forEach(function (select) {
    select.addEventListener('change', function () {
      form.submit();
    });
  });
});
