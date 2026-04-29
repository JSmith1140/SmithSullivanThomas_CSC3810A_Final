package DatabasesFinal.DAL;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.sql.CallableStatement;

public class GenreStats {
    
    public static void getGenreStats(int userId) throws SQLException {

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetUserGenreStats(?)}";

           try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, userId);
            stmt.registerOutParameter(3, Types.INTEGER);

            stmt.execute();

            ResultSet genreResultSet = stmt.getResultSet();

            while (genreResultSet.next())
            {
                int genreId = genreResultSet.getInt("GenreId");
                String genreName = genreResultSet.getString("GenreName");
                int uniqueSongs = genreResultSet.getInt("UniqueSongs");
                int totalPlays = genreResultSet.getInt("TotalPlays");
                int totalSecondsListened = genreResultSet.getInt("TotalSecondsListened");
                int totalSkips = genreResultSet.getInt("TotalSkips");
                System.out.println("Tuple Values:" + genreId + "," + genreName + "," + uniqueSongs + "," + totalPlays + "," + totalSecondsListened + "," + totalSkips);
            }
            return;
        }
    }
}
