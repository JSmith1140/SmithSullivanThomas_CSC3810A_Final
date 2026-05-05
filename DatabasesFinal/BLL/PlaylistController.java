package DatabasesFinal.BLL;

import DatabasesFinal.DAL.GenreStatsDataProvider;
import DatabasesFinal.DAL.PlaylistDataProvider;

public class PlaylistController {

    private PlaylistDataProvider playlistDP = new PlaylistDataProvider();

    // User input goes from controller to DataProvider to be inserted into DB
    public int createPlaylist(int userId, String playlistName) throws Exception {
        return playlistDP.createPlaylist(userId, playlistName);
    }

    public void addSongToPlaylist(int playlistId, int songId) throws Exception {
        playlistDP.addSongToPlaylist(playlistId, songId);
    }

    public void blacklistSong(int userId, int songId) throws Exception {
        playlistDP.blacklistSong(userId, songId);
    }

    public void genreStats(int userId) throws Exception {
        GenreStatsDataProvider.getGenreStats(userId);
    }
}
