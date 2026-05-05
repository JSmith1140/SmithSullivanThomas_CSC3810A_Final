package DatabasesFinal.PresentationLayer;
import java.awt.*;
import javax.swing.*;

import DatabasesFinal.BLL.PlaylistController;
import DatabasesFinal.BLL.PurgeController;
import DatabasesFinal.DAL.DataMgr;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import DatabasesFinal.BLL.AutoPlaylistController;
import DatabasesFinal.BLL.ScoredSong;

import java.util.List;

public class DatabaseGUI {
    JFrame frame;
    JLabel passwordPrompt;
    JLabel usernamePrompt;
    JTextField usernameInput;
    JPasswordField passwordInput;
    JButton submit;
    JButton back;
    JComboBox<String> selection;
    JLabel query;
    
    JLabel idPrompt;
    JLabel playlistNamePrompt;
    JTextField idInput;
    JTextField playlistNameInput;

    JLabel artist1Prompt;
    JLabel artist2Prompt;
    JLabel artist3Prompt;
    JTextField artist1Input;
    JTextField artist2Input;
    JTextField artist3Input;


    List<ScoredSong> recommendations;
    int currentIndex = 0;
    int currentPlaylistId;

    JLabel songDisplay;
    JLabel artistDisplay;
    JButton acceptBtn;
    JButton rejectBtn;
    JButton finishBtn;

    public DatabaseGUI(){

        frame = new JFrame("Music Player DB");
        frame.setBackground(Color.gray);

        frame.setSize(340, 260);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(null);

        usernamePrompt = new JLabel("Username: ", SwingConstants.CENTER);
        usernamePrompt.setBounds(10, 50, 80, 30);
        passwordPrompt = new JLabel("Password: ", SwingConstants.CENTER);
        passwordPrompt.setBounds(10, 90, 80, 30);

        submit = new JButton("Submit");
        submit.setBackground(Color.green);
        submit.setBorder(BorderFactory.createLineBorder(new Color(39, 174, 96), 3, false));
        submit.setBounds(105, 140, 110, 30);
        submit.addActionListener(new submitLogin());

        back = new JButton("Back");
        back.setBackground(Color.red);
        back.setBorder(BorderFactory.createLineBorder(new Color(192, 57, 43), 3, false));
        back.setBounds(105, 180, 110, 30);
        back.addActionListener(new backListener());

        usernameInput = new JTextField(20);
        usernameInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        usernameInput.setForeground(Color.BLACK);
        usernameInput.setBackground(Color.WHITE);
        usernameInput.setEditable(true);
        usernameInput.setBounds(90, 50, 200, 30); // Set consistent size
        
        passwordInput = new JPasswordField(20);
        passwordInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        passwordInput.setForeground(Color.BLACK);
        passwordInput.setBackground(Color.WHITE);
        passwordInput.setEditable(true);
        passwordInput.setBounds(90, 90, 200, 30); // Set consistent size
        
        frame.add(usernamePrompt); 
        frame.add(passwordPrompt);
        frame.add(passwordInput);
        frame.add(usernameInput);
        frame.add(submit);
        frame.setVisible(true);
    }

    public void OnLogin(){
        frame.remove(passwordPrompt);
        frame.remove(usernamePrompt);
        frame.remove(passwordInput);
        frame.remove(usernameInput);

        frame.repaint();

        query = new JLabel("What do you want to do?", SwingConstants.CENTER);
        query.setBounds(60, 30, 200, 30);

        selection = new JComboBox<String>();
        selection.addItem("New Playlist");
        selection.addItem("Get Stats");
        selection.addItem("Auto Playlist Builder");
        selection.addItem("Purge Playlist");
        selection.addItem("Join Playlists");
        selection.setBounds(60, 80, 200, 30);
        submit.setBounds(105, 140, 110, 30);
        back.setBounds(105, 180, 110, 30);

        for (ActionListener a : submit.getActionListeners()) {
            submit.removeActionListener(a);
        }
        submit.addActionListener(new selectionListener());

        frame.add(selection);
        frame.add(query);
    }

