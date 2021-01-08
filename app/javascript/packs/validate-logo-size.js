document.getElementById("service_provider_logo_file").addEventListener("change", (e) => {
  // Clear the error div
  var errorDiv = document.getElementById("logo-upload-error");
  errorDiv.textContent = "";

  // See https://stackoverflow.com/a/3717847
  if (!window.FileReader) {
    console.log("The file API isn't supported on this browser yet.");
    return;
  }

  if (!e.target.files) {
    console.error("This browser doesn't seem to support the `files` property of file inputs.");
  } else if (!e.target.files[0]) {
    console.log("No file attached.");
  } else {
    var file = e.target.files[0];

    if (file.size > (1024 * 1024)) { // file.size returns bytes
      errorDiv.textContent = "ERROR: Logo must not be larger than 1MB.";
    }
  }
});
