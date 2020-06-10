using ValaGist;

namespace GtkGistManager {

    public class MyProfileView : ProfileView, Object {

        public Gist[] gists { get; set; }
        public bool editable { get; set; }

        public PageSwitcher page_switcher { get; set; }

        public MyProfile profile;

        public signal void create ();
        public signal void edited ();
        public signal void clicked ();
        public signal void unclicked ();

        public MyProfileView(MyProfile profile){
            this.profile = profile;
            editable = true;

            create.connect (()=>{
                print("create signal");
            });

		    page_switcher = new PageSwitcher ();
		    page_switcher.show_all ();
        }

        public Gist[] list_all () {
            return profile.list_all ();
        }

        public void set_gists(Gist[] gists){
            page_switcher.remove_all ();
            set_gists_widgets (gists);

            // select first in list
            page_switcher.sidebar.sidebar_list.list_box.select_row (
                page_switcher.sidebar.sidebar_list.list_box.get_row_at_index (0));

            page_switcher.show_all ();
        }

        private void set_gists_widgets(Gist[] gists){
            foreach(Gist gist in gists){
                var gist_view = new GistView(gist, true);
                gist_view.edited.connect ((source, gist) => {
                    profile.edit (gist);
                    edited ();
                });

                page_switcher.add_page (gist_view, gist.name, gist.id);

                page_switcher.pages.notify["visible-child-name"].connect ((sender, property) => {
                    clicked ();
                    if (gist.id == page_switcher.pages.get_visible_child_name ()) {
                        GistView wid = (GistView) page_switcher.pages.get_child_by_name(gist.id);
                        foreach(FileView file_v in wid.file_view){
                            file_v.load_content ();
                        }
                    }
                    unclicked ();
                });
            }
        }

    }

}