    public void OnPlaylist(){
        frame.remove(selection);
        frame.remove(query);
        frame.repaint();
        frame.add(back);

        idPrompt = new JLabel("User ID: ", SwingConstants.CENTER);
        idPrompt.setBounds(10, 50, 80, 30);
        playlistNamePrompt = new JLabel("Playlist Name: ", SwingConstants.CENTER);
        playlistNamePrompt.setBounds(10, 90, 100, 30);

        idInput = new JTextField(20);
        idInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        idInput.setForeground(Color.BLACK);
        idInput.setBackground(Color.WHITE);
        idInput.setEditable(true);
        idInput.setBounds(110, 50, 180, 30); // Set consistent size
        
        playlistNameInput = new JTextField(20);
        playlistNameInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        playlistNameInput.setForeground(Color.BLACK);
        playlistNameInput.setBackground(Color.WHITE);
        playlistNameInput.setEditable(true);
        playlistNameInput.setBounds(110, 90, 180, 30); // Set consistent size

        for (ActionListener a : submit.getActionListeners()) {
            submit.removeActionListener(a);
        }
        submit.addActionListener(new playlistListener());
        back.addActionListener(new backListener());

        frame.add(idPrompt);
        frame.add(playlistNamePrompt);
        frame.add(idInput);
        frame.add(playlistNameInput);
    }

    public void OnPlaylistBuilder(){
        frame.remove(selection);
        frame.remove(query);
        frame.remove(submit);
        frame.repaint();

        idPrompt = new JLabel("User ID: ", SwingConstants.CENTER);
        idPrompt.setBounds(10, 20, 80, 30);
        artist1Prompt = new JLabel("Artist 1: ", SwingConstants.CENTER);
        artist1Prompt.setBounds(10, 90, 100, 30);
        artist2Prompt = new JLabel("Artist 2: ", SwingConstants.CENTER);
        artist2Prompt.setBounds(10, 120, 100, 30);
        artist3Prompt = new JLabel("Artist 3: ", SwingConstants.CENTER);
        artist3Prompt.setBounds(10, 150, 100, 30);

        idInput = new JTextField(20);
        idInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        idInput.setForeground(Color.BLACK);
        idInput.setBackground(Color.WHITE);
        idInput.setEditable(true);
        idInput.setBounds(110, 20, 180, 30);

        playlistNamePrompt = new JLabel("Playlist Name: ", SwingConstants.CENTER);
        playlistNamePrompt.setBounds(10, 50, 100, 30);

        playlistNameInput = new JTextField(20);
        playlistNameInput.setBounds(110, 50, 180, 30);

        artist1Input = new JTextField(20);
        artist1Input.setFont(new Font("Monospaced", Font.PLAIN, 12));
        artist1Input.setForeground(Color.BLACK);
        artist1Input.setBackground(Color.WHITE);
        artist1Input.setEditable(true);
        artist1Input.setBounds(110, 90, 180, 30);

        artist2Input = new JTextField(20);
        artist2Input.setFont(new Font("Monospaced", Font.PLAIN, 12));
        artist2Input.setForeground(Color.BLACK);
        artist2Input.setBackground(Color.WHITE);
        artist2Input.setEditable(true);
        artist2Input.setBounds(110, 120, 180, 30);

        artist3Input = new JTextField(20);
        artist3Input.setFont(new Font("Monospaced", Font.PLAIN, 12));
        artist3Input.setForeground(Color.BLACK);
        artist3Input.setBackground(Color.WHITE);
        artist3Input.setEditable(true);
        artist3Input.setBounds(110, 150, 180, 30);

        submit.setBounds(180, 190, 100, 30);
        back.setBounds(60, 190, 100, 30);

        for (ActionListener a : submit.getActionListeners()) {
            submit.removeActionListener(a);
        }
        submit.addActionListener(new autoPlaylistListener());
        back.addActionListener(new backListener());

        frame.add(idPrompt);
        frame.add(idInput);
        frame.add(playlistNamePrompt);
        frame.add(playlistNameInput);
        frame.add(artist1Prompt);
        frame.add(artist1Input);
        frame.add(artist2Prompt);
        frame.add(artist2Input);
        frame.add(artist3Prompt);
        frame.add(artist3Input);
        frame.add(submit);
        frame.add(back);
    }

