//
// VIDE: Modified to allow version & license as args.
//

// Copyright (c) 2019-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module main

// This module follows a similar convention to Rust: `init` makes the
// structure of the program in the _current_ directory, while `new`
// makes the program structure in a _sub_ directory. Besides that, the
// functionality is essentially the same.
import os

struct Create {
mut:
	name        string
	description string
	version     string
	license     string
	dir         string
}

fn cerror(e string) {
	eprintln('\nerror: ${e}')
}

fn check_name(name string) string {
	if name.trim_space().len == 0 {
		return ''

		// cerror('project name cannot be empty')
		// exit(1)
	}
	if name.is_title() {
		mut cname := name.to_lower()
		if cname.contains(' ') {
			cname = cname.replace(' ', '_')
		}
		eprintln('warning: the project name cannot be capitalized, the name will be changed to `${cname}`')
		return cname
	}
	if name.contains(' ') {
		cname := name.replace(' ', '_')
		eprintln('warning: the project name cannot contain spaces, the name will be changed to `${cname}`')
		return cname
	}
	return name
}

fn vmod_content(c Create) string {
	return [
		'Module {',
		"	name: '${c.name}'",
		"	description: '${c.description}'",
		"	version: '${c.version}'",
		"	license: '${c.license}'",
		'	dependencies: []',
		'}',
		'',
	].join_lines()
}

fn main_content() string {
	return [
		'module main\n',
		'fn main() {',
		"	println('Hello World!')",
		'}',
		'',
	].join_lines()
}

fn gen_gitignore(name string) string {
	return [
		'# Binaries for programs and plugins',
		'main',
		'${name}',
		'*.exe',
		'*.exe~',
		'*.so',
		'*.dylib',
		'*.dll',
		'vls.log',
		'',
	].join_lines()
}

fn gitattributes_content() string {
	return [
		'*.v linguist-language=V text=auto eol=lf',
		'*.vv linguist-language=V text=auto eol=lf',
		'',
	].join_lines()
}

fn (c &Create) write_vmod(new bool) {
	vmod_path := if new { '${c.dir}/${c.name}/v.mod' } else { 'v.mod' }
	os.write_file(vmod_path, vmod_content(c)) or { panic(err) }
}

fn (c &Create) write_main(new bool) {
	if !new && (os.exists('${c.name}.v') || os.exists('src/${c.name}.v')) {
		return
	}
	main_path := if new { '${c.dir}/${c.name}/${c.name}.v' } else { '${c.name}.v' }
	os.write_file(main_path, main_content()) or { panic(err) }
}

fn (c &Create) write_gitattributes(new bool) {
	gitattributes_path := if new { '${c.dir}/${c.name}/.gitattributes' } else { '.gitattributes' }
	os.write_file(gitattributes_path, gitattributes_content()) or { panic(err) }
}

fn (c &Create) create_git_repo(dir string) {
	// Create Git Repo and .gitignore file
	if !os.is_dir('${dir}/.git') {
		res := os.execute('git init ${dir}')
		if res.exit_code != 0 {
			// cerror('Unable to create git repo')

			// exit(4)
		}
	}
	gitignore_path := '${dir}/.gitignore'
	if !os.exists(gitignore_path) {
		os.write_file(gitignore_path, gen_gitignore(c.name)) or {}
	}
}

pub fn create_v(dir string, args []string) {
	mut c := Create{}
	c.dir = dir
	c.name = check_name(if args.len > 0 { args[0] } else { os.input('Input your project name: ') })
	if c.name == '' {
		// cerror('project name cannot be empty')
		// exit(1)
		return
	}
	if c.name.contains('-') {
		// cerror('"$c.name" should not contain hyphens')
		// exit(1)
		return
	}
	if os.is_dir(c.name) {
		// cerror('$c.name folder already exists')
		// exit(3)
		return
	}
	c.description = if args.len > 1 { args[1] } else { os.input('Input your project description: ') }
	default_version := '0.0.0'
	c.version = if args.len > 2 {
		args[2]
	} else {
		os.input('Input your project version: (${default_version}) ')
	}
	if c.version == '' {
		c.version = default_version
	}
	default_license := 'MIT'
	c.license = if args.len > 3 {
		args[3]
	} else {
		os.input('Input your project license: (${default_license}) ')
	}
	if c.license == '' {
		c.license = default_license
	}
	println('Initialising ...')
	os.mkdir(c.dir + '/' + c.name) or { panic(err) }
	c.write_vmod(true)
	c.write_main(true)
	c.write_gitattributes(true)
	c.create_git_repo(c.dir + '/' + c.name)
}

fn init_project() {
	if os.exists('v.mod') {
		cerror('`v init` cannot be run on existing v modules')
		exit(3)
	}
	mut c := Create{}
	c.name = check_name(os.file_name(os.getwd()))
	c.description = ''
	c.write_vmod(false)
	c.write_main(false)
	c.write_gitattributes(false)
	c.create_git_repo('.')

	println('Change the description of your project in `v.mod`')
}
