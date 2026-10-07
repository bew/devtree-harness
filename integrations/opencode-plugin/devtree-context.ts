// OpenCode plugin: inject devtree-wide context.
//
// Walks up from the session directory for a `.devtree-root` marker.
// When found, adds the devtree's shared skills directory and its AGENTS.md
// to the opencode config, so every project under the devtree inherits them.

import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import type { Plugin } from "@opencode-ai/plugin";

const DEVTREE_MARKER = ".devtree-root";

// Walk up from `start` (inclusive) until a dir holding the devtree marker.
// Returns the devtree root path, or null when no ancestor carries the marker.
function findDevtreeRoot(start: string): string | null {
  let dir = start;
  while (true) {
    if (existsSync(join(dir, DEVTREE_MARKER))) return dir;
    const parent = dirname(dir);
    if (parent === dir) return null; // reached the filesystem root
    dir = parent;
  }
}

// Return `list` with `value` appended, unless it is already present.
function appendUnique(list: string[] | undefined, value: string): string[] {
  const current = list ?? [];
  return current.includes(value) ? current : [...current, value];
}

// Plugin that injects the devtree's shared skills dir and AGENTS.md into the
// running config, so any project nested under the devtree inherits them.
export const DevtreeContext: Plugin = async ({ directory }) => {
  return {
    config: async (cfg) => {
      const root = findDevtreeRoot(directory ?? process.cwd());
      if (root === null) return;

      const skillsDir = join(root, ".agents", "skills");
      if (existsSync(skillsDir)) {
        cfg.skills = cfg.skills ?? {};
        cfg.skills.paths = appendUnique(cfg.skills.paths, skillsDir);
      }

      const agentsFile = join(root, "AGENTS.md");
      if (existsSync(agentsFile)) {
        cfg.instructions = appendUnique(cfg.instructions, agentsFile);
      }
    },
  };
};