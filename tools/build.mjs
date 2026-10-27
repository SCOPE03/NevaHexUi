#!/usr/bin/env node
/*
 * NEVAHEXUI build system.
 *
 * Discovers every module under src/, resolves the internal dependency graph from
 * `require("NEVA:<module>")` statements, topologically sorts it (erroring on
 * cycles and unknown modules) and emits:
 *   build/NEVAHEXUI.luau          standalone single-file library
 *   build/NEVAHEXUI.min.lua       comment/whitespace-stripped build (no renaming)
 *   build/nevahexui-tests.luau    test bundle: library + tests + harness
 *   build/build-report.json       module list, sizes and hashes
 *
 * No npm dependencies; runs on any Node 18+.
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import url from 'node:url';

const ROOT = path.resolve(path.dirname(url.fileURLToPath(import.meta.url)), '..');
const SRC = path.join(ROOT, 'src');
const OUT = path.join(ROOT, 'build');
const ENTRY = 'Init';
const REQUIRE = /require\(\s*"NEVA:([^"]+)"\s*\)/g;
const VERSION = '1.0.0';

function walk(dir, base, out) {
	out = out || [];
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) walk(full, base, out);
		else if (entry.name.endsWith('.luau') || entry.name.endsWith('.lua')) out.push(path.relative(base, full).split(path.sep).join('/'));
	}
	return out;
}

function moduleId(rel) {
	return rel.replace(/\.(luau|lua)$/, '');
}

function varname(id) {
	return '__NEVA_' + id.replace(/[^A-Za-z0-9]/g, '_');
}

function collect() {
	const modules = new Map();
	for (const rel of walk(SRC, SRC).sort()) {
		const id = moduleId(rel);
		if (modules.has(id)) throw new Error('NEVAHEXUI build: duplicate module id ' + id);
		const source = fs.readFileSync(path.join(SRC, rel), 'utf8');
		const deps = [];
		for (const match of source.matchAll(REQUIRE)) deps.push(match[1]);
		modules.set(id, { id, rel, source, deps });
	}
	return modules;
}

function topoSort(modules) {
	const state = new Map();
	const order = [];
	function visit(id, chain) {
		const current = state.get(id);
		if (current === 'done') return;
		if (current === 'active') throw new Error('NEVAHEXUI build: circular require ' + chain.concat(id).join(' -> '));
		const mod = modules.get(id);
		if (!mod) throw new Error('NEVAHEXUI build: unknown module "' + id + '" required from ' + chain.join(' -> '));
		state.set(id, 'active');
		for (const dep of mod.deps.slice().sort()) visit(dep, chain.concat(id));
		state.set(id, 'done');
		order.push(mod);
	}
	for (const id of Array.from(modules.keys()).sort()) visit(id, []);
	return order;
}

function moduleChunks(order) {
	const chunks = [];
	for (const mod of order) {
		const body = mod.source.replace(REQUIRE, (match, dep) => varname(dep)).trimEnd();
		if (/\breturn\b/.test(body.split('\n').slice(-3).join('\n')) === false) {
			throw new Error('NEVAHEXUI build: module ' + mod.id + ' does not end with a return statement');
		}
		chunks.push('local ' + varname(mod.id) + ' = (function()\n' + body + '\nend)()\n');
	}
	return chunks;
}

function version(action) {
	let minor = 0;
	try {
		const config = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8'));
		if (config.version) return config.version + (action ? '+' + action : '');
	} catch (error) {
		minor = 0;
	}
	return VERSION + (action ? '+' + action : '');
}

function header(mode) {
	return [
		'--[[',
		'  NEVAHEXUI ' + version(),
		'  Unified Roblox Luau UI framework.',
		'',
		'  Generated file - do not edit. Regenerate with: node tools/build.mjs',
		'  Build mode: ' + mode,
		'  License: MIT (see LICENSE). Third-party notices: THIRD_PARTY_NOTICES.md',
		'',
		'  Usage:',
		'    local NEVAHEXUI = loadstring(game:HttpGet("<hosted url>"))()',
		'    local Window = NEVAHEXUI:CreateWindow({ Name = "Example", Layout = "Sidebar" })',
		'  ]]',
		'',
	].join('\n');
}

function renderLibrary(order) {
	return header('standalone') + moduleChunks(order).join('\n') + '\nreturn ' + varname(ENTRY) + '\n';
}

/* Character-level comment stripper that understands Luau strings and long
 * brackets, so it cannot corrupt string contents or merge tokens. */
