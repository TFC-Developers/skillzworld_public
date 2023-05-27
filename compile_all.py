import os, json, subprocess, datetime

KEY_PATH_PLUGINS  = 'plugins_path'
KEY_PATH_COMPILER = 'compiler_path'


def prompt_path():
	while 1:
		path = input(' > ').strip()
		if os.path.isdir(path): return path
		print(f'The path "{path}" does not exist.')
		
cwd           = os.getcwd()
print(f'Looking for .sma source files in current directory: "{cwd}"')

dir_appdata   = os.path.expandvars('%APPDATA%')
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
		path_compiler = prompt_path()
		file_compiler = os.path.join(path_compiler, 'amxxpc.exe')
		if isfile(file_compiler): break
		print('The compiler amxxpc.exe is not in this directory.')
	settings[KEY_PATH_COMPILER] = path_compiler
	should_save_settings = True

if should_save_settings:
	with open(file_settings, 'w') as f:
		json.dump(settings, f, indent = '\t')

file_compiler = os.path.join(settings[KEY_PATH_COMPILER], 'amxxpc.exe')
path_include = os.path.join(cwd, 'include')
file_script_version = os.path.join(path_include, 'script_version.inc')
file_script_name    = os.path.join(path_include, 'script_name.inc')
print(f'Using compiler: "{file_compiler}"')
print('Creating these files:')
print(f' "{file_script_version}"')
print(f' "{file_script_name}"')
print(f'Dumping plugins into directory: "{settings[KEY_PATH_PLUGINS]}"')

compiled_n = 0
_, _, filenames = next(os.walk(cwd))
print() # Empty line
for filename in filenames:
	extless, ext = os.path.splitext(filename)
	file_output = os.path.join(settings[KEY_PATH_PLUGINS], extless)
	
	if not ext.lower() == '.sma': continue
	
	compiled_n += 1
	today_str = datetime.date.today().strftime('%d/%m/%y')
	print(f'Compiling plugin code: "{filename}"')
	with open(file_script_version, 'w') as f: f.write(f'stock const _SCRIPT_DATE[] = "{today_str}"')
	with open(file_script_name   , 'w') as f: f.write(f'stock const _SCRIPT_NAME[] = "{extless}"')
	subprocess.run(
		(file_compiler, filename, f'-o{file_output}')
	)
	print() # Empty line
	
print(f'Compiled {compiled_n} plugins.')
input('Press enter to quit.\n')