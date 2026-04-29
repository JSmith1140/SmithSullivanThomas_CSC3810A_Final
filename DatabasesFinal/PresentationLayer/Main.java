package DatabasesFinal.PresentationLayer;

import java.util.Scanner;

import DatabasesFinal.BLL.PlaylistController;
import DatabasesFinal.DAL.DataMgr;

public class Main {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        PlaylistController controller = new PlaylistController();

        System.out.print("Enter DB username: ");
        String user = scanner.nextLine();

        System.out.print("Enter DB password: ");
        String pass = scanner.nextLine();

        try {
            DataMgr.initialize(user, pass);
            System.out.println("Connected to database successfully!");
        } catch (Exception e) {
            System.out.println("Connection failed: " + e.getMessage());
            return;
        }

        // ****Temporary Menu to test Workflows will change to a GUI****
        while (true) {
            System.out.println("---------------------------------");
            System.out.println("1. Create a new playlist");
            System.out.println("2. Exit");
            System.out.print("Select an option: ");

            String choice = scanner.nextLine();

            // switch case for user input
            switch (choice) {
                case "1":
                    try {
                        // Get user input
                        System.out.print("Enter User ID: ");
                        int userId = Integer.parseInt(scanner.nextLine());

                        System.out.print("Enter Playlist Name: ");
                        String playlistName = scanner.nextLine();

                        // user inputs go to controller
                        controller.createPlaylist(userId, playlistName);

                        // Show result
                        System.out.println(playlistName + " created successfully!");

                    } catch (Exception e) {
                        System.out.println("Error creating playlist: " + e.getMessage());
                    }
                    break;
                case "2":
                    System.out.println("Exiting system");
                    DataMgr.closeConnection();
                    return;
                default:
                    System.out.println("Invalid option. Please try again.");
            }
        }
    }
}