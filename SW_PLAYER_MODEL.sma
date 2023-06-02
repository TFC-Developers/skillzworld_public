#include "include/global"                       // Include file for general functions
#include <engine>
#include <fakemeta>
#include "include/utils"                        // Include file for utility functions
#include <amxmisc>

new DEBUG_MODELS[][] = {
	"Werewolf", "bender", "biker",
	"blackcat", "blossom", "boris", "bugs_recon", "ccsakura", "crash",
	"darth_vader", "domokun_r", "doomguy", "dukenukem", "eva", "farseer",
	"flanders", "gaben", "jason", "kate", "kermit_r", "mario",
	"mountie", "necromancer", "panther_r", "partybear", "penguin",
	"polarbear", "ribbon", "s3xeyc0ncer", "santa", "selene", "skatergoofy",
	"skatermax", "smoke", "striker", "sw_alien", "truth", "yoda",
}
const PRECACHE_MAX = 10
const NAME_SIZE = 0x20
const AUTHID_SIZE = 0x20
const DAY = 60*60*24
const MONTH = 60*60*24*30
enum eModelInfo {
	mMI_iSkins,
	mMI_iParts,
	mMI_iCacheID,
	mMI_iUsers,
}
enum eBumpEntry {
	mBE_iTimestamp,
	mBE_iExtra,
	mBE_szName[NAME_SIZE], // The name field must be last
}

// Loaded model indices: Maps model names to indices into loaded_model_infos, to avoid having to search through that array.
new Trie:loaded_model_indices = Invalid_Trie

// Loaded model infos: Stores detailed information about a model, names to use, skin and body part choices.
new Array:loaded_model_infos = Invalid_Array

// An authid trie records a player's connection so that they can 
new Trie:loaded_authids = Invalid_Trie // Authid points to model name
new Trie:disconnected_authids = Invalid_Trie // Authid points to model name

new g_fileBumps
new bool:g_fileBumpsIsOpen = false

new Array:g_aBumps = Invalid_Array
enum { // Values for mBE_iExtra
	mBX_OneDay = 1
}

new g_fwPre_SetClientKeyValue
public plugin_init() {
	RegisterPlugin
	register_clcmd "sw_model", "cmd_model"
	g_fwPre_SetClientKeyValue = register_forward(FM_SetClientKeyValue, "fwPre_SetClientKeyValue")
}
public fwPre_SetClientKeyValue(id, const info[], const key[], const value[]) {
	return equal(key, "model") ? FMRES_SUPERCEDE : FMRES_IGNORED
}

/*
// TODO: Check connecting players' model choices, add them to 
public client_authorized(id, const authid[]) {
	console_print 0, "This freaker joined bro: %d, %s", id, authid
}
*/

// Precache bumping rules are:
// Newest/highest models in the queue list are most important, and get preferential treatment when precaching.
// The lowest in the list are least important and are less likely to be precached.
// A player can request a model to bump it to the top.
//   This bump has a short lifespan; unless later bumped by entering or leaving with it, it will be unbumped in a day.
// A player can enter the server with a model to bump it.
//   If their model wasn't precached, the model they wanted to have is bumped.
// A player can exit the server with a model to bump it.
//
// A model is unbumped if it's a month old. Sooner if the extras field says so.
//
// A model name in the bump system should always be lowercase, otherwise trie membership testing will fail.

