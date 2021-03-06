package prolog3d;

import javax.media.j3d.*;
import javax.vecmath.*;
import com.sun.j3d.utils.geometry.*;

/**
 *
 * @author Brad
 */
public class Sphere3D extends Simple {

    /**
     *
     * @param c
     * @param t
     */
    public Sphere3D(Color3f c,float t) {
    super((Shape3D)(new Sphere()).getShape().cloneNode(true),makeApp(c,t)); 
    transformScale(defScale);
  }
  
    /**
     *
     * @param c
     */
    public Sphere3D(Color3f c) {
    this(c,transparency);
  } 
  
    /**
     *
     */
    public Sphere3D() {
    this(defCol,transparency);
  }
}