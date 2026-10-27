// Browser equivalent of patcher.py: apply the patch to the user's own copy
// of Waldorf's update, entirely on their computer.
const MAX_UPDATE_BYTES = 1000000;
const ERASED = 0xff;
// Waldorf's update file: a Standard MIDI File of System Exclusive packets.
const WALDORF_ID = 0x3e, MW2_ID = 0x0e, BROADCAST_ID = 0x7f, UPDATE_COMMAND = 0x71;
const SYSEX = 0xf0, SYSEX_END = 0xf7, META = 0xff;
const PACKET_BYTES = 261;            // SysEx payload of one update packet
const PACKET_HEADER_BYTES = 9;       // ID, device, broadcast, command, group count, counter, tag
const PACKET_DECODED_BYTES = 200;
const MAX_OS_PACKETS = Math.floor(0x20000 / PACKET_DECODED_BYTES);  // the 128 KiB OS bank
const PACKET_DELTA = 24;             // ticks before each stock packet
const PACKET_LENGTH_VLQ = [0x82, 0x05];  // 261 as an SMF variable-length quantity
const MAIN_PREFIX = [0xc0, 0xde, 0x00, 0x00];
// Four decoded bytes in five MIDI-safe bytes. The first holds the four low
// bits and, in bits 4..6, the rolling group number the update loader checks.
const GROUP_BYTES = 4, ENCODED_GROUP_BYTES = 5;
const GROUP_SEQUENCE_MASK = 0x07, GROUP_SEQUENCE_SHIFT = 4;
const SYSTEM_DATA_BYTES = {0xf1: 1, 0xf2: 2, 0xf3: 1, 0xf6: 0, 0xf8: 0, 0xf9: 0, 0xfa: 0, 0xfb: 0, 0xfc: 0, 0xfd: 0, 0xfe: 0};

function require(condition, message) {
  if (!condition) throw new Error(message);
}
function fields(object, names, optional = '') {
  if (object === null || typeof object !== 'object' || Array.isArray(object)) return false;
  const allowed = new Set([...names.split(','), ...optional.split(',').filter(Boolean)]);
  return names.split(',').every(name => name in object) && Object.keys(object).every(key => allowed.has(key));
}
function number(value) {
  if (Number.isInteger(value)) return value;
  require(typeof value === 'string' && /^0x[0-9a-f]+$/i.test(value), 'Invalid number in patch.');
  return parseInt(value, 16);
}
function fromHex(text) {
  require(typeof text === 'string' && /^(?:[0-9a-f]{2})*$/.test(text), 'Invalid data in patch.');
  return Uint8Array.from(text.match(/../g) ?? [], pair => parseInt(pair, 16));
}
const toHex = bytes => Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('');
export async function sha256(bytes) {
  return toHex(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)));
}
const NOT_AN_UPDATE = 'This file is not a Waldorf Microwave II/XT/XTk update.';
const u32 = (data, at) => {
  require(at + 4 <= data.length, NOT_AN_UPDATE);
  return new DataView(data.buffer, data.byteOffset).getUint32(at);
};
function vlq(data, at, limit) {
  let value = 0;
  for (let n = 0; n < 4; n++) {
    require(at < limit, NOT_AN_UPDATE);
    const byte = data[at++];
    value = (value << 7) | (byte & 0x7f);
    if (!(byte & 0x80)) return [value, at];
  }
  throw new Error(NOT_AN_UPDATE);
}
const sum7 = bytes => bytes.reduce((total, byte) => total + byte, 0) & 0x7f;

// Every System Exclusive event in the file, with its payload's file offset.
function sysexEvents(data) {
  require(String.fromCharCode(...data.subarray(0, 4)) === 'MThd', NOT_AN_UPDATE);
  const events = [];
  let offset = 8 + u32(data, 4);
  while (offset < data.length) {
    const id = String.fromCharCode(...data.subarray(offset, offset + 4));
    const start = offset + 8, end = start + u32(data, offset + 4);
    require(end <= data.length, NOT_AN_UPDATE);
    offset = end;
    if (id !== 'MTrk') continue;
    let at = start, running = null;
    while (at < end) {
      [, at] = vlq(data, at, end);
      require(at < end, NOT_AN_UPDATE);
      let status;
      if (data[at] & 0x80) status = data[at++];
      else { require(running !== null, NOT_AN_UPDATE); status = running; }
      if (status < SYSEX) {
        running = status;
        at += status >> 4 === 0xc || status >> 4 === 0xd ? 1 : 2;
        continue;
      }
      running = null;
      if (status === SYSEX || status === SYSEX_END) {
        let size;
        [size, at] = vlq(data, at, end);
        require(at + size <= end, NOT_AN_UPDATE);
        events.push({track: start - 8, status, offset: at, payload: data.subarray(at, at + size)});
        at += size;
      } else if (status === META) {
        let size;
        [size, at] = vlq(data, at + 1, end);
        at += size;
      } else {
        require(status in SYSTEM_DATA_BYTES, NOT_AN_UPDATE);
        at += SYSTEM_DATA_BYTES[status];
      }
      require(at <= end, NOT_AN_UPDATE);
    }
  }
  return events;
}

