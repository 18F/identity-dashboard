document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('#filter form');
  if (!form) { return; }

  const allSelects = document.getElementById('reports_form').querySelectorAll('select');
  const teamSelect = document.getElementById('analytic_team');
  const appSelect = document.getElementById('analytic_uuid');
  const dateSelect = document.getElementById('analytic_date');
  const allAppOptions = new Array(...appSelect.getElementsByTagName('option'));
  const allDateOptions = new Array(...dateSelect.getElementsByTagName('option'));

  const onSelectChange = (ev) => {
    // Parent select element and children
    const select = ev.currentTarget;
    const opt = select.selectedOptions[0];
    const optIds = opt.dataset.controls.split(',');
    // Child select element and children
    const nextSelect = allSelects[[...allSelects].indexOf(select) + 1];
    const nextOptions = nextSelect === appSelect ? allAppOptions : allDateOptions;
    const nextValue = nextSelect.value;
    const nextValueIsSet = !!opt.dataset.controls.includes(nextValue);
    // Unless a specific option is selected, don't select a new option on child
    let optNeedsSetting = !!select.value.length;
    // Filter the child options
    nextSelect.innerHTML = '';
    nextOptions.forEach((option) => {
      if (optIds.indexOf(option.value) >= 0) {
        nextSelect.appendChild(option);
        // Set the child select value, and cascade if App select
        if (optNeedsSetting || !nextValueIsSet) {
          // condition: no default
          if (optNeedsSetting && !nextValueIsSet) {
            nextSelect.value = option.value;
          }
          // if the next Select element is Application, also update Dates
          if (!nextValueIsSet && nextSelect === appSelect) {
            nextSelect.dispatchEvent(new Event('change'));
          }
          // We updated selected option, so it doesn't need to be set again.
          optNeedsSetting = false;
        }
        // If the next value is preselected (ie by URL), set it and base the next
        // set of options on this value.
        if (nextValue === option.value && nextValueIsSet) {
          nextSelect.value = option.value;
          nextSelect.dispatchEvent(new Event('change'));
        }
      }
    });
  };
  // Listen for changes to Team and Application Selects
  teamSelect.addEventListener('change', onSelectChange);
  appSelect.addEventListener('change', onSelectChange);
  // Filter URL-defined report on page load
  onSelectChange({ currentTarget: teamSelect });
});
