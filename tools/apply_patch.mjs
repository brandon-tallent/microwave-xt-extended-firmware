// Apply a patch with the browser patcher under Node, as the page does:
// node tools/apply_patch.mjs UPDATE PATCH [OUTPUT]
// Prints the SHA-256 of the patched OS and update file as JSON.
import {readFileSync, writeFileSync} from 'node:fs';
import {patchFirmware, sha256} from '../web/patcher.mjs';

const [update, patch, output] = process.argv.slice(2);
const layout = new URL('../src/patch_layout.json', import.meta.url);
try {
  const result = await patchFirmware(new Uint8Array(readFileSync(update)),
    {patch: JSON.parse(readFileSync(patch)), layout: JSON.parse(readFileSync(layout))});
  if (output) writeFileSync(output, result.update, {flag: 'wx'});
  console.log(JSON.stringify({overlay_sha256: await sha256(result.overlay), update_sha256: await sha256(result.update)}));
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
