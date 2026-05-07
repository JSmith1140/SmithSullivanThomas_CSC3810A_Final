package DatabasesFinal.BLL;

import java.sql.Date;

public class PlaylistStat {
    private String songName;
    private int plays;
    private int skips;
    private Date lastPlayed;

    /***
     * playlist stat constructor
     * @param songName
     * @param plays
     * @param skips
     * @param lastPlayed
     */
    public PlaylistStat(String songName, int plays, int skips, Date lastPlayed) {
        this.songName = songName;
        this.plays = plays;
        this.skips = skips;
        this.lastPlayed = lastPlayed;
    }

    public String getSongName() { return songName; } // get song name
    public int getPlays() { return plays; } // get plays
    public int getSkips() { return skips; } // get skips
    public Date getLastPlayed() { return lastPlayed; } // get last played
}
