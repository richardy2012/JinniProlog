package prolog.core;

import prolog.kernel.*;
import prolog.logic.*;

import java.io.*;
import static java.lang.Class.forName;
import static java.lang.System.arraycopy;
import java.lang.reflect.*;
import java.util.Arrays;
import static java.util.Arrays.stream;
import java.util.stream.Collectors;
import static java.util.stream.Collectors.summingInt;
import java.util.zip.*;
import static prolog.core.Transport.file2bytes;
import static prolog.kernel.JavaIO.toWriter;
import static prolog.kernel.JavaIO.toWriter;
import static prolog.kernel.Top.getPrologVersion;
import static prolog.logic.Interact.errmes;
import static prolog.logic.Interact.warnmes;
import static prolog.logic.Prolog.dump;

/**
 * Converts byte code to Java classes that can be included in jar files and
 * autoloaded, for programs that run from the Web or which, for some reason,
 * should not depend on external files.
 */
public class Javafier {

    /**
     *
     */
    public static String TARGET = "Wam";

    /**
     *
     */
    public static String TARGET_DIR = "../prolog/kernel/";
    private static final short codeword = 27182; // for obfuscation

    private static boolean inactive = false;
    private static final boolean zipping = true; //

    /**
     *
     */
    public static final void turnOff() {
        inactive = true;
    }

    /**
     *
     */
    public static int SPLIT = 7200;

    /**
     *
     */
    public static void run() {
        javafy(Interact.PROLOG_BYTECODE_FILE);
    }

    /**
     *
     * @param ByteCodeFile
     */
    public static void javafy(String ByteCodeFile) {
        dump("Starting conversion of " + ByteCodeFile + " Prolog bytecode file to Java");
        try {
            javafy0(ByteCodeFile);
            dump("conversion of " + ByteCodeFile + " to Java succeded");
        } catch (PrologException e) {
            errmes("conversion of " + ByteCodeFile + " to Java failed", e);
        }
    }

    /**
     *
     * @param fname
     * @return
     * @throws ExistenceException
     */
    public static byte[] toBytes(String fname) throws ExistenceException {
        try {
            return file2bytes(fname);
        } catch (IOException e) {
            throw new ExistenceException("unable to read: " + fname);
        }
    }

    private static PrologWriter newCodeWriter(int ctr) {
        String sname = TARGET_DIR + TARGET + ctr + ".java";
        PrologWriter out = toWriter(sname);
        out.println("package prolog.kernel;\n");
        out.println("import prolog.logic.*;\n");
        out.println("\nclass "
                + TARGET
                + ctr
                + " implements Stateful {\nstatic short[] code={");
        return out;
    }

    private static void javafy0(String infile) throws PrologException {
        byte[] bytes = toBytes(infile);
        if (zipping) {
            bytes = zip(bytes);
        }
        short[] bs = fuse(bytes);

        int ctr = 0;
        int i = 1;
        PrologWriter out = newCodeWriter(ctr);
        for (int b : bs) {
            out.print("" + b);
            if (0 == (i % SPLIT)) {
                // end class
                    out.println("};}");
                    out.close();
                // new class Wam+ctr
                out = newCodeWriter(ctr);
                ctr++;
            } else {
                out.println(",");
            }
            i++;
        }
        // Final file
        if (0 != (i % SPLIT)) {
            out.println("};}"); // unless already done
        }
        out.close();

        // new class Wam
        String wname = TARGET_DIR + TARGET + ".java";
        out = toWriter(wname);
        out.println("package prolog.kernel;\n");
        out.println("import prolog.logic.*;\n");
        out.println("\npublic class " + TARGET + " implements Stateful {");

        out.println("public static final short[][] getByteCode() {");
        out.println("short[][] code=new short[maxwam][];");
        for (int j = 0; j < ctr; j++) {
            out.println("code[" + j + "]=" + TARGET + j + ".code;");
        }
        out.println("return code;\n}\n");

        out.println("final static public int maxwam=" + ctr + ";\n");

        out.println("final static public int prologVersion() {return "
                + getPrologVersion()
                + ";}\n}");

        out.close();

        // end class
    }