    public void OnPurgePlaylist() {

        frame.getContentPane().removeAll();
        frame.repaint();

        JLabel userIdLabel = new JLabel("User ID:", SwingConstants.CENTER);
        userIdLabel.setBounds(20, 40, 100, 30);

        JTextField userIdInput = new JTextField();
        userIdInput.setBounds(130, 40, 150, 30);

        JLabel playlistIdLabel = new JLabel("Playlist ID:", SwingConstants.CENTER);
        playlistIdLabel.setBounds(20, 80, 100, 30);

        JTextField playlistIdInput = new JTextField();
        playlistIdInput.setBounds(130, 80, 150, 30);

        JButton submitBtn = new JButton("Purge");
        submitBtn.setBounds(90, 130, 150, 35);
        submitBtn.setBackground(Color.RED);

        JButton backBtn = new JButton("Back");
        backBtn.setBounds(90, 180, 150, 30);

        JTextArea resultArea = new JTextArea();
        resultArea.setBounds(20, 220, 280, 150);
        resultArea.setEditable(false);

        submitBtn.addActionListener(e -> {
            try {
                int userId = Integer.parseInt(userIdInput.getText());
                int playlistId = Integer.parseInt(playlistIdInput.getText());

                PurgeController controller = new PurgeController();
                List<String> removed = controller.purgePlaylist(playlistId, userId);

                showPurgeResultsScreen(removed);
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });

        backBtn.addActionListener(e -> {
            frame.getContentPane().removeAll();
            frame.add(submit);
            OnLogin();
        });

        frame.add(userIdLabel);
        frame.add(userIdInput);
        frame.add(playlistIdLabel);
        frame.add(playlistIdInput);
        frame.add(submitBtn);
        frame.add(backBtn);
        frame.add(resultArea);

        frame.revalidate();
        frame.repaint();
    }

    public void showPurgeResultsScreen(List<String> removedSongs) {

        frame.getContentPane().removeAll();
        frame.repaint();

        JLabel title = new JLabel("Purge Results", SwingConstants.CENTER);
        title.setBounds(50, 20, 240, 30);
        title.setFont(new Font("Monospaced", Font.BOLD, 18));

        JTextArea textArea = new JTextArea();
        textArea.setEditable(false);
        textArea.setFont(new Font("Monospaced", Font.PLAIN, 12));

        if (removedSongs.isEmpty()) {
            textArea.setText("No songs were removed.");
        } else {
            textArea.append("Removed Songs:\n\n");
            for (String song : removedSongs) {
                textArea.append("- " + song + "\n");
            }
        }

        JScrollPane scrollPane = new JScrollPane(textArea);
        scrollPane.setBounds(20, 60, 300, 150);

        JButton continueBtn = new JButton("Continue");
        continueBtn.setBounds(90, 220, 150, 35);

        continueBtn.addActionListener(e -> {
            frame.getContentPane().removeAll();
            frame.add(submit);
            OnLogin(); // go back to home
        });

        frame.add(title);
        frame.add(scrollPane);
        frame.add(continueBtn);

        frame.revalidate();
        frame.repaint();
    }

    class autoPlaylistListener implements ActionListener {
    @Override
    public void actionPerformed(ActionEvent event){
        try {
            int userId = Integer.parseInt(idInput.getText());

            String playlistName = playlistNameInput.getText().trim();

            if (playlistName.isEmpty()) {
                throw new Exception("Please enter a playlist name.");
            }

            String a1 = artist1Input.getText();
            String a2 = artist2Input.getText();
            String a3 = artist3Input.getText();

            if (a1.isEmpty() || a2.isEmpty() || a3.isEmpty()) {
                throw new Exception("Please enter all 3 artist names.");
            }

            PlaylistController pc = new PlaylistController();
            currentPlaylistId = pc.createPlaylist(userId, playlistName);

            AutoPlaylistController controller = new AutoPlaylistController();
            recommendations = controller.buildAutoPlaylist(userId, a1, a2, a3);

            currentIndex = 0;

            showRecommendationScreen();

        } catch (Exception e) {
            JOptionPane.showMessageDialog(frame, e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
}

    public void showRecommendationScreen() {

        frame.getContentPane().removeAll();

        songDisplay = new JLabel("", SwingConstants.CENTER);
        songDisplay.setBounds(50, 40, 240, 30);
        songDisplay.setFont(new Font("Monospaced", Font.BOLD, 18));

        artistDisplay = new JLabel("", SwingConstants.CENTER);
        artistDisplay.setBounds(50, 60, 240, 30);
        artistDisplay.setFont(new Font("Monospaced", Font.PLAIN, 14));

        acceptBtn = new JButton("Accept");
        acceptBtn.setBackground(Color.green);
        rejectBtn = new JButton("Reject");
        rejectBtn.setBackground(Color.red);
        finishBtn = new JButton("Finish");

        acceptBtn.setBounds(40, 120, 120, 35);
        rejectBtn.setBounds(180, 120, 120, 35);
        finishBtn.setBounds(110, 170, 120, 35);

        acceptBtn.addActionListener(new acceptListener());
        rejectBtn.addActionListener(new rejectListener());
        finishBtn.addActionListener(new finishListener());

        frame.add(songDisplay);
        frame.add(artistDisplay);
        frame.add(acceptBtn);
        frame.add(rejectBtn);
        frame.add(finishBtn);

        showNextSong();

        frame.revalidate();
        frame.repaint();
    }

    public void showNextSong() {
        if (recommendations == null || currentIndex >= recommendations.size()) {
            JOptionPane.showMessageDialog(frame, "No more songs!");
            frame.remove(songDisplay);
            frame.remove(artistDisplay);
            frame.remove(acceptBtn);
            frame.remove(rejectBtn);
            frame.remove(finishBtn);
            frame.add(submit);
            OnLogin();
            return;
        }

        ScoredSong song = recommendations.get(currentIndex);

        songDisplay.setText(song.getSong().getSongName());
        artistDisplay.setText(song.getSong().getArtist());
    }

    class acceptListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            try {
                ScoredSong song = recommendations.get(currentIndex);

                PlaylistController pc = new PlaylistController();
                pc.addSongToPlaylist(currentPlaylistId, song.getSong().getSongId());

                currentIndex++;
                showNextSong();

            } catch (Exception ex) {
                JOptionPane.showMessageDialog(frame, ex.getMessage());
            }
        }
    }

    class rejectListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            try {
                int userId = Integer.parseInt(idInput.getText());
                ScoredSong song = recommendations.get(currentIndex);

                PlaylistController pc = new PlaylistController();
                pc.blacklistSong(userId, song.getSong().getSongId());

                currentIndex++;
                showNextSong();

            } catch (Exception ex) {
                JOptionPane.showMessageDialog(frame, ex.getMessage());
            }
        }
    }

