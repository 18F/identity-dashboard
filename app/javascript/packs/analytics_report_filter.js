document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('#filter form');
  if (!form) { return; }

  const appSelect = form.querySelector('#analytic_uuid');
  const appOptions = appSelect.querySelectorAll('option');

  document.getElementById('analytic_team').addEventListener('change', (event) => {
    const opt = event.currentTarget.selectedOptions[0];
    const appIds = opt.dataset.apps.split(',');
    const invalidOptions = [];
    const validOptions = [];
    let appNeedsSetting = true;

    appOptions.forEach(option => {
      if(appIds.indexOf(option.value) < 0) {
        option.setAttribute('hidden', true);
      } else {
        option.removeAttribute('hidden');
        if(appNeedsSetting) {
          appNeedsSetting = false;
          appSelect.value = option.value;
        }
      }
    });
  });
});