stock bumps_open() {
	static szBumpsFP[0x100]; new iOffset = get_configsdir(szBumpsFP, charsmax(szBumpsFP))
	copy szBumpsFP[iOffset], charsmax(szBumpsFP) - iOffset, "/bumps.bin"
	console_print 0, "Opening bumps file: \"%s\"", szBumpsFP
	g_fileBumps = file_exists(szBumpsFP) ? fopen(szBumpsFP, "r+") : fopen(szBumpsFP, "w+")
	g_fileBumpsIsOpen = true
}
stock bumps_close() {
	fclose g_fileBumps
	g_fileBumpsIsOpen = false
}
stock Array:bumps_as_array() {
	if (!g_fileBumpsIsOpen) bumps_open
	fseek g_fileBumps, 0, SEEK_SET
	new entries_n
	new read_n = fread(g_fileBumps, entries_n, BLOCK_INT)
	if (read_n != BLOCK_INT) entries_n = 0 // File is too short to make sense, avoid risk of garbage memory read
	console_print 0, "Bumps amount: %d", entries_n
	new Array:arr = ArrayCreate(eBumpEntry, .reserved = entries_n + 10)
	static entry[eBumpEntry]
	for (new i; i < entries_n; i++) {
		fread_blocks g_fileBumps, entry, mBE_szName, BLOCK_INT // Read all int fields before the name
		fread_blocks g_fileBumps, entry[mBE_szName], NAME_SIZE, BLOCK_CHAR // Read the name
		ArrayPushArray arr, entry, eBumpEntry
	}
	bumps_close
	return arr
}
stock bumps_from_array(Array:arr) {
	if (!g_fileBumpsIsOpen) bumps_open
	new entries_n = ArraySize(arr)
	fseek g_fileBumps, 0, SEEK_SET
	console_print 0, "Write ftell: %d", ftell(g_fileBumps)
	fwrite g_fileBumps, entries_n, BLOCK_INT
	static entry[eBumpEntry]
	for (new i; i < entries_n; i++) {
		ArrayGetArray arr, i, entry, eBumpEntry
		fwrite_blocks g_fileBumps, entry, mBE_szName, BLOCK_INT
		fwrite_blocks g_fileBumps, entry[mBE_szName], NAME_SIZE, BLOCK_CHAR
	}
	bumps_close
}
stock bumps_from_trieiter(TrieIter:trie) {
	if (!g_fileBumpsIsOpen) bumps_open
	new entries_n = TrieIterGetSize(trie)
	fseek g_fileBumps, 0, SEEK_SET
	console_print 0, "Write ftell: %d", ftell(g_fileBumps)
	fwrite g_fileBumps, entries_n, BLOCK_INT
	static entry[eBumpEntry]
	while (TrieIterGetArray(trie, entry, mBE_szName)) {
		TrieIterGetKey trie, entry[mBE_szName], charsmax(entry[mBE_szName])
		fwrite_blocks g_fileBumps, entry, mBE_szName, BLOCK_INT
		fwrite_blocks g_fileBumps, entry[mBE_szName], NAME_SIZE, BLOCK_CHAR
		TrieIterNext trie
	}
	bumps_close
}
stock sort_bump_entries_by_timestamp(Array:arr, a[eBumpEntry], b[eBumpEntry]) {
	// Use with ArraySortEx https://www.amxmodx.org/api/cellarray/ArraySortEx
	// Elements with the highest timestamp are last in the sorted array.
	// That way, elements can be read and deleted from the array in one swoop without risking index invalidation.
	return a[mBE_iTimestamp] >= b[mBE_iTimestamp] ? a[mBE_iTimestamp] == b[mBE_iTimestamp] ? 0 : 1 : -1
}

public plugin_precache() {
	disconnected_authids = TrieCreate()
	loaded_authids = TrieCreate()
	
	new timestamp = get_systime()
	
	loaded_model_infos = ArrayCreate(eModelInfo)
	loaded_model_indices = TrieCreate()
	
	g_aBumps = bumps_as_array()
	ArraySortEx g_aBumps, "sort_bump_entries_by_timestamp" // Highest timestamp are last
	new entries_n = ArraySize(g_aBumps)
	static entry[eBumpEntry]
	static diff
	new precache_i = 0
	for (new i = entries_n - 1; i > -1 && precache_i < PRECACHE_MAX; i--) {
		console_print 0, "##### Dynamic precache: Checking if loaded bump %d is worthy", i
		// Iterate in reverse order because elements can be deleted and read without invalidating loop indices
		ArrayGetArray g_aBumps, i, entry, eBumpEntry
		diff = timestamp - entry[mBE_iTimestamp]
		if (	entry[mBE_iExtra] == mBX_OneDay && diff > DAY ||
			diff > MONTH
		) {
			ArrayDeleteItem g_aBumps, i
			console_print 0, "##### It wasn't"
			continue
		}
		precache_player_model entry[mBE_szName]
		precache_i++
	}
	bumps_from_array g_aBumps
	// Fill in the remaining precache slots, do not bump them
	
	/*
	for (; precache_i < PRECACHE_MAX; precache_i++) {
		if (precache_i >= sizeof DEBUG_MODELS) break
		precache_player_model DEBUG_MODELS[precache_i]
	}
	*/
}
stock precache_player_model(name[]) {
	static model_path[NAME_SIZE*2 + 20]
	new this_model_info[eModelInfo]
	formatex model_path, charsmax(model_path), "models/player/%s/%s.mdl", name, name
	this_model_info[mMI_iCacheID] = precache_model(model_path)
	TrieSetCell loaded_model_indices, name, ArraySize(loaded_model_infos)
	ArrayPushArray loaded_model_infos, this_model_info
	console_print 0, "Precached model \"%s\" brother", name
}