    class finishListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            JOptionPane.showMessageDialog(frame, "Playlist complete!");
            frame.remove(songDisplay);
            frame.remove(artistDisplay);
            frame.remove(acceptBtn);
            frame.remove(rejectBtn);
            frame.remove(finishBtn);
            frame.add(submit);
            OnLogin();
        }
    }

    class submitLogin implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent event){

            String user = usernameInput.getText().trim();
            String pass = new String(passwordInput.getPassword()).trim();

            // Validate input
            if(user.isEmpty() || pass.isEmpty()){
                JOptionPane.showMessageDialog(frame, 
                    "Please enter database username and password.",
                    "Missing Input",
                    JOptionPane.WARNING_MESSAGE);
                return;
            }

            try {
                DataMgr.initialize(user, pass);  // <-- actually connect

                System.out.println("Connected to database successfully!");
                JOptionPane.showMessageDialog(frame, 
                    "Successfully Connected", 
                    "Login", 
                    JOptionPane.INFORMATION_MESSAGE);

                OnLogin();

            } catch (Exception e) {
                System.out.println("Connection failed: " + e.getMessage());
                JOptionPane.showMessageDialog(frame, 
                    e.getMessage(), 
                    "Connection Error", 
                    JOptionPane.ERROR_MESSAGE);
            }
        }
    }

    class selectionListener implements ActionListener{
        @Override
        public void actionPerformed(ActionEvent event){
            try {
            if(selection.getSelectedItem() == "New Playlist"){
                System.out.println("Selected New Playlist");
                OnPlaylist();
            } else if(selection.getSelectedItem() == "Get Stats"){
                System.out.println("Selected Genre Stats");
                OnPlaylist();
            } else if (selection.getSelectedItem() == "Auto Playlist Builder"){
                System.out.println("Selected Auto Playlist Builder");
                OnPlaylistBuilder();
            } else if (selection.getSelectedItem() == "Purge Playlist") {
                System.out.println("Selected Purge Playlist");
                OnPurgePlaylist();
            } else if (selection.getSelectedItem() == "Join Playlists") {
                System.out.println("Selected Join Playlists");
            }

        } catch (Exception e) {
            System.out.println("Selection Failed failed: " + e.getMessage());
            JOptionPane.showMessageDialog(frame, e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            
            return;
        }
        }
    }

    class backListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent event) {

            frame.remove(idPrompt);
            frame.remove(playlistNamePrompt);
            frame.remove(idInput);
            frame.remove(playlistNameInput);
            frame.remove(back);

            frame.getContentPane().removeAll();

            frame.revalidate();
            frame.repaint();

            frame.add(submit);
            OnLogin();
        }
    }

    class playlistListener implements ActionListener{
        @Override
        public void actionPerformed(ActionEvent event){
            try {
            // Get user input
                int userId = Integer.parseInt(idInput.getText());
                
                String playlistName = playlistNameInput.getText();

                // user inputs go to controller
                PlaylistController controller = new PlaylistController();
                controller.createPlaylist(userId, playlistName);

                // Show result
                JOptionPane.showMessageDialog(frame, playlistName + " created successfully!", "Create Playlist", JOptionPane.INFORMATION_MESSAGE);
                System.out.println(playlistName + " created successfully!");
        } catch (Exception e) {
            System.out.println("Error Creating Playlist: " + e.getMessage());
            JOptionPane.showMessageDialog(frame, e.getMessage(), "Error Creating Playlist:", JOptionPane.ERROR_MESSAGE);
            
            return;
        }
        }
    }
    public static void main(String[] args){
        new DatabaseGUI();
    }

}