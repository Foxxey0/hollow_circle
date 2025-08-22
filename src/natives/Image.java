package natives;

import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import com.sun.jna.Structure;

@Structure.FieldOrder({"width", "height", "pixels"})
public class Image extends Structure {

    public int width;
    public int height;
    public Pointer pixels;

    public Image() {
        super();
    }

    public Image(Pointer p) {
        super(p);
    }

    @Override
    public String toString() {
        String string = "Image{" +
                "width=" + width +
                ", height=" + height +
                ", pixels=\n";

        for (int row = 0; row <= width -1; row++) {
            for (int col = 0; col <= height -1; col++) {
                int index = (row *width) +col;
                string += "red[" +index +"]: " +pixels.getInt((new Pixel().size() *index) +(Integer.BYTES *0)) +", ";
                string += "green[" +index +"]: " +pixels.getInt((new Pixel().size() *index) +(Integer.BYTES *1)) +", ";
                string += "blue[" +index +"]: " +pixels.getInt((new Pixel().size() *index) +(Integer.BYTES *2)) +", ";
            }
            string += "\n";
        }

        string += "}";


        return string;
    }

}
