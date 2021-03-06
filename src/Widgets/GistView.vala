namespace GtkGistManager {

    class GistView : Gtk.Box{

        public ValaGist.Gist gist;
        public FileView[] file_view = {};

        public bool is_editable;
        public signal void edited (ValaGist.Gist gist, GLib.Array<ValaGist.GistFile> files_to_remove = new GLib.Array<ValaGist.GistFile>());
        public signal void failed_edit (string message);
        public signal void cancelled_edit ();
        public signal void delete_gist ();
        private Gtk.ScrolledWindow scroll_files;
        private Gtk.Box scroll_files_box;
        private Gtk.ActionBar action_bar;
        private Gtk.Button edit_button;
        private Gtk.Button cancel_button;
        private Gtk.Button add_file_button;
        private Gtk.CheckButton public_check;
        private Gtk.Entry description_entry;
        private Gtk.Button delete_gist_button;

        private ValaGist.GistFile[] orginal_gist_files = {};
        private string orginal_description;

        public GistView (ValaGist.Gist gist, bool can_edit, bool create = false) {
            this.gist = gist;
            orginal_gist_files = gist.files;
            this.set_orientation (Gtk.Orientation.VERTICAL);

            edit_button = new Gtk.Button.with_label ("Edit");
            edit_button.get_style_context ().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            edit_button.clicked.connect (() =>{
                toggle_is_editable (create);
            });

            cancel_button = new Gtk.Button.with_label ("Cancel");
            cancel_button.set_sensitive(false);
            cancel_button.clicked.connect(() =>{
                toggle_is_editable (create, true);
            });

            delete_gist_button = new Gtk.Button.with_label ("Delete");
            delete_gist_button.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            delete_gist_button.clicked.connect(() =>{
                delete_gist ();
            });

            public_check = new Gtk.CheckButton.with_label ("Public");
            public_check.active = gist.is_public;
            public_check.set_sensitive(false);

            description_entry = new Gtk.Entry();
            description_entry.set_placeholder_text("Description");
            description_entry.set_hexpand(true);
            description_entry.set_editable(false);
            description_entry.can_focus = false;
            description_entry.set_text(gist.description);
            orginal_description = gist.description;

            add_file_button = new Gtk.Button.with_label("Add file");
            add_file_button.set_sensitive(false);
            add_file_button.clicked.connect(() =>{
                var new_file = new ValaGist.GistFile ("newfile.txt", "", false);
                gist.add_file (new_file);
                FileView new_view = new FileView (new_file);
                file_view += new_view;
                new_view.delete_file.connect ((source) => {
                    scroll_files_box.remove (new_view);
                    GenericArray<FileView> new_file_views = new GenericArray<FileView>();
                    new_file_views.data = file_view;
                    new_file_views.remove (source);
                    file_view = new_file_views.data;

                    GenericArray<ValaGist.GistFile> new_files = new GenericArray<ValaGist.GistFile>();
                    new_files.data = gist.files;
                    new_files.remove (new_file);
                    gist.replace_with_files (new_files.data);
                });

                file_view[file_view.length - 1].toggle_editable ();
                scroll_files_box.pack_start(file_view[file_view.length - 1]);
                show_all ();
            });

            action_bar = new Gtk.ActionBar();
            action_bar.get_style_context ().add_class ("action-bar");
            if (can_edit) action_bar.pack_start(edit_button);
            action_bar.pack_end(delete_gist_button);
            action_bar.pack_end(public_check);
            action_bar.pack_end(description_entry);
            action_bar.pack_end(add_file_button);
            action_bar.pack_end(cancel_button);

            scroll_files = new Gtk.ScrolledWindow(null, null);
            scroll_files_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            scroll_files.add(scroll_files_box);

            set_files(gist);
            this.pack_start(scroll_files, true);
            this.pack_end(action_bar, false);
        }

        public void reset(){
            description_entry.set_text (orginal_description);
            gist.replace_with_files (orginal_gist_files);
            scroll_files_box.foreach ((element) => scroll_files_box.remove (element));
            file_view = {};
            set_files (gist);

            description_entry.set_text(gist.description);

            show_all ();
        }

        public bool get_is_editable(){
            return is_editable;
        }

        public string check_edit () {
            if (file_view.length == 0) {
                return "Gist must have more than one file";
            }

            string[] filenames = {};
            foreach (FileView file_v in file_view) {
                if (file_v.get_content () == "") {
                    return "All files must be not be empty";
                }

                if (file_v.get_name () in filenames) {
                    return "Repeated filenames are not allowed";
                }

                filenames += file_v.get_name ();
            }

            return "";
        }

        public void toggle_is_editable(bool create=false, bool cancelled=false){
            is_editable = !is_editable;
            if(is_editable){
                description_entry.set_editable (true);
                description_entry.can_focus = true;
                if (create) {
                    action_bar.remove (cancel_button);
                    action_bar.remove (delete_gist_button);
                    public_check.set_sensitive (true);
                }

                cancel_button.set_sensitive (true);
                add_file_button.set_sensitive (true);
                foreach(FileView file in file_view){
                    file.toggle_editable();
                }

                edit_button.set_label ("Save");
                edit_button.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                edit_button.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            }else{
                string check = check_edit ();
                if (check == "" || cancelled) {
                    description_entry.set_editable (false);
                    description_entry.can_focus = false;
                    add_file_button.set_sensitive (false);
                    cancel_button.set_sensitive (false);
                    foreach(FileView file in file_view){
                        file.toggle_editable();
                    }

                    edit_button.set_label("Edit");
                    edit_button.get_style_context().remove_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                    edit_button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                }

                if (cancelled) {
                    reset ();
                    cancelled_edit ();
                    return;
                }

                if (check != "") {
                    is_editable = !is_editable;
                    failed_edit (check);
                    return;
                }

                if (create) {
                    ValaGist.GistFile[] files = new ValaGist.GistFile[file_view.length];
                    int count = 0;
                    foreach(FileView file_v in file_view){
                        files[count] = new ValaGist.GistFile (file_v.get_name (), file_v.get_content (), false);
                        count += 1;
                    }

                    edited (new ValaGist.Gist (get_description (), get_is_public (), files));
                    return;
                }

                // edit
                gist.edit_description (get_description());

                // update gist from file_view
                int count = 0;
                foreach(FileView file_v in file_view){
                    gist.files[count].edit_filename (file_v.get_name ());
                    gist.files[count].edit_file_content (file_v.get_content ());
                    count += 1;
                }

                // remove files that have been removed from file_view
                GLib.Array<ValaGist.GistFile> files_to_remove = new GLib.Array<ValaGist.GistFile> ();
                foreach(ValaGist.GistFile org_file in orginal_gist_files){
                    bool found = false;
                    foreach(ValaGist.GistFile file in gist.files){
                        if (file == org_file) {
                            found = true;
                            break;
                        }
                    }

                    bool file_view_with_same_filename = false;
                    foreach(FileView file_v in file_view){
                        if (file_v.get_name () == org_file.filename) {
                            file_view_with_same_filename = true;
                            break;
                        }
                    }

                    if (!found && !file_view_with_same_filename) {
                        files_to_remove.append_val (org_file);
                    }
                }

                edited (gist, files_to_remove);

            }

        }

        public string get_description(){
            return description_entry.get_text();
        }

        public void set_description(string description){
            description_entry.set_text(description);
        }

        public bool get_is_public(){
            print (public_check.get_mode().to_string());
            return public_check.get_active ();
        }

        private void set_files(ValaGist.Gist gist){
            foreach(ValaGist.GistFile file in gist.files){
                FileView new_view = new FileView(file);
                file_view += new_view;
                new_view.delete_file.connect ((source) => {
                    scroll_files_box.remove (new_view);
                    GenericArray<FileView> new_file_views = new GenericArray<FileView>();
                    new_file_views.data = file_view;
                    new_file_views.remove (source);
                    file_view = new_file_views.data;

                    GenericArray<ValaGist.GistFile> new_files = new GenericArray<ValaGist.GistFile>();
                    new_files.data = gist.files;
                    new_files.remove (file);
                    gist.replace_with_files (new_files.data);
                });

                scroll_files_box.pack_start(new_view);
            }
        }

    }

}
