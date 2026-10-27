// patchFirmware is embedded alongside this UI when packaged.

const input = document.querySelector('#firmware');
const status = document.querySelector('#status');
const download = document.querySelector('#download');
const MAX_PICK_BYTES = 1000000;
let outputUrl;

input.addEventListener('change', async () => {
  const file = input.files[0];
  if (!file) return;
  input.disabled = true;
  download.hidden = true;
  download.removeAttribute('href');
  if (outputUrl) URL.revokeObjectURL(outputUrl);
  status.textContent = 'Checking update…';
  status.dataset.error = 'false';
  try {
    if (!globalThis.crypto?.subtle) throw new Error('Use a current browser, or open the hosted patcher over HTTPS.');
    if (file.size > MAX_PICK_BYTES) throw new Error('Choose Waldorf’s OS v2.33 update, mw2_xt_xtk_sys_v233.mid.');
    const bundle = JSON.parse(document.querySelector('#firmware-data').textContent);
    const result = await patchFirmware(new Uint8Array(await file.arrayBuffer()), bundle);
    outputUrl = URL.createObjectURL(new Blob([result.update], {type: 'audio/midi'}));
    download.href = outputUrl;
    download.download = result.name;
    download.hidden = false;
    download.click();
    status.textContent = `Your update is ready. Send ${result.name} to the XT the way Waldorf’s update is sent.`;
  } catch (error) {
    status.dataset.error = 'true';
    status.textContent = error instanceof Error ? error.message : 'Could not prepare the update. Please try again.';
  } finally {
    input.disabled = false;
    input.value = '';
  }
});
