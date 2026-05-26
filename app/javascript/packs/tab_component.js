const arrayMod = (a, b) => {
  const mod = a % b;
  if (mod < 0) {
    return mod + b;
  } else {
    return mod;
  }
};

const onEvent = (ev) => {
  console.log('click', ev.currentTarget);
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

const onTabSelect = (ev) => {
  const allAnchors = document.querySelectorAll('.usa-tab__anchor');

  if (ev?.type == 'keydown') {
    let anchors, currentIndex, newTarget;
    switch (ev.key) {
      case ' ':
      case 'Enter':
        onEvent(ev);
        break;
      case 'ArrowRight':
        anchors = new Array(...allAnchors);
        currentIndex = anchors.indexOf(ev.currentTarget);
        newTarget = anchors[arrayMod(currentIndex + 1, anchors.length)];
        newTarget.focus();
        newTarget.click();
        return true;
      case 'ArrowLeft':
        anchors = new Array(...allAnchors);
        currentIndex = anchors.indexOf(ev.currentTarget);
        newTarget = anchors[arrayMod(currentIndex - 1, anchors.length)];
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
  const allItems = document.querySelectorAll('.usa-tab__item');

  const selectedPanel = ev?.currentTarget !== window &&
    ev?.currentTarget.getAttribute('aria-controls');
  const hash = location.hash?.slice(1);
  const hashPanel = validHash(hash, allPanels) && hash;
  const defaultPanel = allPanels[0].id;

  const currentPanelId = selectedPanel || hashPanel || defaultPanel;

  allPanels.forEach(panel => {
    panel.style.display = (panel.id == currentPanelId) ? '' : 'none';
  });
  allAnchors.forEach(anchor => {
    anchor.setAttribute(
      'aria-selected',
      anchor.id == `usa-tab__${currentPanelId}`,
    );
  });
  allItems.forEach(item => {
    if (item.id == `usa-tab-item__${currentPanelId}`) {
      item.classList.add('is-active');
    } else {
      item.classList.remove('is-active');
    }
  });
};

addEventListener('DOMContentLoaded', () => {
  const anchors = document.querySelectorAll('.usa-tab__anchor');

  anchors.forEach(anchor => {
    anchor.addEventListener('click', onTabSelect);
    anchor.addEventListener('keydown', onTabSelect);
  });

  addEventListener('hashchange', onTabSelect);

  onTabSelect();
});
