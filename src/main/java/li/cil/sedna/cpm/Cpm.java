package li.cil.sedna.cpm;

import java.io.InputStream;

public final class Cpm {
    public static InputStream getBootRom() {
        return open("generated/bootrom.bin");
    }

    public static InputStream getFloppyImage() {
        return open("generated/cpm.img");
    }

    private static InputStream open(final String resource) {
        final InputStream stream = Cpm.class.getClassLoader().getResourceAsStream(resource);
        if (stream == null) {
            throw new IllegalStateException("Missing resource [" + resource + "].");
        }
        return stream;
    }
}
