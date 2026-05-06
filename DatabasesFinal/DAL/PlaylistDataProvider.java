package DatabasesFinal.DAL;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import DatabasesFinal.BLL.PlaylistStat;
import DatabasesFinal.BLL.SongCandidate;

import java.sql.CallableStatement;

public class PlaylistDataProvider {
    
    public int createPlaylist(int userId, String playlistName) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL CreatePlaylist(?, ?, ?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, playlistName);
            stmt.registerOutParameter(3, Types.INTEGER);

            stmt.execute();

            int playlistId = stmt.getInt(3);

            return playlistId;
        }
    }

    public void addSongToPlaylist(int playlistId, int songId) throws SQLException{
        
        Connection conn = DataMgr.getConnection();
        String sql = "{CALL AddSongToPlaylist(?, ?)}";

        try(CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, playlistId);
            stmt.setInt(2, songId);

            stmt.execute();
        }
    }

    public void blacklistSong(int userId, int songId) throws SQLException{

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL BlacklistSong(?, ?)}";

        try(CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);
            stmt.setInt(2, songId);

            stmt.execute();
        }
    }

    public List<SongCandidate> getCandidateSongs(int userId, String artist1, String artist2, String artist3) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetCandidateSongs(?, ?, ?, ?)}";

        List<SongCandidate> songs = new ArrayList<>();

        try (CallableStatement stmt = conn.prepareCall(sql)) {

            stmt.setInt(1, userId);
            stmt.setString(2, artist1);
            stmt.setString(3, artist2);
            stmt.setString(4, artist3);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                int songId = rs.getInt("SongId");
                String songName = rs.getString("SongName");
                String source = rs.getString("Source");
                String artist = rs.getString("ArtistName");
                int plays = rs.getInt("UserPlays");
                int skips = rs.getInt("SkipCount");
                int lastPlayed = rs.getInt("DaysSinceLastPlayed");

                songs.add(new SongCandidate(songId, songName, source, artist, plays, skips, lastPlayed));
            }
        }

        return songs;
    }

    public Set<Integer> getBlacklist(int userId) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetBlacklistIds(?)}";

        Set<Integer> blacklist = new HashSet<>();

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                blacklist.add(rs.getInt("SongId"));
            }
        }

        return blacklist;
    }

    public Map<Integer, Integer> getUserArtistScores(int userId) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetUserArtistScores(?)}";

        Map<Integer, Integer> map = new HashMap<>();

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                int artistId = rs.getInt("ArtistId");
                int score = rs.getInt("Score");

                map.put(artistId, score);
            }
        }

        return map;
    }

    public Map<Integer, Integer> getUserGenreScores(int userId) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetUserGenreScores(?)}";

        Map<Integer, Integer> map = new HashMap<>();

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                int genreId = rs.getInt("GenreId");
                int score = rs.getInt("Score");

                map.put(genreId, score);
            }
        }

        return map;
    }

    public int getArtistIdBySong(int songId) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetArtistIdBySong(?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, songId);

            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                return rs.getInt("ArtistId");
            }
        }

        return 0;
    }

    public int getGenreIdBySong(int songId) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetGenreIdBySong(?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, songId);

            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                return rs.getInt("GenreId");
            }
        }

        return 0;
    }

    public List<PlaylistStat> getPlaylistStats(int userId, String playlistName) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetPlaylistStats(?, ?)}";

        List<PlaylistStat> list = new ArrayList<>();

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, playlistName);

            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                list.add(new PlaylistStat(
                    rs.getString("SongName"),
                    rs.getInt("Plays"),
                    rs.getInt("TimesSkipped"),
                    rs.getDate("LastPlayed")
                ));
            }
        }

        return list;
    }
}
