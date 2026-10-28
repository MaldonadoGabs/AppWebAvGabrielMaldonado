using System;
using System.Collections.Generic;
using System.Data;
using System.Web;

namespace WebAppPoliMusicV2.BLL
{
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }
        public int Save(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Save(song);
        }
        public DataTable Read()
        {
            return new DAL.Song(strConnectionString).Read();
        }
        public DataTable ReadById(int id)
        {
            return new DAL.Song(strConnectionString).ReadById(id);
        }

        public int Update(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Update(song);
        }

        public int Delete(int id)
        {
            return new DAL.Song(strConnectionString).Delete(id);
        }
        public int IncrementPlays(int idSong)
        {
            return new DAL.Song(strConnectionString).IncrementPlays(idSong);
        }
        public int CheckExistSong(string songName)
        {
            return new DAL.Song(strConnectionString).CheckExistSong(songName);
        }
        public string ValidationsRequired(Entities.Song song)
        {
            if (song.SongName == null || song.SongName.Trim() == string.Empty)
            {
                return "Song name is required!";
            }
            if (song.SongPath == null || song.SongPath.Trim() == string.Empty)
            {
                return "Song file is required!";
            }
            return string.Empty;
        }
        public string ValidationsDuplicated(Entities.Song song)
        {
            int returnValue = CheckExistSong(song.SongName);
            if (returnValue != 0)
            {
                return "Song already registered!";
            }
            return string.Empty;
        }
    }

}
