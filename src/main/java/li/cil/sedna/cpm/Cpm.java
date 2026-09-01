package li.cil.sedna.cpm;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.Properties;

public final class Cpm {
    public static InputStream getBootRom() {
        return open("generated/bootrom.bin");
    }

    public static InputStream getFloppyImage() {
        return open("generated/cpm.img");
    }

    public static final class DiskGeometry {
        public static final int SIDES = 1;
        public static final int TRACKS;
        public static final int SECTORS_PER_TRACK;
        public static final int SECTOR_SIZE;
        public static final int BLOCK_SIZE;
        public static final int DIRECTORY_ENTRIES;
        public static final int RESERVED_TRACKS;

        public static int getImageSize() {
            return SIDES * TRACKS * SECTORS_PER_TRACK * SECTOR_SIZE;
        }

        static {
            final Properties geometry = new Properties();
            try (final InputStream stream = open("generated/geometry.properties")) {
                geometry.load(stream);
            } catch (final IOException e) {
                throw new UncheckedIOException(e);
            }
            TRACKS = value(geometry, "tracks");
            SECTORS_PER_TRACK = value(geometry, "sectorsPerTrack");
            SECTOR_SIZE = value(geometry, "sectorSize");
            BLOCK_SIZE = value(geometry, "blockSize");
            DIRECTORY_ENTRIES = value(geometry, "directoryEntries");
            RESERVED_TRACKS = value(geometry, "reservedTracks");
        }

        private DiskGeometry() {
        }

        private static int value(final Properties properties, final String key) {
            final String value = properties.getProperty(key);
            if (value == null) {
                throw new IllegalStateException("Missing geometry [" + key + "].");
            }
            return Integer.parseInt(value);
        }
    }

    private static InputStream open(final String resource) {
        final InputStream stream = Cpm.class.getClassLoader().getResourceAsStream(resource);
        if (stream == null) {
            throw new IllegalStateException("Missing resource [" + resource + "].");
        }
        return stream;
    }
}
