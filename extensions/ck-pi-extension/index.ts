/**
 * ck-pi-extension — Pi extension wrapping ck semantic code search CLI.
 *
 * Provides tools:
 *   ck_semantic — semantic/concept search (--sem)
 *   ck_hybrid — balanced precision+recall (--hybrid, requires index)
 *   ck_index — manage index (build, status, clean)
 *
 * Only semantic tools — regex/lexical covered by fff extension.
 */

import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

function runCk(args: string[], cwd: string): { output: string; error: boolean } {
  try {
    const result = execSync(`ck ${args.join(" ")}`, {
      cwd,
      encoding: "utf-8",
      timeout: 30000,
      maxBuffer: 1024 * 1024 * 5,
    });
    return { output: result.trim(), error: false };
  } catch (e: any) {
    const stderr = e.stderr?.toString().trim() ?? "";
    const stdout = e.stdout?.toString().trim() ?? "";
    return { output: stderr || stdout || e.message, error: true };
  }
}

function quote(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`;
}

// --- Tools ---

const ckSemantic = defineTool({
  name: "ck_semantic",
  label: "ck semantic search",
  description:
    "Search code by concept/intent using embeddings. Best for finding behavior, patterns, logic — e.g. 'retry logic', 'input validation', 'error handling'. Requires index (auto-builds on first use).",
  promptSnippet: "Semantic concept search — find code by meaning/intent (e.g. 'retry logic')",
  promptGuidelines: [
    "Use ck_semantic when searching for concepts, behavior, or intent rather than exact text.",
    "Adjust threshold: higher (0.7-0.9) = more precise, lower (0.3-0.5) = more results.",
  ],
  parameters: Type.Object({
    query: Type.String({ description: "Natural language concept to search for" }),
    path: Type.String({ description: "Directory to search in", default: "." }),
    threshold: Type.Optional(
      Type.Number({ description: "Similarity threshold 0.0-1.0 (default 0.6)", minimum: 0, maximum: 1 })
    ),
    limit: Type.Optional(Type.Number({ description: "Max results to return", minimum: 1 })),
    rerank: Type.Optional(Type.Boolean({ description: "Enable reranking for better precision" })),
  }),
  async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
    const cwd = ctx.cwd;
    const searchPath = params.path || ".";
    const args: string[] = ["--jsonl", "--sem"];
    if (params.threshold !== undefined) args.push("--threshold", String(params.threshold));
    if (params.limit !== undefined) args.push("--limit", String(params.limit));
    if (params.rerank) args.push("--rerank");
    args.push(quote(params.query), searchPath);
    const result = runCk(args, cwd);
    return {
      content: [{ type: "text", text: result.output || "No results found." }],
      details: { mode: "semantic", query: params.query, path: searchPath },
      isError: result.error,
    };
  },
});

const ckHybrid = defineTool({
  name: "ck_hybrid",
  label: "ck hybrid search",
  description:
    "Combined semantic + lexical search using RRF. Balances precision and recall. Requires index. Threshold range: 0.01-0.05.",
  promptSnippet: "Hybrid semantic+lexical search for balanced results (requires index)",
  promptGuidelines: [
    "Use ck_hybrid when unsure between semantic and lexical — combines both. Threshold range 0.01-0.05.",
  ],
  parameters: Type.Object({
    query: Type.String({ description: "Search query" }),
    path: Type.String({ description: "Directory to search in", default: "." }),
    threshold: Type.Optional(
      Type.Number({ description: "RRF threshold (default ~0.03, range 0.01-0.05)", minimum: 0, maximum: 1 })
    ),
    limit: Type.Optional(Type.Number({ description: "Max results to return", minimum: 1 })),
  }),
  async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
    const cwd = ctx.cwd;
    const searchPath = params.path || ".";
    const args: string[] = ["--jsonl", "--hybrid"];
    if (params.threshold !== undefined) args.push("--threshold", String(params.threshold));
    if (params.limit !== undefined) args.push("--limit", String(params.limit));
    args.push(quote(params.query), searchPath);
    const result = runCk(args, cwd);
    return {
      content: [{ type: "text", text: result.output || "No results found." }],
      details: { mode: "hybrid", query: params.query, path: searchPath },
      isError: result.error,
    };
  },
});

const ckIndex = defineTool({
  name: "ck_index",
  label: "ck index management",
  description:
    "Manage ck search index. Actions: 'build' creates/updates index, 'status' checks index state, 'clean' removes index. Index required for lexical and hybrid search.",
  promptSnippet: "Build, check, or clean the ck search index",
  promptGuidelines: [
    "Run ck_index with action 'build' before using ck_lexical or ck_hybrid.",
    "Use ck_index 'status' to check if index exists before lexical/hybrid search.",
  ],
  parameters: Type.Object({
    action: Type.Union([Type.Literal("build"), Type.Literal("status"), Type.Literal("clean")], {
      description: "Index action: build, status, or clean",
    }),
    path: Type.String({ description: "Directory to index", default: "." }),
  }),
  async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
    const cwd = ctx.cwd;
    const searchPath = params.path || ".";
    const flagMap = { build: "--index", status: "--status", clean: "--clean" };
    const flag = flagMap[params.action];
    const result = runCk([flag, searchPath], cwd);
    return {
      content: [{ type: "text", text: result.output || `Index ${params.action} complete.` }],
      details: { action: params.action, path: searchPath },
      isError: result.error,
    };
  },
});

// --- Extension entry ---

export default function (pi: ExtensionAPI) {
  pi.registerTool(ckSemantic);
  pi.registerTool(ckHybrid);
  pi.registerTool(ckIndex);
}