public cmd_model(id, level, cid) {
	static model[NAME_SIZE]; read_argv 1, model, charsmax(model)
	strtolower model
	apply_model_name id, model, read_argv_int(2), read_argv_int(3)
}
stock get_model_name(const model_path[], model_name[], name_sz = sizeof model_name) { // "models/player/daffy/daffy.mdl" -> "daffy"
	name_sz -= 1 // As charsmax
	static const MODEL_PATH_PREFIX[] = "models/player/"
	if (!equali(model_path, MODEL_PATH_PREFIX, charsmax(MODEL_PATH_PREFIX))) return
	new name_i
	for (new path_i = charsmax(MODEL_PATH_PREFIX); model_path[path_i] != '/' && model_path[path_i] && name_i < name_sz; ) {
		model_name[name_i++] = model_path[path_i++]
	}
	model_name[name_i] = EOS
}
stock apply_model_name(id, model[], skin = 0, body = 0) {
	static pmodel_i
	if (!TrieGetCell(loaded_model_indices, model, pmodel_i)) {
		console_print 0, "Tried to apply non-precached model \"%s\" on player %d", model, id
		return
	}
	DispatchKeyValue id, "replacement_model", model
	set_pev id, pev_skin, skin
	set_pev id, pev_body, body
	engfunc EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model
	console_print id, "Loaded model \"%s\"", model
}

public plugin_end() {
	unregister_forward FM_SetClientKeyValue, g_fwPre_SetClientKeyValue
	
	// Merge disconnected_authids into loaded_authids
	// disconnected_authids becomes useless after, so free it.
	static name[NAME_SIZE]
	static authid[AUTHID_SIZE]
	new TrieIter:iter_disconnected_authids = TrieIterCreate(disconnected_authids)
	while (TrieIterGetString(iter_disconnected_authids, name, charsmax(name))) {
		TrieIterGetKey iter_disconnected_authids, authid, charsmax(authid)
		TrieSetString loaded_authids, authid, name
		TrieIterNext iter_disconnected_authids
	}
	TrieIterDestroy iter_disconnected_authids
	TrieDestroy disconnected_authids
	// Merge these to-be-bumped models into a trie of those that are already bumped
	// This means that g_aBumps must be turned into a trie first...
	new Trie:map_bumps = TrieCreate()
	static entry[eBumpEntry]
	new entries_n = ArraySize(g_aBumps)
	for (new i; i < entries_n; i++) {
		ArrayGetArray g_aBumps, i, entry, eBumpEntry
		TrieSetArray map_bumps, entry[mBE_szName], entry, mBE_szName
	}
	// Now use Trie:loaded_authids, create bump entries, put them in the new Trie:map_bumps.
	// loaded_authids becomes useless after, so free it.
	new TrieIter:iter_loaded_authids = TrieIterCreate(loaded_authids)
	new timestamp = get_systime()
	while (TrieIterGetString(iter_loaded_authids, entry[mBE_szName], charsmax(entry[mBE_szName]))) {
		TrieIterGetKey iter_loaded_authids, authid, charsmax(authid)
		entry[mBE_iTimestamp] = timestamp
		entry[mBE_iExtra] = 0
		TrieSetArray map_bumps, name, entry, mBE_szName
		TrieIterNext iter_loaded_authids
	}
	TrieIterDestroy iter_loaded_authids
	TrieDestroy loaded_authids
	// Rewrite the bumps file.
	// After, we can wash our hands of this bump-related trie/array nonsense.
	new TrieIter:map_bumps_iter = TrieIterCreate(map_bumps)
	bumps_from_trieiter map_bumps_iter
	TrieIterDestroy map_bumps_iter
	TrieDestroy map_bumps
	ArrayDestroy g_aBumps
	if (g_fileBumpsIsOpen) bumps_close
	//
	
	TrieDestroy loaded_model_indices
	ArrayDestroy loaded_model_infos
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
