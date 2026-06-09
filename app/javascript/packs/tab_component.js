let allItems, list, button;

const arrayMod = (a, b) => {
  const mod = a % b;
  if (mod < 0) {
    return mod + b;
  } else {
    return mod;
  }
};

const onEvent = (ev) => {
  ev.preventDefault();
  history.replaceState(
    null,
    null,
    `#${ev.currentTarget.getAttribute('aria-controls')}`,
  );
};

const validHash = (hash, panels) => {
  return new Array(...panels).some(p => p.id == hash);
};

const onButtonSelect = () => {
  list.classList.toggle('is-active');
}

const onTabSelect = (ev) => {
  if (ev?.type == 'keydown') {
    let items, currentIndex, newTarget;
    switch (ev.key) {
      case ' ':
      case 'Enter':
        onEvent(ev);
        break;
      case 'ArrowRight':
        items = new Array(...allItems);
        currentIndex = items.indexOf(ev.currentTarget);
        newTarget = items[arrayMod(currentIndex + 1, items.length)];
        newTarget.focus();
        newTarget.click();
        return true;
      case 'ArrowLeft':
        items = new Array(...allItems);
        currentIndex = items.indexOf(ev.currentTarget);
        newTarget = items[arrayMod(currentIndex - 1, items.length)];
        newTarget.focus();
        newTarget.click();
        return true;
      default:
        return false;
    }
  } else if (ev?.type == 'click') {
    onEvent(ev);
  }

  const allPanels = document.querySelectorAll('.usa-tab__panel');
  const mobileTabTitle = document.getElementById('usa-tab__title');

  const selectedPanel = ev?.currentTarget !== window &&
    ev?.currentTarget.getAttribute('aria-controls');
  const hash = location.hash?.slice(1);
  const hashPanel = validHash(hash, allPanels) && hash;
  const defaultPanel = allPanels[0].id;

  const currentPanelId = selectedPanel || hashPanel || defaultPanel;

  allPanels.forEach(panel => {
    panel.style.display = (panel.id == currentPanelId) ? '' : 'none';
  });
  allItems.forEach(item => {
    const isActiveItem = item.id == `usa-tab__${currentPanelId}`;

    item.setAttribute('aria-selected', isActiveItem);
    if (isActiveItem) {
      mobileTabTitle.innerText = item.innerText;
      item.classList.add('is-active');
    } else {
      item.classList.remove('is-active');
    }
  });
  // hide mobile dropdown;
  list.classList.remove('is-active');
};

addEventListener('DOMContentLoaded', () => {
  allItems = document.querySelectorAll('.usa-tab__item');
  list = document.getElementById('usa-tab-list');
  button = document.getElementById('usa-tab-button');

  list.classList.remove('default-active');

  button.addEventListener('click', onButtonSelect);

  allItems.forEach(item => {
    item.addEventListener('click', onTabSelect);
    item.addEventListener('keydown', onTabSelect);
  });

  addEventListener('hashchange', onTabSelect);

  onTabSelect();
});
