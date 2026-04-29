package DatabasesFinal.BLL;

import DatabasesFinal.DAL.PlaylistDataProvider;

public class PlaylistController {

    private PlaylistDataProvider playlistDP = new PlaylistDataProvider();

    // User input goes from controller to DataProvider to be inserted into DB
    public int createPlaylist(int userId, String playlistName) throws Exception {
        return playlistDP.createPlaylist(userId, playlistName);
    }
}
