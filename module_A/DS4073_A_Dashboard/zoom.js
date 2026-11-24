document.addEventListener("click", function (event) {
  const trigger = event.target.closest(".a-zoom");
  if (!trigger) return;
  const source = trigger.querySelector("img");
  let dialog = document.querySelector(".a-zoom-dialog");
  if (!dialog) {
    dialog = document.createElement("dialog");
    dialog.className = "a-zoom-dialog";
    dialog.setAttribute("aria-label", "Enlarged chart");
    const form = document.createElement("form");
    form.method = "dialog";
    const close = document.createElement("button");
    close.textContent = "Close";
    form.appendChild(close);
    dialog.append(form, document.createElement("img"));
    document.body.appendChild(dialog);
  }
  const preview = dialog.querySelector("img");
  preview.src = source.currentSrc || source.src;
  preview.alt = source.alt;
  dialog.showModal();
});
