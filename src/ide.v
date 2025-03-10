module main

import gg
import iui as ui
import os
import hc

const (
	version = '0.0.14-dev'
)

struct App {
pub mut:
	win  &ui.Window
	conf &Config
	nill voidptr = unsafe { nil }
}

fn (mut app App) get_saved_value(key string) string {
	return app.conf.get_value(key)
}

[console]
fn main() {
	// Hide Console
	hc.hide_console_win()

	// Create Window

	mut window := ui.make_window(
		theme: ui.get_system_theme()
		title: 'Vide - IDE for V'
		width: 1080
		height: 670
		ui_mode: false
	)

	mut app := &App{
		win: window
		conf: config
	}

	// our custom config
	get_v_exe(window)

	fs := config.get_value('font_size')
	if fs.len > 0 {
		window.font_size = fs.int()
	}

	// Set menu
	app.make_menubar()

	// Set Saved Theme
	app.set_theme_from_save()

	workd := config.get_value('workspace_dir').replace('\{user_home}', '~').replace('\\',
		'/') // '
	folder := os.expand_tilde_to_home(workd).replace('~', os.home_dir())

	window.extra_map['workspace'] = folder
	os.mkdir_all(folder) or {}

	mut tb := ui.tabbox(window)
	tb.set_id(mut window, 'main-tabs')
	tb.set_bounds(0, 0, 300, 400)

	tb.draw_event_fn = on_draw

	mut hbox := ui.hbox(window)
	tree := setup_tree(mut window, folder)
	hbox.add_child(tree)
	// hbox.add_child(tb)

	hbox.draw_event_fn = fn (mut win ui.Window, mut hbox ui.Component) {
		size := win.gg.window_size()
		hbox.width = size.width
		hbox.height = size.height

		/*
		if 'font_load' !in win.extra_map {
			download_jbm()
			mut conf := get_config(win)
			saved_font := config.get_value('main_font')
			if saved_font.len > 0 {
				font := win.add_font('Saved Font', saved_font)
				win.graphics_context.font = font
			} else {
				path := os.resource_abs_path('assets/JetBrainsMono-Regular.ttf')
				font := win.add_font('Saved Font', path)
				win.graphics_context.font = font
			}
			win.extra_map['font_load'] = 'true'
		}*/
	}
	window.add_child(hbox)

	tb.z_index = 1
	welcome_tab(mut window, mut tb, folder)

	mut console_box := create_box(window)
	console_box.z_index = 2
	console_box.set_id(mut window, 'consolebox')

	mut sv := ui.scroll_view(
		view: console_box
		increment: 5
		bounds: ui.Bounds{
			height: 100
		}
		padding: 0
	)
	sv.set_id(mut window, 'vermsv')

	mut spv := ui.split_view(
		first: tb
		second: sv
		min_percent: 20
		h1: 70
		h2: 20
		bounds: ui.Bounds{
			y: 30
			x: 4
		}
	)
	spv.set_id(mut window, 'spv')
	hbox.add_child(spv)

	// window.add_child(sv)

	// basic plugin system
	// plugin_dir := os.real_path(os.home_dir() + '/vide/plugins/')
	// os.mkdir_all(plugin_dir) or {}
	// load_plugins(plugin_dir, mut window) or {}

	// open_install_modal_on_start_if_needed(mut window, app.nill)

	window.gg.run()
}

fn setup_tree(mut window ui.Window, folder string) &ui.Tree2 {
	mut tree2 := ui.tree2('Projects')
	tree2.set_bounds(4, 30, 300, 200)
	tree2.draw_event_fn = fn (mut win ui.Window, mut tree ui.Component) {
		tree.height = gg.window_size().height - 32
	}

	files := os.ls(folder) or { [] }
	tree2.click_event_fn = tree2_click

	for fi in files {
		mut node := make_tree2(os.join_path(folder, fi))
		tree2.add_child(node)
	}

	tree2.set_id(mut window, 'proj-tree')
	return tree2
}

fn welcome_tab(mut window ui.Window, mut tb ui.Tabbox, folder string) {
	mut info_lbl := ui.label(window,
		'Welcome to Vide!\nSimple IDE for the V Programming Language made in V.\n\nVersion: ' +
		version + ', UI version: ' + ui.version)

	padding_left := 70
	padding_top := 50

	mut vbox := ui.vbox(window)
	vbox.set_pos(padding_left, padding_top)

	info_lbl.set_pos(12, 24)
	info_lbl.pack()

	logo := window.gg.create_image_from_byte_array(vide_png0.to_bytes())
	window.id_map['vide_logo'] = &logo

	logo1 := window.gg.create_image_from_byte_array(vide_png1.to_bytes())
	window.id_map['vide_logo1'] = &logo1

	mut logo_im := ui.image(window, logo1)
	logo_im.set_bounds(0, 0, logo1.width, logo1.height)

	gh := ui.link(
		text: 'Github'
		url: 'https://github.com/isaiahpatton/vide'
		pack: true
	)

	ad := ui.link(
		text: 'Addons'
		url: 'https://github.com/topics/vide-addon'
		bounds: ui.Bounds{
			x: 12
		}
		pack: true
	)

	di := ui.link(
		text: 'Discord'
		url: 'https://discord.gg/NruVtYBf5g'
		bounds: ui.Bounds{
			x: 12
		}
		pack: true
	)

	vbox.add_child(logo_im)
	vbox.add_child(info_lbl)

	// Links
	mut hbox := ui.hbox(window)
	hbox.add_child(gh)
	hbox.add_child(ad)
	hbox.add_child(di)
	hbox.set_bounds(12, 12, 600, 100)
	hbox.pack()
	vbox.add_child(hbox)
	vbox.pack()

	tb.add_child('Welcome', vbox)
}

fn new_tab(mut window ui.Window, file string) {
	mut tb := &ui.Tabbox(window.get_from_id('main-tabs'))

	if file in tb.kids {
		// Don't remake already open tab
		tb.active_tab = file
		return
	}

	if file.ends_with('.png') {
		// Test
		comp := make_image_view(file, mut window)
		tb.add_child(file, comp)
		tb.active_tab = file
		return
	}

	lines := os.read_lines(file) or { ['ERROR while reading file contents'] }

	mut code_box := ui.textarea(window, lines)

	code_box.text_change_event_fn = codebox_text_change
	code_box.after_draw_event_fn = on_text_area_draw
	code_box.line_draw_event_fn = draw_code_suggest
	code_box.active_line_draw_event = text_area_testing
	code_box.hide_border = true
	code_box.padding_x = 8
	code_box.padding_y = 8
	code_box.set_bounds(0, 0, 620, 250)

	mut scroll_view := ui.scroll_view(
		bounds: ui.Bounds{0, 0, 620, 250}
		view: code_box
		increment: 16
		always_show: true
	)
	scroll_view.after_draw_event_fn = on_runebox_draw

	tb.add_child(file, scroll_view)
	tb.active_tab = file
}

fn set_console_text(mut win ui.Window, out string) {
	for mut comm in win.components {
		if mut comm is ui.TextArea {
			for line in comm.text.split_into_lines() {
				comm.lines << line
			}
			add_new_input_line(mut comm)
			return
		}
	}
}

fn run_v(dir string, mut win ui.Window) {
	mut vexe := 'v'
	if 'VEXE' in os.environ() {
		vexe = os.environ()['VEXE']
	} else {
		vexe = get_v_exe(win)
	}

	out := os.execute(vexe + ' run ' + dir)
	set_console_text(mut win, out.output)
}
