using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            LoadUserInformation();
            if (!Page.IsPostBack)
            {
                LoadSongs();
            }
        }

        /// <summary>
        /// User stored in session when the login was successful.
        /// </summary>
        protected Entities.User CurrentUser
        {
            get
            {
                if (Session[Util.Constants.USER] == null)
                {
                    return null;
                }
                return (Entities.User)Session[Util.Constants.USER];
            }
        }

        protected bool IsAdmin
        {
            get
            {
                Entities.User user = CurrentUser;
                return user != null && user.UserType == Util.Constants.ID_USER_ADMIN;
            }
        }

        /// <summary>
        /// Shows the name of the logged user and enables the admin options.
        /// </summary>
        private void LoadUserInformation()
        {
            Entities.User user = CurrentUser;
            if (user != null)
            {
                lblUserName.Text = Server.HtmlEncode(user.UserName);
                lblUserType.Text = IsAdmin ? "Admin" : "User";
                pnlAdmin.Visible = IsAdmin;
                return;
            }

            // The session expired but the authentication ticket is still valid.
            string userName = Page.User.Identity.Name;
            if (string.IsNullOrEmpty(userName))
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }
            lblUserName.Text = Server.HtmlEncode(userName);
            lblUserType.Text = "User";
            pnlAdmin.Visible = false;
        }

        private void LoadSongs()
        {
            DataTable dtSong = new BLL.Song(strConnString).Read();
            rptSongs.DataSource = dtSong;
            rptSongs.DataBind();
            rptSongs.Visible = dtSong.Rows.Count > 0;
            pnlEmpty.Visible = dtSong.Rows.Count == 0;
        }

        /// <summary>
        /// Resolves a "~/songFiles/x.mp3" path into a URL usable by the audio player.
        /// </summary>
        protected string SongUrl(object songPath)
        {
            string path = Convert.ToString(songPath);
            if (string.IsNullOrEmpty(path) || path.Trim() == string.Empty)
            {
                return string.Empty;
            }
            return ResolveUrl(path);
        }

        protected string HtmlText(object value)
        {
            return Server.HtmlEncode(Convert.ToString(value));
        }

        protected string HtmlAttr(object value)
        {
            return HttpUtility.HtmlAttributeEncode(Convert.ToString(value));
        }

        protected void BtnAddSong_Click(object sender, EventArgs e)
        {
            if (!IsAdmin)
            {
                lblMessage.Text = "Only an administrator can add songs!";
                return;
            }

            string songName = txtSongName.Text.Trim();
            string strSongFolder = ConfigurationManager.AppSettings["songFolderPath"];
            if (strSongFolder.EndsWith("/") == false)
            {
                strSongFolder += "/";
            }

            string newFileName = songName.Replace(" ", string.Empty);

            Entities.Song song = new Entities.Song();
            song.SongName = songName;
            song.Plays = 0;
            song.SongPath = strSongFolder + newFileName + ".mp3";

            string messageValidations = new BLL.Song(strConnString).ValidationsRequired(song);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }
            messageValidations = new BLL.Song(strConnString).ValidationsDuplicated(song);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }
            messageValidations = new FileManagement().SaveSongOnServer(fupSong, strSongFolder, newFileName);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }

            new BLL.Song(strConnString).Save(song);
            txtSongName.Text = string.Empty;
            lblMessage.Text = "Song added successfully!";
            LoadSongs();
        }

        protected void RptSongs_Command(object sender, CommandEventArgs e)
        {
            if (e.CommandName != "DeleteSong" || !IsAdmin)
            {
                return;
            }
            int idSong;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out idSong) || idSong <= 0)
            {
                lblMessage.Text = "The selected song is not valid!";
                return;
            }
            try
            {
                int rowsAffected = new BLL.Song(strConnString).Delete(idSong);
                lblMessage.Text = rowsAffected > 0 ? string.Empty : "The song could not be deleted!";
            }
            catch (Exception)
            {
                // The song is referenced by an album, a playlist or an artist.
                lblMessage.Text = "The song is used by an album or a playlist, it cannot be deleted!";
            }
            LoadSongs();
        }

        protected void BtnLogout_Click(object sender, EventArgs e)
        {
            Session.Clear();
            Session.Abandon();
            FormsAuthentication.SignOut();
            Response.Redirect("~/Login.aspx", true);
        }
    }
}
