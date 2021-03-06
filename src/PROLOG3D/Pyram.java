package prolog3d;

import javax.media.j3d.*;
import javax.vecmath.*;

/**
 *
 * @author Brad
 */
public class Pyram extends Simple {
  // to be about the same size as other Simple objects
 
    /**
     *
     */
      public static double scale=2*(defScale/0.2); 
 
    /**
     *
     */
    public Pyram() {
    super(new PyramShape(),Simple.defApp);
    transformScale(scale);
  }
  
    /**
     *
     * @param c
     * @param t
     */
    public Pyram(Color3f c,float t) {
    // BUG: color defined at creation time - insensitive to setColor
    super(new PyramShape(c),makeApp(c,t));
    //                              ^^ ignored !!!
    //transformScale(scale); // used in Edge3D
  }
  
    /**
     *
     * @param c
     */
    public Pyram(Color3f c) {
    super(new PyramShape(c));
    //transformScale(scale);
  }
   
    /**
     *
     * @param dif
     * @param r
     */
    public void draw(Tuple3f dif,float r) {
    ((PyramShape)shape3d).geom.draw(dif,r);
  }
}

