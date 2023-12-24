import process from "node:process";
import { BitArray } from "./gleam.mjs";
import { readFileSync } from "node:fs";
import { Buffer } from "node:buffer";

export function read_body_sync(size) {
  const buf = new Uint8Array(size);
  fs.readSync(process.stdin.fd, buf, 0, size);
  return new BitArray(buf);
}

export function read_body_async(size, next) {
  const buffer = new Uint8Array(size);
  let remaining = size;
  let offset = 0;

  const finish = () => {
    process.stdin.removeListener("end", finish);
    process.stdin.removeListener("error", finish);
    process.stdin.removeListener("data", read);
    next(new BitArray(buffer));
  };

  const read = (data) => {
    let chunk = new Uint8Array(data);
    if (remaining < chunk.length) chunk = chunk.slice(0, remaining);
    buffer.set(chunk, offset);
    offset += chunk.length;
    remaining -= chunk.length;
    if (remaining <= 0) finish();
  };

  process.stdin.on("end", finish);
  process.stdin.on("error", finish);
  process.stdin.on("data", read);
}
