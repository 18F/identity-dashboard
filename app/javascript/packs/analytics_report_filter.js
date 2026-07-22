document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('#filter form');
  if (!form) { return; }

  const teamSelect = document.getElementById('analytic_team');
  const appSelect = form.querySelector('#analytic_uuid');
  const appOptions = appSelect.querySelectorAll('option');

  const onTeamChange = () => {
    const opt = teamSelect.selectedOptions[0];
    const appIds = opt.dataset.apps.split(',');
    let appNeedsSetting = true;

    appOptions.forEach((option) => {
      if (appIds.indexOf(option.value) < 0) {
        option.classList.add('display-none');
      } else {
        option.classList.remove('display-none');
        if (appNeedsSetting) {
          appNeedsSetting = false;
          appSelect.value = option.value;
        }
      }
    });
  };

  document.getElementById('analytic_team').addEventListener('change', onTeamChange);
  onTeamChange();
});