    /**
     *
     * @param codeStore
     * @return
     * @throws Exception
     */
    public static boolean activateBytecode(CodeStore codeStore) throws Exception {

        if (inactive) {
            return false;
        }

        short[][] scodes = null;

        try {
            String className = "prolog.kernel.Wam";
            String methodName = "getByteCode";
            Class C = forName(className);
            Method theMethod = C.getMethod(methodName, (Class[]) null);
            scodes = (short[][]) theMethod.invoke(C, (Object[]) null);
        } catch (ClassNotFoundException | NoSuchMethodException | SecurityException | IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
            //JavaIO.errmes("unable to activate Prolog bytecode from Java class",e);
        }

        if (null == scodes) {
            return false;
        }

        try {
            String className = "prolog.kernel.Wam";
            String methodName = "prologVersion";
            Class C = forName(className);
            Method theMethod = C.getMethod(methodName, (Class[]) null);
            Integer Version = (Integer) theMethod.invoke(C, (Object[]) null);
            int vers = Version;
            int vers0 = getPrologVersion();
            if (vers0 != vers) {
                warnmes("Prolog source version " + vers0 + " different from runtime version: " + vers);
            }
        } catch (ClassNotFoundException | NoSuchMethodException | SecurityException | IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
            warnmes("unable to get prolog version information->" + e);
        }

        int codesize = stream(scodes)
                .collect(summingInt(sc -> sc.length));

        short[] scode = new short[codesize];

        int n = 0;
        for (short[] instr : scodes) {
            for (short c : instr) {
                scode[n++] = c;
            }
        }

        byte[] code = unfuse(scode);

        if (zipping) {
            code = unzip(code);
        }

        try (PrologReader r
                = new PrologReader(new ByteArrayInputStream(code))) {
            (new CodeIO(codeStore)).floadfromReader(r);
            return true;
        } catch (IOException e) {
            warnmes("failed to load code from internal files, code length: " + code.length);
            return false;
        }
    }

    /**
     *
     * @param bs
     * @return
     */
    public static byte[] zip(byte[] bs) {
        Deflater zipper = new Deflater(); //Deflater.BEST_COMPRESSION);
        zipper.setInput(bs);
        zipper.finish();
        byte[] zs = new byte[bs.length];
        zipper.deflate(zs);
        int l = zipper.getTotalOut();
        //Prolog.dump("zip: "+l+"<"+bs.length);
        bs = new byte[l];
        arraycopy(zs, 0, bs, 0, l);

        return bs;
    }

    /**
     *
     * @param zs
     * @return
     */
    public static byte[] unzip(byte[] zs) {
        Inflater unzipper = new Inflater();
        byte[] cs = new byte[zs.length * 10];
        try {
            unzipper.setInput(zs);
            unzipper.inflate(cs);
        } catch (DataFormatException e) {
            errmes("unable to get zipped Prolog bytecode from Java class", e);
            return null;
        }
        int l = unzipper.getTotalOut();
        byte[] bs = new byte[l];
        arraycopy(cs, 0, bs, 0, l);
        return bs;
    }

    private static short xor(short A, short B) {
        return (short) ((int) A ^ (int) B);
        //return A;
    }

    private static short encode(short plain, short key) {
        return xor(plain, key);
    }

    private static short decode(short cipher, short key) {
        return xor(cipher, key);
    }

    private static short fuse(byte a, byte b) {
        short i = (short) ((toInt(a) << 8) | toInt(b));
        return encode(i, codeword);
    }

    private static byte[] unfuse(short i) {
        i = decode(i, codeword);
        byte[] unfused = new byte[2];
        unfused[0] = (byte) (((int) i) >> 8);
        unfused[1] = (byte) (((int) i) << 24 >> 24);
        return unfused;
    }

    private static int toInt(byte b) {
        int x = b;
        if (x < 0) {
            x = 256 + x;
        }
        return x;
    }

    static final short[] fuse(byte[] bs) {
        int bl = bs.length;
        int cl = (0 == bl % 2) ? (bl / 2) : (bl + 1) / 2;
        short[] cs = new short[cl + 1];
        cs[cl] = (short) (bl % 2);
        for (int i = 0; i < bs.length; i += 2) {
            byte a = bs[i];
            byte b = ((i + 1) < bs.length) ? bs[i + 1] : 0;
            cs[i / 2] = fuse(a, b);
        }

        return cs;
    }

    static final byte[] unfuse(short[] cs) {
        int cl = cs.length;
        boolean odd = (1 == cs[cl - 1]);
        cl--;
        int bl = (odd) ? (cl * 2 - 1) : (cl * 2);
        byte[] bs = new byte[bl];
        for (int i = 0; i < cl; i++) {
            byte[] us = unfuse(cs[i]);
            bs[2 * i] = us[0];
            if (2 * i + 1 < bs.length) {
                bs[2 * i + 1] = us[1];
            }
        }

        return bs;
    }
}
