package DatabasesFinal.DAL;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DataMgr {

    private static Connection connection = null;

    private static String dbUrl = "jdbc:mysql://localhost:3306/MusicPlayer";
    private static String username;
    private static String password;

    private DataMgr() {}

    /**
     * Initialize connection using user-provided credentials
     */
    public static void initialize(String user, String pass) throws SQLException {
        username = user;
        password = pass;

        connection = DriverManager.getConnection(dbUrl, username, password);
    }

    /**
     * Cached database connection object
     */
    public static synchronized Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            if (username == null || password == null) {
                throw new SQLException("Database not initialized. Call initialize() first.");
            }
            connection = DriverManager.getConnection(dbUrl, username, password);
        }
        return connection;
    }

    /**
     * Close connection
     */
    public static void closeConnection() {
        if (connection != null) {
            try {
                connection.close();
                connection = null;
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}