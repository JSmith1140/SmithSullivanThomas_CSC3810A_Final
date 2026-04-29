package DatabasesFinal.DAL;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
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
}
