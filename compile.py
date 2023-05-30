####
# Usage guide:
#  Run with no arguments to compile all .sma source code files in the current directory.
#  Run with a .sma file path argument to compile a single file.
#   The "include" directory will still be searched for in the current directory.
####

import os, json, subprocess, datetime, sys

KEY_PATH_PLUGINS  = 'path_plugins'
KEY_PATH_COMPILER = 'path_compiler'
KEY_PATH_CONFIGS  = 'path_configs'

def prompt_path():
	while 1:
		path = input(' > ').strip()
		if os.path.isdir(path): return path
		print(f'The path "{path}" does not exist.')

dir_appdata = (
	os.path.expandvars('%APPDATA%') if os.name == 'nt' else
	os.path.expanduser('~')
)
dir_sw        = os.path.join(dir_appdata, 'SkillzWorld')
file_settings = os.path.join(dir_sw     , 'compilehelper.json')
os.makedirs(dir_sw, exist_ok = True)

print(f'Looking for settings file: "{file_settings}"')
if os.path.isfile(file_settings):
	print(' Found.')
	with open(file_settings) as f:
		settings = json.load(f)
	should_save_settings = False
else:
	print(' Not found.')
	settings = {}
	should_save_settings = True

if settings.get(KEY_PATH_PLUGINS) is None:
	print('The plugins path is not set up. Enter the directory to put compiled .amxx plugins:')
	settings[KEY_PATH_PLUGINS] = prompt_path()
	should_save_settings = True
	
if settings.get(KEY_PATH_COMPILER) is None:
	print('The compiler path is not set up. Enter the directory where amxxpc.exe can be found:')
	while 1:
		path = prompt_path()
		file = os.path.join(path, 'amxxpc.exe')
		if os.path.isfile(file): break
		print('The compiler amxxpc.exe is not in this directory.')
	settings[KEY_PATH_COMPILER] = path
	should_save_settings = True
file_compiler = os.path.join(settings[KEY_PATH_COMPILER], 'amxxpc.exe')
	
if settings.get(KEY_PATH_CONFIGS) is None:
	print('The configs path is not set up. Enter the directory where plugins.ini for AMX Mod X can be found:')
	while 1:
		path = prompt_path()
		file = os.path.join(path, 'plugins.ini')
		if os.path.isfile(file): break
		print('The plugins config plugins.ini is not in this directory.')
	settings[KEY_PATH_CONFIGS] = path
	should_save_settings = True
file_config_plugins = os.path.join(settings[KEY_PATH_CONFIGS], 'plugins.ini')

if should_save_settings:
	with open(file_settings, 'w') as f:
		json.dump(settings, f, indent = '\t')

cwd = os.getcwd()
path_include = os.path.join(cwd, 'include')
file_script_version = os.path.join(path_include, 'script_version.inc')
file_script_name    = os.path.join(path_include, 'script_name.inc')
print(f'Using compiler: "{file_compiler}"')
print('Creating these files:')
print(f' "{file_script_version}"')
print(f' "{file_script_name}"')
print(f'Dumping plugins into directory: "{settings[KEY_PATH_PLUGINS]}"')

compiled_n = 0
if len(sys.argv) > 1: # A file argument was given
	file = sys.argv[1]
	assert os.path.splitext(file)[1].lower() == '.sma', 'If an argument is given, it must be .sma source code to compile.'
	assert os.path.isfile(file), 'The given file argument is not a valid file.'
	print(f'Compiling single file "{file}"')
	files = (file,)
else: # Nothing was given, so compile everything in the CWD
	print(f'Compiling all .sma source files in current directory: "{cwd}"')
	_, _, filenames = next(os.walk(cwd))
	files = (os.path.join(cwd, filename) for filename in filenames)

compiled_plugins = set()

print() # Empty line
for file in files:
	file_extless, ext = os.path.splitext(file)
	if not ext.lower() == '.sma': continue
	compiled_n += 1
	
	filename_extless = os.path.split(file_extless)[1]
	filename_plugin = filename_extless + '.amxx'
	
	file_plugin = os.path.join(settings[KEY_PATH_PLUGINS], filename_plugin)
	compiled_plugins.add(filename_plugin)
	today_str = datetime.date.today().strftime('%d/%m/%y')
	
	_, filename = os.path.split(file)
	print(f'Compiling plugin code: "{filename}"')
	
	with open(file_script_version, 'w') as f: f.write(f'stock const _SCRIPT_DATE[] = "{today_str}"')
	with open(file_script_name   , 'w') as f: f.write(f'stock const _SCRIPT_NAME[] = "{filename_extless}"')
	subprocess.run(
		(file_compiler, file, f'-o{file_plugin}')
	)
	print() # Empty line

if not os.path.isfile(file_config_plugins):
	print(f'Could not find plugins.ini in "{file_config_plugins}".\n Ignoring.')
elif compiled_plugins:
	config_plugins = set()
	with open(file_config_plugins) as f:
		for line in f:
			line = line.strip() # Prune whitespace
			if not line: continue
			line = line.split(';', maxsplit = 1)[0] # Prune comments
			if not line: continue
			tokens = line.split(maxsplit = 1)
			config_plugins.add(tokens[0]) # Add the plugin name.amxx
	
	new_plugins = compiled_plugins - config_plugins
	if new_plugins:
		print(f'Adding new plugins to plugins.ini:')
		with open(file_config_plugins, 'a') as f:
			for new_plugin in sorted(new_plugins):
				print(f' {new_plugin}')
				f.write(f'\n{new_plugin} debug ; Added by compile.py')

print(f'Compiled {compiled_n} plugin{"s"*(compiled_n != 1)}.')
#input('Press enter to quit.\n')