function decodeBlock(encoded) {
  const decoded = new Uint8Array(encoded.length / ENCODED_GROUP_BYTES * GROUP_BYTES);
  for (let group = 0, at = 0; at < encoded.length; group++, at += ENCODED_GROUP_BYTES) {
    for (let n = 0; n < GROUP_BYTES; n++) {
      const high = encoded[at + 1 + n];
      require(!(high & 0x80), NOT_AN_UPDATE);
      decoded[group * GROUP_BYTES + n] = (high << 1) | ((encoded[at] >> n) & 1);
    }
  }
  return decoded;
}

function encodeBlock(decoded, firstGroup) {
  const encoded = new Uint8Array(decoded.length / GROUP_BYTES * ENCODED_GROUP_BYTES);
  for (let group = 0; group * GROUP_BYTES < decoded.length; group++) {
    const bytes = decoded.subarray(group * GROUP_BYTES, (group + 1) * GROUP_BYTES);
    let low = 0;
    bytes.forEach((byte, bit) => { low |= (byte & 1) << bit; });
    encoded[group * ENCODED_GROUP_BYTES] = low | ((firstGroup + group) & GROUP_SEQUENCE_MASK) << GROUP_SEQUENCE_SHIFT;
    bytes.forEach((byte, n) => { encoded[group * ENCODED_GROUP_BYTES + 1 + n] = byte >> 1; });
  }
  return encoded;
}

// The update's packet groups; the OS is the one whose data starts with MAIN_PREFIX.
function mainGroup(data) {
  const groups = [];
  for (const event of sysexEvents(data)) {
    const p = event.payload;
    if (event.status !== SYSEX || p.length < 4 || p[0] !== WALDORF_ID || p[1] !== MW2_ID ||
        p[2] !== BROADCAST_ID || p[3] !== UPDATE_COMMAND) continue;
    require(p.length === PACKET_BYTES && p[p.length - 1] === SYSEX_END, NOT_AN_UPDATE);
    const encodedEnd = PACKET_HEADER_BYTES + p[4] * ENCODED_GROUP_BYTES;
    require(encodedEnd + 2 === p.length, NOT_AN_UPDATE);
    const encoded = p.subarray(PACKET_HEADER_BYTES, encodedEnd);
    require(p[encodedEnd] === sum7(encoded), NOT_AN_UPDATE);
    const counter = (p[5] << 7) | p[6], tag = (p[7] << 7) | p[8];
    if (counter === 1) groups.push({tag, packets: []});
    const group = groups.at(-1);
    require(group && counter === group.packets.length + 1 && tag === group.tag, NOT_AN_UPDATE);
    group.packets.push({event, decoded: decodeBlock(encoded)});
  }
  const main = groups.filter(group => MAIN_PREFIX.every((byte, n) => group.packets[0].decoded[n] === byte));
  require(main.length === 1, NOT_AN_UPDATE);
  const overlay = new Uint8Array(main[0].packets.reduce((size, packet) => size + packet.decoded.length, 0));
  let at = 0;
  for (const packet of main[0].packets) { overlay.set(packet.decoded, at); at += packet.decoded.length; }
  return {packets: main[0].packets, overlay};
}

