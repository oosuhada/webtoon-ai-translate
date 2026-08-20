import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

test("dashboard identifies the implemented translation-project surface", async () => {
  const source = await readFile(new URL("../app/dashboard/page.tsx", import.meta.url), "utf8");

  assert.match(source, /AI Losy/);
  assert.match(source, /번역 프로젝트/);
});

test("middleware protects project workspaces", async () => {
  const source = await readFile(new URL("../middleware.ts", import.meta.url), "utf8");

  assert.match(source, /\/dashboard/);
  assert.match(source, /access_token/);
  assert.match(source, /\/login/);
});
