module main

import iui as ui
import os
import math
import os.font
import gg
// import iui.extra.dialogs
// import net.http

fn settings_click(mut win ui.Window, com ui.MenuItem) {
	mut modal := ui.page(win, 'Settings')

	mut vbox := ui.vbox(win)

	mut lbl := title_label(win, 'General')
	vbox.add_child(lbl)

	vbox.set_bounds(16, 16, 0, 0)

	modal.needs_init = false
	mut close := ui.button(win, 'Save & Done')
	close.set_bounds(130, 7, 250, 30)

	mut can := ui.button(win, 'Cancel')
	can.set_bounds(21, 7, 100, 30)
	can.set_click(fn (mut win ui.Window, btn ui.Button) {
		win.components = win.components.filter(mut it !is ui.Page)
	})
	modal.add_child(can)

	close.set_click(fn (mut win ui.Window, btn ui.Button) {
		mut conf := get_config(win)
		conf.save()
		win.components = win.components.filter(mut it !is ui.Page)
	})

	vbox.draw_event_fn = fn (mut win ui.Window, mut com ui.Component) {
		size := win.gg.window_size()
		x_pos := (size.width / 3) - (com.width / 2)
		ui.set_pos(mut com, x_pos, 24)
	}
	win.id_map['setting_box'] = vbox

	mut conf := get_config(win)

	general_section(win, mut conf, mut vbox)
	appearance_section(win, mut conf, mut vbox)

	// Spacer
	spacer := title_label(win, '  ')
	vbox.add_child(spacer)

	mut sv := ui.scroll_view(
		view: vbox
	)

	sv.draw_event_fn = fn (mut win ui.Window, mut com ui.Component) {
		size := win.gg.window_size()
		ui.set_bounds(mut com, 20, 54, size.width - 40, size.height - 155)
	}

	modal.add_child(close)
	modal.add_child(sv)
	win.add_child(modal)
}

fn title_label(win &ui.Window, text string) &ui.Label {
	mut lbl := ui.label(win, text)
	lbl.pack()
	lbl.set_pos(0, 16)
	lbl.set_config(4, false, true)
	return &lbl
}

fn general_section(win &ui.Window, mut conf Config, mut vbox ui.VBox) {
	mut work_lbl := ui.label(win, 'Workspace Location')
	work_lbl.pack()

	workd := os.real_path(conf.get_value('workspace_dir').replace('\{user_home}', '~'))
	folder := os.expand_tilde_to_home(workd)

	mut work := ui.textfield(win, folder)
	mut dialog_btn := ui.button(win, 'Choose Folder')

	work.draw_event_fn = fn (mut win ui.Window, mut work ui.Component) {
		work.width = math.max(ui.text_width(win, work.text + 'a b'), 300)
		work.height = win.graphics_context.line_height + 8
	}
	work.text_change_event_fn = fn (a voidptr, b voidptr) {
		mut conf := get_config(&ui.Window(a))
		work := &ui.TextField(b)
		conf.set('workspace_dir', work.text.replace(os.home_dir().replace('\\', '/'),
			'~')) // '
	}

	mut lib_lbl := ui.label(win, 'Path to VEXE')
	lib_lbl.pack()

	home := os.home_dir().replace('\\', '/') // '
	mut vlib := ui.textfield(win, get_v_exe(win).replace(home, '~'))

	vlib.draw_event_fn = fn (mut win ui.Window, mut work ui.Component) {
		work.width = math.max(250, ui.text_width(win, work.text + 'a b'))
		work.height = win.graphics_context.line_height + 10
	}
	vlib.text_change_event_fn = fn (win_ptr voidptr, box_ptr voidptr) {
		mut win := &ui.Window(win_ptr)
		work := &ui.TextField(box_ptr)

		mut conf := get_config(win)
		conf.set('v_exe', work.text.replace(os.home_dir().replace('\\', '/'), '~')) // '
	}

	work_lbl.set_bounds(32, 8, 0, 0)
	lib_lbl.set_bounds(32, 8, 0, 0)
	work.set_bounds(32, 0, 0, 0)
	vlib.set_bounds(32, 4, 0, 0)

	mut hbox := ui.hbox(win)
	hbox.set_pos(0, 4)
	hbox.pack()

	/*
	dialog_btn.set_click_fn(fn (a voidptr, b voidptr, c voidptr) {
		mut work := &ui.TextField(c)
		val := dialogs.select_folder_dialog('Select Workspace Directory', work.text)
		if val.len > 0 && os.exists(val) {
			work.text = val

			mut win := &ui.Window(a)
			mut conf := get_config(win)
			conf.set('workspace_dir', work.text.replace(os.home_dir().replace('\\', '/'),
				'~')) // '
		}
	}, work)*/
	dialog_btn.set_pos(4, 0)
	dialog_btn.pack()

	hbox.add_child(work)
	hbox.add_child(dialog_btn)

	vbox.add_child(work_lbl)
	vbox.add_child(hbox)
	vbox.add_child(lib_lbl)
	vbox.add_child(vlib)
}

