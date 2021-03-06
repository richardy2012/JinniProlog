// Init.java
package prolog.kernel;

import static java.lang.System.getProperty;
import static prolog.kernel.JavaIO.println;

final class Init {

    private final static int year = 2012;
    private final static String license = "License: GPL v. 3.0, http://www.gnu.org/licenses/gpl-3.0.txt";

    private final static int XBRAND_MAJOR = 12;
    private final static int XBRAND_FROM = 1999;
    private final static String XBRAND_NAME = "Jinni Java-based Prolog Compiler";
    private final static String XBRAND_COMP = "Paul Tarau";
    public final static int XBRAND_START_IDE = 1;

    final static int XBRAND_MINOR = 02;

    public static final String getPrologName() {
        return XBRAND_NAME;
    }

    public static final String getOsName() {
        return osname;
    }

    public static String userdir = null;
    public static String osname = null;

    static final void greeting(int verbosity) {
        if (JavaIO.isApplet) {
            return;
        }
        String jinni = XBRAND_NAME;

        userdir = getProperty("user.dir");
        if (null == userdir) {
            userdir = ".";
        }
        osname = getProperty("os.name");
        if (null == osname) {
            osname = "?";
        }
        String java = getProperty("java.version");
        if (null == java) {
            java = "";
        }
        String jvendor = getProperty("java.vendor");
        if (null == jvendor) {
            jvendor = "";
        }
        if ("".equals(jvendor) || ("Microsoft Corp.".equals(jvendor))) {
            jinni = XBRAND_NAME;
            java = "J#" + java;
        } else {
            //System.setProperty("java.rmi.server.codebase","file:/bin/prolog.jar"); //fails on J#
        }

    //JavaIO.println(System.getProperties().toString()); // $$
        String s = JavaIO.NL + "Starting " + jinni + " version " + XBRAND_MAJOR + "."
                + ((XBRAND_MINOR < 10) ? "0" : "")
                + XBRAND_MINOR + JavaIO.NL
                + "Copyright (C) " + XBRAND_COMP + " " + XBRAND_FROM + "-" + year + JavaIO.NL
                + license + JavaIO.NL
                + "Detected " + jvendor + " " + java + " Java, " + osname + JavaIO.NL
                + "User Dir " + userdir + JavaIO.NL;
        if (verbosity > 0) {
            println(s);
        }
    }

}
