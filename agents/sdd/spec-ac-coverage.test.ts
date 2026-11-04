import { describe, expect, it } from "bun:test";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const repoRoot = join(import.meta.dir, "..");
const specsDir = join(repoRoot, "specs");
const skipped = new Set(["node_modules", ".git", ".wrangler"]);
const testFile = /\.test\.(?:ts|tsx|js|mjs)$/;
const named = /`([^`\s]+\.(?:test|spec)\.(?:ts|tsx|js|mjs))`|`([^`\s]+\/)`/g;
const criterion = /^- \[( |x|X)\]\s*(AC\d+):/gm;
const testName = /\b(?:it|test)\((['"`])((?:(?!\1).)*)\1/g;

function walk(dir: string, found: string[] = []): string[] {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!skipped.has(entry.name)) walk(join(dir, entry.name), found);
    } else if (testFile.test(entry.name)) {
      found.push(join(dir, entry.name));
    }
  }
  return found;
}

function section(text: string, heading: string): string {
  return text.split(/^## /m).find((part) => part.startsWith(`${heading}\n`)) ?? "";
}

const contents = new Map(
  [...walk(join(repoRoot, "src")), ...walk(join(repoRoot, "test"))].map((file) => [
    file.slice(repoRoot.length + 1),
    readFileSync(file, "utf8"),
  ]),
);
const paths = [...contents.keys()];

function covered(text: string): Set<string> {
  const ids = new Set<string>();
  for (const match of text.matchAll(testName)) {
    for (const id of (match[2] ?? "").matchAll(/\bAC(\d+)\b/g)) ids.add(`AC${id[1]}`);
  }
  return ids;
}

const covers = new Map(paths.map((path) => [path, covered(contents.get(path)!)]));

function resolve(entry: string): string[] {
  if (contents.has(entry)) return [entry];
  if (entry.endsWith("/")) return paths.filter((path) => path.startsWith(entry));
  return paths.filter((path) => path.endsWith(`/${entry}`));
}

const specs = readdirSync(specsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory() && entry.name !== "templates")
  .map((entry) => `${entry.name}/spec.md`)
  .map((name) => {
    const text = readFileSync(join(specsDir, name), "utf8");
    const status = /^Status:\s*(\S+)\s*$/m.exec(text)?.[1];
    return {
      file: `specs/${name}`,
      status,
      criteria: [...section(text, "Acceptance criteria").matchAll(criterion)].map((match) => ({
        id: match[2]!,
        ticked: match[1]!.toLowerCase() === "x",
      })),
      names: [...section(text, "Validation").matchAll(named)].map((match) => (match[1] ?? match[2])!),
    };
  })
  .filter((spec) => spec.status !== undefined);

const done = specs.filter((spec) => spec.status === "done");

describe("Spec acceptance criteria", () => {
  it("knows each status", () => {
    expect(
      specs.map((spec) => spec.status!).filter((s) => !["draft", "approved", "done", "superseded"].includes(s)),
    ).toEqual([]);
  });

  for (const spec of done) {
    it(`${spec.file} ticks every acceptance criterion`, () => {
      expect(spec.criteria.length).toBeGreaterThan(0);
      expect(spec.criteria.filter((item) => !item.ticked).map((item) => item.id)).toEqual([]);
    });

    it(`${spec.file} names test files that exist`, () => {
      const missing = spec.names.filter((entry) => testFile.test(entry) && resolve(entry).length === 0);
      expect(missing).toEqual([]);
    });

    it(`${spec.file} names a test for every acceptance criterion`, () => {
      const listed = spec.names.flatMap((entry) => resolve(entry));
      expect(listed.length).toBeGreaterThan(0);
      const missing = spec.criteria.filter((item) => !listed.some((path) => covers.get(path)?.has(item.id)));
      expect(missing.map((item) => item.id)).toEqual([]);
    });
  }
});
