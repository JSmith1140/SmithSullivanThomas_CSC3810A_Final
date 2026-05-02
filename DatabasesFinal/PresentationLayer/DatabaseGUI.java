package DatabasesFinal.PresentationLayer;
import java.awt.*;

import javax.management.Query;
import javax.swing.*;

import DatabasesFinal.BLL.PlaylistController;
import DatabasesFinal.DAL.DataMgr;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

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
        submit.setBounds(105, 140, 110, 30);
        submit.addActionListener(new submitLogin());

        back = new JButton("Back");
        back.setBackground(Color.red);
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
        selection.addItem("Option 3");
        selection.setBounds(60, 80, 200, 30);

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
            } else if (selection.getSelectedItem() == "Option 3"){
                System.out.println("Selected Option 3");
                OnPlaylist();
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
