package DatabasesFinal.PresentationLayer;

import java.awt.*;
import javax.swing.*;

import DatabasesFinal.BLL.PlaylistController;
import DatabasesFinal.BLL.PlaylistStat;
import DatabasesFinal.BLL.PurgeController;
import DatabasesFinal.DAL.DataMgr;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import DatabasesFinal.BLL.AutoPlaylistController;
import DatabasesFinal.BLL.JoinPlaylistController;
import DatabasesFinal.BLL.ScoredSong;
import DatabasesFinal.BLL.SongCandidate;

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
    JLabel loginTitle;
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

    public DatabaseGUI() {
        // cross-platform look so that mac & windows look the same
        try {
            UIManager.setLookAndFeel(UIManager.getCrossPlatformLookAndFeelClassName());
        } catch (Exception e) {
            e.printStackTrace();
        }

        frame = new JFrame("Music Player DB");
        frame.setBackground(Color.gray);

        frame.setSize(560, 460);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        // center the window on screen
        frame.setLocationRelativeTo(null);
        frame.setLayout(null);

        usernamePrompt = new JLabel("Username: ", SwingConstants.CENTER);
        usernamePrompt.setBounds(100, 100, 90, 30);
        passwordPrompt = new JLabel("Password: ", SwingConstants.CENTER);
        passwordPrompt.setBounds(100, 145, 90, 30);

        submit = new JButton("Submit");
        submit.setBackground(Color.green);
        submit.setBorder(BorderFactory.createLineBorder(new Color(39, 174, 96), 3, false));
        submit.setBounds(210, 210, 130, 35);
        submit.addActionListener(new submitLogin());

        back = new JButton("Back");
        back.setBackground(Color.red);
        back.setBorder(BorderFactory.createLineBorder(new Color(192, 57, 43), 3, false));
        back.setBounds(210, 255, 130, 35);
        back.addActionListener(new backListener());

        usernameInput = new JTextField(20);
        usernameInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        usernameInput.setForeground(Color.BLACK);
        usernameInput.setBackground(Color.WHITE);
        usernameInput.setEditable(true);
        usernameInput.setBounds(200, 100, 220, 30); // set consistent width with password input

        passwordInput = new JPasswordField(20);
        passwordInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        passwordInput.setForeground(Color.BLACK);
        passwordInput.setBackground(Color.WHITE);
        passwordInput.setEditable(true);
        passwordInput.setBounds(200, 145, 220, 30); // set consistent width with username input

        frame.add(usernamePrompt);
        frame.add(passwordPrompt);
        frame.add(passwordInput);
        frame.add(usernameInput);
        frame.add(submit);
        frame.setVisible(true);
    }

    /***
     * Main page
     */
    public void OnLogin() {
        frame.remove(passwordPrompt);
        frame.remove(usernamePrompt);
        frame.remove(passwordInput);
        frame.remove(usernameInput);

        frame.repaint();

        JLabel loginTitle = new JLabel("Music System", SwingConstants.CENTER);
        loginTitle.setFont(new Font("Monospaced", Font.BOLD, 36));
        loginTitle.setBounds(0, 20, 560, 40);

        query = new JLabel("What do you want to do?", SwingConstants.CENTER);
        query.setFont(new Font("SansSerif", Font.BOLD, 14));
        query.setBounds(150, 80, 250, 30);

        selection = new JComboBox<String>();
        selection.addItem("New Playlist");
        selection.addItem("Get Playlist Stats");
        selection.addItem("Auto Playlist Builder");
        selection.addItem("Purge Playlist");
        selection.addItem("Join Playlists");
        selection.setBounds(150, 130, 250, 30);
        submit.setBounds(210, 190, 130, 35);
        back.setBounds(210, 225, 130, 35);

        for (ActionListener a : submit.getActionListeners()) {
            submit.removeActionListener(a);
        }
        submit.addActionListener(new selectionListener());

        frame.add(loginTitle);
        frame.add(selection);
        frame.add(query);

        // ensure components are updated when going to home screen
        frame.revalidate();
        frame.repaint();
    }

    /***
     * Playlist page
     */
    public void OnPlaylist() {
        frame.remove(loginTitle);
        frame.remove(selection);
        frame.remove(query);
        frame.repaint();
        frame.add(back);

        JLabel title = new JLabel("New Playlist", SwingConstants.CENTER);
        title.setFont(new Font("Monospaced", Font.BOLD, 24));
        title.setBounds(0, 20, 560, 30); 

        idPrompt = new JLabel("User ID: ", SwingConstants.CENTER);
        idPrompt.setBounds(80, 100, 100, 30);
        playlistNamePrompt = new JLabel("Playlist Name: ", SwingConstants.CENTER);
        playlistNamePrompt.setBounds(80, 150, 120, 30);

        idInput = new JTextField(20);
        idInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        idInput.setForeground(Color.BLACK);
        idInput.setBackground(Color.WHITE);
        idInput.setEditable(true);
        idInput.setBounds(210, 100, 220, 30); // set consistent width with playlist name input

        playlistNameInput = new JTextField(20);
        playlistNameInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        playlistNameInput.setForeground(Color.BLACK);
        playlistNameInput.setBackground(Color.WHITE);
        playlistNameInput.setEditable(true);
        playlistNameInput.setBounds(210, 150, 220, 30); // set consistent width with user id input

        submit.setBounds(210, 210, 130, 35);
        back.setBounds(210, 255, 130, 35);

        for (ActionListener a : submit.getActionListeners()) {
            submit.removeActionListener(a);
        }
        submit.addActionListener(new playlistListener());
        back.addActionListener(new backListener());

        frame.add(title);
        frame.add(idPrompt);
        frame.add(playlistNamePrompt);
        frame.add(idInput);
        frame.add(playlistNameInput);
    }

    /***
     * playlist stats
     */
    public void OnPlaylistStats() {

        frame.getContentPane().removeAll();

        JLabel title = new JLabel("Playlist Stats", SwingConstants.CENTER);
        title.setBounds(170, 20, 220, 30);
        title.setFont(new Font("Monospaced", Font.BOLD, 24));

        // reuse playlist name and id inputs from create playlist screen for stats input
        idPrompt = new JLabel("User ID:", SwingConstants.RIGHT);
        idPrompt.setBounds(70, 90, 110, 30);

        playlistNamePrompt = new JLabel("Playlist Name:", SwingConstants.RIGHT);
        playlistNamePrompt.setBounds(70, 135, 110, 30);

        idInput = new JTextField();
        idInput.setBounds(190, 90, 220, 30);

        playlistNameInput = new JTextField();
        playlistNameInput.setBounds(190, 135, 220, 30);

        JButton loadBtn = new JButton("Load");
        loadBtn.setBounds(290, 185, 120, 35);

        back.setBounds(150, 185, 120, 35);

        loadBtn.addActionListener(new playlistStatsListener());
        back.addActionListener(new backListener());

        frame.add(title);
        frame.add(idPrompt);
        frame.add(idInput);
        frame.add(playlistNamePrompt);
        frame.add(playlistNameInput);
        frame.add(loadBtn);
        frame.add(back);

        frame.revalidate();
        frame.repaint();
    }

    /**
     * shows stats table
     * @param stats
     */
    public void showStatsTable(List<PlaylistStat> stats) {

        frame.getContentPane().removeAll();

        String[] columns = { "Song", "Plays", "Skips", "Last Played" };

        Object[][] data = new Object[stats.size()][4];

        for (int i = 0; i < stats.size(); i++) {
            PlaylistStat s = stats.get(i);

            data[i][0] = s.getSongName();
            data[i][1] = s.getPlays();
            data[i][2] = s.getSkips();
            data[i][3] = s.getLastPlayed();
        }

        JTable table = new JTable(data, columns);
        table.getColumnModel().getColumn(0).setPreferredWidth(200);
        table.setFont(new Font("Monospaced", Font.PLAIN, 12));
        table.setRowHeight(22);
        table.setEnabled(false); // read-only

        // add a scroll pane in case of many songs
        JScrollPane scrollPane = new JScrollPane(table);
        scrollPane.setBounds(40, 50, 470, 200);

        JLabel title = new JLabel("Playlist Stats", SwingConstants.CENTER);
        title.setBounds(170, 15, 220, 30);

        JButton backBtn = new JButton("Back");
        backBtn.setBounds(210, 265, 130, 35);

        backBtn.addActionListener(e -> {
            frame.getContentPane().removeAll();
            frame.add(submit);
            OnLogin();
        });

        frame.add(title);
        frame.add(scrollPane);
        frame.add(backBtn);

        frame.revalidate();
        frame.repaint();
    }

    /**
     * auto playlist builder
     */
    public void OnPlaylistBuilder() {
        frame.remove(selection);
        frame.remove(query);
        frame.remove(submit);
        frame.repaint();

        JLabel title = new JLabel("Auto Playlist Builder", SwingConstants.CENTER);
        title.setFont(new Font("Monospaced", Font.BOLD, 24));
        title.setBounds(0, 20, 560, 30);

        idPrompt = new JLabel("User ID: ", SwingConstants.RIGHT);
        idPrompt.setBounds(80, 70, 110, 30);
        artist1Prompt = new JLabel("Artist 1: ", SwingConstants.RIGHT);
        artist1Prompt.setBounds(80, 150, 110, 30);
        artist2Prompt = new JLabel("Artist 2: ", SwingConstants.RIGHT);
        artist2Prompt.setBounds(80, 190, 110, 30);
        artist3Prompt = new JLabel("Artist 3: ", SwingConstants.RIGHT);
        artist3Prompt.setBounds(80, 230, 110, 30);

        idInput = new JTextField(20);
        idInput.setFont(new Font("Monospaced", Font.PLAIN, 12));
        idInput.setForeground(Color.BLACK);
        idInput.setBackground(Color.WHITE);
        idInput.setEditable(true);
        idInput.setBounds(200, 70, 220, 30);

        playlistNamePrompt = new JLabel("Playlist Name: ", SwingConstants.RIGHT);
        playlistNamePrompt.setBounds(80, 110, 110, 30);

        playlistNameInput = new JTextField(20);
        playlistNameInput.setBounds(200, 110, 220, 30);

        artist1Input = new JTextField(20);
        artist1Input.setFont(new Font("Monospaced", Font.PLAIN, 12));
        artist1Input.setForeground(Color.BLACK);
        artist1Input.setBackground(Color.WHITE);
        artist1Input.setEditable(true);
        artist1Input.setBounds(200, 150, 220, 30);

        artist2Input = new JTextField(20);
        artist2Input.setFont(new Font("Monospaced", Font.PLAIN, 12));
        artist2Input.setForeground(Color.BLACK);
        artist2Input.setBackground(Color.WHITE);
        artist2Input.setEditable(true);
        artist2Input.setBounds(200, 190, 220, 30);

        artist3Input = new JTextField(20);
        artist3Input.setFont(new Font("Monospaced", Font.PLAIN, 12));
        artist3Input.setForeground(Color.BLACK);
        artist3Input.setBackground(Color.WHITE);
        artist3Input.setEditable(true);
        artist3Input.setBounds(200, 230, 220, 30);

        submit.setBounds(300, 285, 120, 35);
        back.setBounds(150, 285, 120, 35);

        for (ActionListener a : submit.getActionListeners()) {
            submit.removeActionListener(a);
        }
        submit.addActionListener(new autoPlaylistListener());
        back.addActionListener(new backListener());

        frame.add(title);
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

    /***
     * purge playlist gui
     */
    public void OnPurgePlaylist() {

        frame.getContentPane().removeAll();
        frame.repaint();

        JLabel title = new JLabel("Purge Playlist", SwingConstants.CENTER);
        title.setFont(new Font("Monospaced", Font.BOLD, 24));
        title.setBounds(0, 20, 560, 30);

        JLabel userIdLabel = new JLabel("User ID:", SwingConstants.RIGHT);
        userIdLabel.setBounds(80, 90, 120, 30);

        JTextField userIdInput = new JTextField();
        userIdInput.setBounds(210, 90, 200, 30);

        JLabel playlistIdLabel = new JLabel("Playlist ID:", SwingConstants.RIGHT);
        playlistIdLabel.setBounds(80, 140, 120, 30);

        JTextField playlistIdInput = new JTextField();
        playlistIdInput.setBounds(210, 140, 200, 30);

        JButton submitBtn = new JButton("Purge");
        submitBtn.setBounds(200, 200, 150, 35);
        submitBtn.setBackground(Color.RED);
        back.setBorder(BorderFactory.createLineBorder(new Color(192, 57, 43), 3, false));

        JButton backBtn = new JButton("Back");
        backBtn.setBounds(200, 245, 150, 30);

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

        frame.add(title);
        frame.add(userIdLabel);
        frame.add(userIdInput);
        frame.add(playlistIdLabel);
        frame.add(playlistIdInput);
        frame.add(submitBtn);
        frame.add(backBtn);

        frame.revalidate();
        frame.repaint();
    }

    /***
     * show purge results screen
     * @param removedSongs
     */
    public void showPurgeResultsScreen(List<String> removedSongs) {

        frame.getContentPane().removeAll();
        frame.repaint();

        JLabel title = new JLabel("Purge Results", SwingConstants.CENTER);
        title.setBounds(150, 20, 250, 30);
        title.setFont(new Font("Segoe UI", Font.BOLD, 20));
        title.setBorder(BorderFactory.createEmptyBorder(0, 0, 10, 0));

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
        scrollPane.setBounds(80, 65, 390, 190);
        scrollPane.setBorder(BorderFactory.createEmptyBorder());
        scrollPane.getVerticalScrollBar().setUI(new javax.swing.plaf.basic.BasicScrollBarUI() {
            @Override
            protected void configureScrollBarColors() {
                this.thumbColor = new Color(180, 180, 180);
                this.trackColor = new Color(240, 240, 240);
            }
        });

        JButton continueBtn = new JButton("Continue");
        continueBtn.setBounds(200, 270, 150, 35);

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

    /***
     * show the reecommendation screen
     */
    public void showRecommendationScreen() {

        frame.getContentPane().removeAll();

        songDisplay = new JLabel("", SwingConstants.CENTER);
        songDisplay.setBounds(130, 70, 300, 35);
        songDisplay.setFont(new Font("Monospaced", Font.BOLD, 18));

        artistDisplay = new JLabel("", SwingConstants.CENTER);
        artistDisplay.setBounds(130, 110, 300, 30);
        artistDisplay.setFont(new Font("Monospaced", Font.PLAIN, 14));

        acceptBtn = new JButton("Accept");
        acceptBtn.setBackground(Color.green);
        rejectBtn = new JButton("Reject");
        rejectBtn.setBackground(Color.red);
        finishBtn = new JButton("Finish");

        acceptBtn.setBounds(100, 180, 140, 40);
        acceptBtn.setBorder(BorderFactory.createLineBorder(new Color(39, 174, 96), 4, false));
        rejectBtn.setBounds(310, 180, 140, 40);
        rejectBtn.setBorder(BorderFactory.createLineBorder(new Color(192, 57, 43), 4, false));

        finishBtn.setBounds(205, 235, 140, 35);

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

    /***
     * show next song
     */
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

    /***
     * join playlists screen
     */
    public void OnJoinPlaylists() {
        frame.getContentPane().removeAll();
        frame.repaint();


        JLabel title = new JLabel("Join Playlists", SwingConstants.CENTER);
        title.setFont(new Font("Monospaced", Font.BOLD, 24));
        title.setBounds(0, 20, 560, 30);

        JLabel user1Label = new JLabel("User 1 ID:", SwingConstants.RIGHT);
        user1Label.setBounds(70, 70, 120, 30);

        JTextField user1Input = new JTextField();
        user1Input.setBounds(200, 70, 200, 30);

        JLabel playlist1Label = new JLabel("Playlist 1 ID:", SwingConstants.RIGHT);
        playlist1Label.setBounds(70, 110, 120, 30);

        JTextField playlist1Input = new JTextField();
        playlist1Input.setBounds(200, 110, 200, 30);

        JLabel user2Label = new JLabel("User 2 ID:", SwingConstants.RIGHT);
        user2Label.setBounds(70, 150, 120, 30);

        JTextField user2Input = new JTextField();
        user2Input.setBounds(200, 150, 200, 30);

        JLabel playlist2Label = new JLabel("Playlist 2 ID:", SwingConstants.RIGHT);
        playlist2Label.setBounds(70, 190, 120, 30);

        JTextField playlist2Input = new JTextField();
        playlist2Input.setBounds(200, 190, 200, 30);

        JLabel newNameLabel = new JLabel("New Playlist Name:", SwingConstants.RIGHT);
        newNameLabel.setBounds(70, 230, 120, 30);

        JTextField newNameInput = new JTextField();
        newNameInput.setBounds(200, 230, 200, 30);

        JButton joinBtn = new JButton("Join");
        joinBtn.setBackground(Color.green);
        joinBtn.setBorder(BorderFactory.createLineBorder(new Color(39, 174, 96), 3, false));
        joinBtn.setBounds(200, 280, 150, 35);

        JButton backBtn = new JButton("Back");
        backBtn.setBackground(Color.red);
        back.setBorder(BorderFactory.createLineBorder(new Color(192, 57, 43), 3, false));
        backBtn.setBounds(200, 325, 150, 30);

        joinBtn.addActionListener(e -> {
            try {
                int u1 = Integer.parseInt(user1Input.getText());
                int p1 = Integer.parseInt(playlist1Input.getText());
                int u2 = Integer.parseInt(user2Input.getText());
                int p2 = Integer.parseInt(playlist2Input.getText());
                String newName = newNameInput.getText().trim();

                if (newName.isEmpty()) {
                    throw new Exception("Enter a new playlist name.");
                }

                JoinPlaylistController controller = new JoinPlaylistController();

                List<SongCandidate> songs = controller.buildJointPlaylist(u1, u2, p1, p2);

                PlaylistController pc = new PlaylistController();
                int newPlaylistId = pc.createPlaylist(u1, newName);
                int newPlaylistId2 = pc.createPlaylist(u2, newName);

                for (SongCandidate song : songs) {
                    pc.addSongToPlaylist(newPlaylistId, song.getSongId());
                    pc.addSongToPlaylist(newPlaylistId2, song.getSongId());
                }
                showJoinResultsScreen(songs);

            } catch (Exception ex) {
                JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            }
        });

        backBtn.addActionListener(e -> {
            frame.getContentPane().removeAll();
            frame.add(submit);
            OnLogin();
        });

        frame.add(title);
        frame.add(user1Label);
        frame.add(user1Input);
        frame.add(playlist1Label);
        frame.add(playlist1Input);
        frame.add(user2Label);
        frame.add(user2Input);
        frame.add(playlist2Label);
        frame.add(playlist2Input);
        frame.add(newNameLabel);
        frame.add(newNameInput);
        frame.add(joinBtn);
        frame.add(backBtn);

        frame.revalidate();
        frame.repaint();
    }

    /***
     * show join results screen
     * @param songs
     */
    public void showJoinResultsScreen(List<SongCandidate> songs) {

        frame.getContentPane().removeAll();
        frame.repaint();

        JLabel title = new JLabel("Joined Playlist", SwingConstants.CENTER);
        title.setBounds(150, 20, 250, 30);
        title.setFont(new Font("Segoe UI", Font.BOLD, 18));

        JTextArea textArea = new JTextArea();
        textArea.setEditable(false);

        if (songs.isEmpty()) {
            textArea.setText("No songs matched both users.");
        } else {
            textArea.append("Songs in new playlist:\n\n");
            for (SongCandidate song : songs) {
                textArea.append(song.getSongName() + "\n");
            }
        }

        JScrollPane scrollPane = new JScrollPane(textArea);
        scrollPane.setBounds(80, 65, 390, 190);

        JButton doneBtn = new JButton("Done");
        doneBtn.setBounds(200, 270, 150, 35);

        doneBtn.addActionListener(e -> {
            frame.getContentPane().removeAll();
            frame.add(submit);
            OnLogin();
        });

        frame.add(title);
        frame.add(scrollPane);
        frame.add(doneBtn);

        frame.revalidate();
        frame.repaint();
    }

    /***
     * accept listener
     */
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

    /***
     * reject listener
     */
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

    /***
     * finish listener
     */
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

    /***
     * submit login
     */
    class submitLogin implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent event) {

            String user = usernameInput.getText().trim();
            String pass = new String(passwordInput.getPassword()).trim();

            // Validate input
            if (user.isEmpty() || pass.isEmpty()) {
                JOptionPane.showMessageDialog(frame,
                        "Please enter database username and password.",
                        "Missing Input",
                        JOptionPane.WARNING_MESSAGE);
                return;
            }

            try {
                DataMgr.initialize(user, pass);

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

    /***
     * selection listener
     */
    class selectionListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent event) {
            try {
                if ("New Playlist".equals(selection.getSelectedItem())) {
                    System.out.println("Selected New Playlist");
                    OnPlaylist();
                } else if ("Get Playlist Stats".equals(selection.getSelectedItem())) {
                    System.out.println("Selected Get Playlist Stats");
                    OnPlaylistStats();
                } else if ("Auto Playlist Builder".equals(selection.getSelectedItem())) {
                    System.out.println("Selected Auto Playlist Builder");
                    OnPlaylistBuilder();
                } else if ("Purge Playlist".equals(selection.getSelectedItem())) {
                    System.out.println("Selected Purge Playlist");
                    OnPurgePlaylist();
                } else if ("Join Playlists".equals(selection.getSelectedItem())) {
                    System.out.println("Selected Join Playlists");
                    OnJoinPlaylists();
                }

            } catch (Exception e) {
                System.out.println("Selection Failed failed: " + e.getMessage());
                JOptionPane.showMessageDialog(frame, e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);

                return;
            }
        }
    }

    /***
     * back listener
     */
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

    /***
     * playlist listener
     */
    class playlistListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent event) {
            try {
                // Get user input
                int userId = Integer.parseInt(idInput.getText());

                String playlistName = playlistNameInput.getText();

                // user inputs go to controller
                PlaylistController controller = new PlaylistController();
                controller.createPlaylist(userId, playlistName);

                // Show result
                JOptionPane.showMessageDialog(frame, playlistName + " created successfully!", "Create Playlist",
                        JOptionPane.INFORMATION_MESSAGE);
                System.out.println(playlistName + " created successfully!");
            } catch (Exception e) {
                System.out.println("Error Creating Playlist: " + e.getMessage());
                JOptionPane.showMessageDialog(frame, e.getMessage(), "Error Creating Playlist:",
                        JOptionPane.ERROR_MESSAGE);

                return;
            }
        }
    }

    /***
     * auto playlist listener
     */
    class autoPlaylistListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent event) {
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

    /***
     * playlist stats listener
     */
    class playlistStatsListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            try {
                int userId = Integer.parseInt(idInput.getText());
                String playlistName = playlistNameInput.getText();

                PlaylistController controller = new PlaylistController();
                List<PlaylistStat> stats = controller.playlistStats(userId, playlistName);

                showStatsTable(stats);

            } catch (Exception ex) {
                JOptionPane.showMessageDialog(frame, ex.getMessage());
            }
        }
    }

    public static void main(String[] args) {
        new DatabaseGUI();
    }

}
