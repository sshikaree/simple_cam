project('simple_cam', 'vala', 'c')

# subdir('src')

gnome = import('gnome')
i18n  = import('i18n')

# define GETTEXT_PACKAGE 
add_project_arguments('-DGETTEXT_PACKAGE="intltest"', language:'c')

# libgxml_proj = subproject('gxml')
# libgxml_dep = libgxml_proj.get_variable('libgxml_dep')

gresources = gnome.compile_resources(
    meson.project_name() + '.resources',
    'data/gresource.xml',
    source_dir: ['ui']
)

sources = files(
    'src/main.vala',
    'src/application.vala',
    'src/main_window.vala',
    'src/cam_widget.vala',
    'src/add_cam_dialog.vala',
    'src/add_cam_url_dialog.vala',

    'src/cam_tree_store.vala',
)

dependencies = [
    dependency('glib-2.0'),
    dependency('gtk+-3.0'),
    dependency('gstreamer-1.0'),
    dependency('libxml-2.0'),
    # dependency('gio-2.0'),
    # dependency('gstreamer-video-1.0'),

    # libgxml_dep
]

executable(
    meson.project_name(),
    sources,
    gresources,
    dependencies: dependencies,
    install: false
)