fn create_font_slider(win &ui.Window) &ui.VBox {
	mut fs_lbl := ui.label(win, 'Font size:')
	fs_lbl.set_bounds(4, 4, 100, 20)
	fs_lbl.draw_event_fn = fn (mut win ui.Window, mut lbl ui.Component) {
		lbl.text = 'Font Size (' + win.font_size.str() + '):'
		lbl.width = ui.text_width(win, lbl.text)
	}

	mut font_slider := ui.slider(win, 0, 28, .hor)
	font_slider.set_bounds(4, 4, 100, 30)
	font_slider.cur = win.font_size - 10
	font_slider.draw_event_fn = font_slider_draw

	mut vbox := ui.vbox(win)
	vbox.add_child(fs_lbl)
	vbox.add_child(font_slider)

	return vbox
}

fn tree_padding_slider_draw(mut win ui.Window, com &ui.Component) {
	mut this := *com
	mut tree := &ui.Tree2(win.get_from_id('proj-tree'))
	// this.y = win.font_size - 12
	// this.height = win.font_size + 4
	if mut this is ui.Slider {
		fs := tree.width
		new_val := (int(this.cur) * 10) + 100
		if fs == new_val {
			return
		}
		tree.width = new_val
		win.graphics_context.set_cfg(size: new_val)
	}
}

fn font_slider_draw(mut win ui.Window, com &ui.Component) {
	mut this := *com
	if mut this is ui.Slider {
		fs := win.font_size
		new_val := int(this.cur) + 10
		if fs == new_val {
			return
		}

		mut conf := get_config(win)
		conf.set('font_size', new_val.str())

		// this.height = new_val + 4

		win.font_size = new_val
		win.graphics_context.set_cfg(size: new_val)

		win.gg.ft.flush()
		win.gg.ft.fons.reset_atlas(1024, 1024)
	}
}

fn create_tree_width_slider(win &ui.Window) &ui.VBox {
	mut tree_padding_lbl := ui.label(win, 'Project Tree Padding')
	tree_padding_lbl.set_bounds(4, 4, 100, 20)
	tree_padding_lbl.draw_event_fn = fn (mut win ui.Window, mut lbl ui.Component) {
		tree := &ui.Tree2(win.get_from_id('proj-tree'))
		lbl.text = 'Project Tree Width (${tree.width}):'
		lbl.width = ui.text_width(win, lbl.text)
	}

	mut tree_padding_slider := ui.slider(win, 0, 30, .hor)
	tree_padding_slider.set_bounds(8, 8, 100, 30)
	tree := &ui.Tree2(win.get_from_id('proj-tree'))
	tree_padding_slider.cur = (tree.width - 100) / 10
	tree_padding_slider.draw_event_fn = tree_padding_slider_draw

	mut vbox := ui.vbox(win)
	vbox.add_child(tree_padding_lbl)
	vbox.add_child(tree_padding_slider)

	return vbox
}

fn appearance_section(win &ui.Window, mut conf Config, mut vbox ui.VBox) {
	// mut vbox := ui.vbox(win)

	mut lbl := title_label(win, 'Appearance')
	vbox.add_child(lbl)

	font_size_box := create_font_slider(win)
	tree_padding_box := create_tree_width_slider(win)

	mut hbox := ui.hbox(win)

	hbox.add_child(font_size_box)
	hbox.add_child(tree_padding_box)

	hbox.set_bounds(0, 0, 400, 100)
	hbox.set_width_as_percent(true, 99)

	hbox.parent = vbox

	// hbox.pack()

	vbox.add_child(hbox)

	font_lbl := ui.label(win, 'Main Font', ui.LabelConfig{
		x: 32
		y: 16
		should_pack: true
	})
	vbox.add_child(font_lbl)

	mut font_box := ui.selector(win, 'Font', ui.SelectConfig{
		bounds: ui.Bounds{32, 8, 250, 35}
		items: [
			'Default Font',
			'Anomaly Mono',
			'Agave-Regular',
			'JetBrainsMono',
			'System SegoeUI',
		]
	})
	font_box.set_change(sel_change)

	vbox.add_child(font_box)

	// tb.add_child('Appearance', vbox)
}

// Font selector change
fn sel_change(mut win ui.Window, com ui.Select, old_val string, new_val string) {
	mut path := os.resource_abs_path('assets/' + new_val.replace(' ', '-') + '.ttf')

	if new_val == 'JetBrainsMono' {
		exists := os.exists(path)
		if !exists {
			download_font()
		}
	}

	if new_val == 'Default Font' {
		path = font.default()
	}
	if new_val.starts_with('System ') {
		path = 'C:/windows/fonts/' + new_val.split('System ')[1].to_lower() + '.ttf'
	}

	font := win.add_font(new_val, path)
	win.graphics_context.font = font
	mut conf := get_config(win)
	conf.set('main_font', path)
}

// Downloads JetBrainsMono
fn download_font() {
	os.mkdir(os.resource_abs_path('assets')) or {}
	path := os.resource_abs_path('assets/JetBrainsMono.ttf')

	mut embed := $embed_file('assets/JetBrainsMono.ttf')
	os.write_file_array(path, embed.to_bytes()) or {
		// Oh no!
	}
}