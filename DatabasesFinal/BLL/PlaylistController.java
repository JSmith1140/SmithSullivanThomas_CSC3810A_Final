package DatabasesFinal.BLL;

import java.util.List;
import DatabasesFinal.DAL.PlaylistDataProvider;

public class PlaylistController {

    private PlaylistDataProvider playlistDP = new PlaylistDataProvider();

    /***
     * create playlist
     * @param userId
     * @param playlistName
     * @return
     * @throws Exception
     */
    public int createPlaylist(int userId, String playlistName) throws Exception {
        return playlistDP.createPlaylist(userId, playlistName);
    }

    /***
     * add song to playlist
     * @param playlistId
     * @param songId
     * @throws Exception
     */
    public void addSongToPlaylist(int playlistId, int songId) throws Exception {
        playlistDP.addSongToPlaylist(playlistId, songId);
    }

    /***
     * blacklist song
     * @param userId
     * @param songId
     * @throws Exception
     */
    public void blacklistSong(int userId, int songId) throws Exception {
        playlistDP.blacklistSong(userId, songId);
    }

    /***
     * playlist stats
     * @param userId
     * @param playlistName
     * @return
     * @throws Exception
     */
    public List<PlaylistStat> playlistStats(int userId, String playlistName) throws Exception {
        return playlistDP.getPlaylistStats(userId, playlistName);
    }
}
