using System;
using System.Configuration;
using System.Web;

namespace WebAppPoliMusicV2
{
    /// <summary>
    /// Lightweight endpoint used by the player of Song.aspx to increase the
    /// PLAYS counter of a song without reloading the page (a postback would
    /// stop the audio). It answers "1" when the counter was updated and "0"
    /// when it was not.
    /// </summary>
    public class PlayCounter : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

            int idSong;
            if (!int.TryParse(context.Request.QueryString["id"], out idSong) || idSong <= 0)
            {
                context.Response.Write("0");
                return;
            }
            try
            {
                string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
                int rowsAffected = new BLL.Song(strConnString).IncrementPlays(idSong);
                context.Response.Write(rowsAffected > 0 ? "1" : "0");
            }
            catch (Exception)
            {
                context.Response.Write("0");
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