function stripComments(source) {
	let out = '';
	let i = 0;
	const n = source.length;
	while (i < n) {
		const ch = source[i];
		if (ch === '[') {
			const longOpen = /^\[(=*)\[/.exec(source.slice(i, i + 20));
			if (longOpen) {
				const close = ']' + longOpen[1] + ']';
				const end = source.indexOf(close, i + longOpen[0].length);
				if (end === -1) { out += source.slice(i); break; }
				out += source.slice(i, end + close.length);
				i = end + close.length;
				continue;
			}
		}
		if (ch === '-' && source[i + 1] === '-') {
			const blockOpen = /^--\[(=*)\[/.exec(source.slice(i, i + 20));
			if (blockOpen) {
				const close = ']' + blockOpen[1] + ']';
				const end = source.indexOf(close, i + blockOpen[0].length);
				i = end === -1 ? n : end + close.length;
				out += ' ';
			} else {
				const newline = source.indexOf('\n', i);
				i = newline === -1 ? n : newline;
			}
			continue;
		}
		if (ch === '"' || ch === "'") {
			out += ch;
			i++;
			while (i < n) {
				const c = source[i];
				if (c === '\\') { out += source.slice(i, i + 2); i += 2; continue; }
				out += c;
				i++;
				if (c === ch) break;
			}
			continue;
		}
		out += ch;
		i++;
	}
	return out;
}

function minify(source) {
	const stripped = stripComments(source);
	const lines = stripped.split('\n').map(line => line.replace(/\s+$/, ''));
	const kept = [];
	let previousBlank = false;
	for (const line of lines) {
		const trimmed = line.replace(/^[ \t]+/, '');
		if (trimmed === '') {
			if (!previousBlank) kept.push('');
			previousBlank = true;
			continue;
		}
		previousBlank = false;
		kept.push(trimmed);
	}
	return kept.join('\n').replace(/\n{3,}/g, '\n\n').trim() + '\n';
}

function renderTests(order) {
	// The harness ends with `return NevaTest` for standalone use; inside the
	// generated bundle that return would sit mid-chunk, so it is stripped. The
	// `local NevaTest` declaration stays in scope for the appended tests.
	const harness = fs.readFileSync(path.join(ROOT, 'tools', 'harness.luau'), 'utf8')
		.replace(/\nreturn\s+NevaTest\s*;?\s*$/, '\n');
	const testsDir = path.join(ROOT, 'tests');
	const tests = fs.existsSync(testsDir)
		? walk(testsDir, testsDir).filter(name => name.endsWith('.test.luau')).sort()
		: [];
	const body = moduleChunks(order).join('\n');
	const parts = [
		'--[[ NEVAHEXUI generated test bundle - do not edit. ]]',
		harness,
		'NEVAHEXUI = (function()',
		body,
		'return ' + varname(ENTRY),
		'end)()',
	];
	for (const rel of tests) {
		parts.push('do');
		parts.push('-- test file: ' + rel);
		parts.push(fs.readFileSync(path.join(testsDir, rel), 'utf8').trimEnd());
		parts.push('end');
	}
	parts.push('NevaTest:runAll()');
	return parts.join('\n') + '\n';
}

function sha(text) {
	return crypto.createHash('sha256').update(text).digest('hex').slice(0, 16);
}

function main() {
	const modules = collect();
	const order = topoSort(modules);
	fs.mkdirSync(OUT, { recursive: true });

	const library = renderLibrary(order);
	const minified = minify(library);
	fs.writeFileSync(path.join(OUT, 'NEVAHEXUI.luau'), library);
	fs.writeFileSync(path.join(OUT, 'NEVAHEXUI.min.lua'), minified);
	const testsSource = renderTests(order);
	fs.writeFileSync(path.join(OUT, 'nevahexui-tests.luau'), testsSource);

	const report = {
		version: version(),
		generatedModules: order.length,
		modules: order.map(mod => ({ id: mod.id, path: 'src/' + mod.rel, bytes: mod.source.length, requires: mod.deps.slice().sort() })),
		outputs: [
			{ file: 'build/NEVAHEXUI.luau', bytes: library.length, hash: sha(library) },
			{ file: 'build/NEVAHEXUI.min.lua', bytes: minified.length, hash: sha(minified) },
			{ file: 'build/nevahexui-tests.luau', bytes: testsSource.length, hash: sha(testsSource) },
		],
	};
	fs.writeFileSync(path.join(OUT, 'build-report.json'), JSON.stringify(report, null, 2) + '\n');

	console.log('NEVAHEXUI build complete');
	console.log('  modules  : ' + order.length);
	console.log('  bundle   : ' + library.length + ' bytes');
	console.log('  minified : ' + minified.length + ' bytes (' + Math.round((1 - minified.length / library.length) * 1000) / 10 + '% smaller)');
	console.log('  tests    : ' + testsSource.length + ' bytes');
}

main();
