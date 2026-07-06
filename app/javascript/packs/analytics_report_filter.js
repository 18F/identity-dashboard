document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('#filter form');
  if (!form) { return; }

  const allSelects = document.getElementById('reports_form').querySelectorAll('select');
  const teamSelect = document.getElementById('analytic_team');
  const appSelect = document.getElementById('analytic_uuid');

  const onSelectChange = (ev) => {
    // Parent select element and children
    const select = ev.currentTarget;
    const opt = select.selectedOptions[0];
    const optIds = opt.dataset.controls.split(',');
    // Child select element and children
    const nextSelect = allSelects[[...allSelects].indexOf(select) + 1];
    const nextOptions = nextSelect.querySelectorAll('option');
    const nextValueIsSet = opt.dataset.controls.includes(nextSelect.value);
    // Unless a specific option is selected, don't select a new option on child
    let optNeedsSetting = !!select.value.length;
    // Filter the child options
    nextOptions.forEach((option) => {
      if (optIds.indexOf(option.value) < 0) {
        option.classList.add('display-none');
      } else {
        option.classList.remove('display-none');
        // Set the child select value, and cascade if App
        if (optNeedsSetting || !nextValueIsSet) {
          if (optNeedsSetting && !nextValueIsSet) {
            nextSelect.value = option.value;
          }
          if (nextSelect === appSelect) {
            nextSelect.dispatchEvent(new Event('change'));
          }
          optNeedsSetting = false;
        }
      }
    });
  };

  teamSelect.addEventListener('change', onSelectChange);
  appSelect.addEventListener('change', onSelectChange);
  // Filter URL-defined report on page load
  onSelectChange({ currentTarget: teamSelect });
});