// Waldorf's update with its OS packets carrying `overlay`, and packets added
// after the last one for the bytes past the stock OS.
function repack(update, overlay) {
  const {packets, overlay: stock} = mainGroup(update);
  require(overlay.length % PACKET_DECODED_BYTES === 0 && overlay.length >= stock.length, 'Invalid patched overlay.');
  const count = overlay.length / PACKET_DECODED_BYTES;
  require(count <= MAX_OS_PACKETS, 'The patched OS does not fit the OS bank.');
  const tag = [(count >> 7) & 0x7f, count & 0x7f];
  const output = update.slice();
  let cursor = 0;
  for (const {event, decoded} of packets) {
    const encoded = encodeBlock(overlay.subarray(cursor, cursor + decoded.length), cursor / GROUP_BYTES);
    cursor += decoded.length;
    output.set(tag, event.offset + 7);
    output.set(encoded, event.offset + PACKET_HEADER_BYTES);
    output[event.offset + PACKET_HEADER_BYTES + encoded.length] = sum7(encoded);
  }
  const last = packets.at(-1).event;
  const added = [];
  for (let counter = packets.length + 1; counter <= count; counter++) {
    const encoded = encodeBlock(overlay.subarray(cursor, cursor + PACKET_DECODED_BYTES), cursor / GROUP_BYTES);
    cursor += PACKET_DECODED_BYTES;
    added.push(PACKET_DELTA, SYSEX, ...PACKET_LENGTH_VLQ,
      WALDORF_ID, MW2_ID, BROADCAST_ID, UPDATE_COMMAND, encoded.length / ENCODED_GROUP_BYTES,
      (counter >> 7) & 0x7f, counter & 0x7f, ...tag, ...encoded, sum7(encoded), SYSEX_END);
  }
  const insert = last.offset + last.payload.length;
  const result = new Uint8Array(output.length + added.length);
  result.set(output.subarray(0, insert));
  result.set(added, insert);
  result.set(output.subarray(insert), insert + added.length);
  // The track holding the packets grows by what was added.
  const sizeAt = last.track + 4;
  new DataView(result.buffer).setUint32(sizeAt, u32(output, sizeAt) + added.length);
  const check = mainGroup(result).overlay;
  require(check.length === overlay.length && check.every((byte, n) => byte === overlay[n]), 'The patched update failed verification.');
  return result;
}

// Check a patch against the layout: its hunks are exactly the listed
// ranges, and the extension lies in the extension region.
export function decodePatch(bundle) {
  require(fields(bundle, 'patch,layout'), 'Invalid patch bundle.');
  const {patch, layout} = bundle;
  require(fields(patch, 'format,base_sha256,hunks,extension', 'result') && patch.format === 1 &&
    patch.base_sha256 === layout.firmware.overlay_sha256, 'Unsupported patch.');
  require(Array.isArray(patch.hunks) && patch.hunks.length === layout.hunks.length, 'Invalid patch hunk count.');
  const hunks = patch.hunks.map((hunk, index) => {
    require(fields(hunk, 'address,data'), 'Invalid patch hunk.');
    const data = fromHex(hunk.data), wanted = layout.hunks[index];
    require(number(hunk.address) === number(wanted.address) && data.length === number(wanted.bytes),
      'Patch hunk differs from the layout.');
    return {address: number(hunk.address), data};
  });
  require(fields(patch.extension, 'address,data'), 'Invalid patch extension.');
  const start = number(layout.extension.start), end = number(layout.extension.end);
  const extension = fromHex(patch.extension.data);
  require(number(patch.extension.address) === start && extension.length > 0 && start + extension.length <= end + 1,
    'Patch extension escapes its region.');
  require(patch.result === undefined || fields(patch.result, 'overlay_sha256,update_sha256'), 'Invalid patch result.');
  return {hunks, extension: {start, data: extension}, result: patch.result};
}

// Returns the patched OS overlay and the patched update MIDI file.
export async function patchFirmware(file, bundle) {
  const {layout} = bundle;
  const patch = decodePatch(bundle);
  require(file.length <= MAX_UPDATE_BYTES, NOT_AN_UPDATE);
  const wrong = `Choose Waldorf’s unmodified OS v${layout.firmware.version} update, ${layout.firmware.update_name}.`;
  let stock;
  try { stock = mainGroup(file).overlay; } catch { throw new Error(wrong); }
  require(await sha256(stock) === layout.firmware.overlay_sha256, wrong);
  const base = number(layout.firmware.base_address), end = number(layout.extension.end);
  const overlay = new Uint8Array(end + 1 - base).fill(ERASED);
  overlay.set(stock);
  for (const {address, data} of patch.hunks) overlay.set(data, address - base);
  overlay.set(patch.extension.data, patch.extension.start - base);
  const update = repack(file, overlay);
  if (patch.result) {
    require(patch.result.overlay_sha256 === await sha256(overlay) && patch.result.update_sha256 === await sha256(update),
      'The patched file failed verification.');
  }
  return {overlay, update, name: layout.firmware.update_name.replace(/\.mid$/, '_tallent.mid')};
}
