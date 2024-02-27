function setup() {
  const versionToggle = document.getElementById('versionToggle');
	const versions = document.getElementById('versions')

	document.addEventListener('click', function (event) {
		toggle();
	}, false);

}

var show = function() {
	versions.style.display = 'block';
};

var hide = function() {
	versions.style.display = 'none';
};

var toggle = function() {
	if (window.getComputedStyle(versions).display === 'block') {
		hide();
		versionToggle.classList.add('closed')
		versionToggle.classList.remove('open')
		return;
	}

	versionToggle.classList.add('open')
	versionToggle.classList.remove('closed')
	show();

};
window.addEventListener('DOMContentLoaded', setup);
