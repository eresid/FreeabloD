module components.FreeabloIO;

import std.stdio;
import std.file;

import core.sync.mutex;

/**
 * original file:
 *      faio.cpp (26.03.2016)
 *      faio.h (26.03.2016)
 */
class FreeabloIO {

    private immutable string DIABDAT_MPQ = "DIABDAT.MPQ";
    private Mutex m;
    private HANDLE diabdat = null;

    enum FAFileMode {
        PlainFile,
        MPQFile
    }

    union FAFileUnion {
        File file;
        string filename;
        HANDLE mpqFile; // This is a StormLib HANDLE type
    }

   // A FILE* like container for either a normal FILE*, or a StormLib HANDLE
    struct FAFile {
        FAFileUnion data;
        FAFileMode mode;
    }

    bool init(string pathMPQ) {
        pathMPQ = pathMPQ is null ? DIABDAT_MPQ : pathMPQ;

        bool success = SFileOpenArchive(pathMPQ, 0, STREAM_FLAG_READ_ONLY, &diabdat);

        if (!success) {
            writeln("Failed to open %s with error %s", pathMPQ, GetLastError());
        }

        return success;
    }

    void quit() {
        if (diabdat != null) {
            SFileCloseArchive(diabdat);
        }
    }

    bool exists(string filename) {
        if (exists(filename)) {
            return true;
        }

        synchronized (m) {
            string stormPath = getStormLibPath(path);
            return SFileHasFile(diabdat, stormPath);
        }
    }

    FAFile fileOpen(string filename) {
        if (!exists(filename)) {
            synchronized (m) {
                string stormPath = getStormLibPath(path);

                if (!SFileHasFile(diabdat, stormPath)) {
                    writeln("File " ~ path ~ " not found");
                    return null;
                }

                FAFile file = new FAFile();
                file.data.mpqFile = malloc(sizeof(HANDLE));

                if (!SFileOpenFileEx(diabdat, stormPath, 0, file.data.mpqFile)) {
                    writeln("Failed to open %s in %s", filename, DIABDAT_MPQ);
                    delete file;
                    return null;
                }

                file.mode = FAFileMode.MPQFile;

                return file;
            }
        } else {
            File plainFile = new File(filename, "r");
            if (!exist(plainFile)) {
                return null;
            }

            FAFile file = new FAFile();
            file.mode = FAFileMode.PlainFile;
            file.data.file = plainFile;
            file.data.filename = filename;

            return file;
        }
    }

    real fileRead(ref void * ptr, real size, real count, FAFile stream) {

    }

    int fileClose(FAFile stream) {

    }

    int FAfseek (FAFile stream, real offset, int origin) {

    }

    real FAftell(FAFile stream) {

    }

    real FAsize(FAFile stream) {
        switch(stream.mode) {
            case FAFileMode.PlainFile: {
                return getSize(stream.data.filename);
            }

            case FAFileMode.MPQFile: {
                synchronized (m) {
                    return SFileGetFileSize(stream.data.mpqFile, null);
                }
            }
        }

        return 0;
    }

    int read32(ref FAFile file) {
        int tmp;
        fileRead(tmp, 4, 1, file);
        return tmp;
    }

    short read16(ref FAFile file) {
        short tmp;
        fileRead(tmp, 2, 1, file);
        return tmp;
    }

    byte read8(ref FAFile file) {
        byte tmp;
        fileRead(tmp, 1, 1, file);
        return tmp;
    }

    string readCString(FAFile file, real ptr) {
        string retval = "";

        if (ptr) {
            FAfseek(file, ptr, SEEK_SET);
            char c = 0;

            real bytesRead = fileRead(c, 1, 1, file);

            while(c != '\0' && bytesRead) {
                retval += c;
                bytesRead = fileRead(c, 1, 1, file);
            }
        }

        return retval;
    }

	string readCStringFromWin32Binary(FAFile file, real ptr, real offset) {
	    if (ptr) {
	        return readCString(file, ptr - offset);
	    }

        return "";
	}

//    string getMPQFileName() {
//        bfs::directory_iterator end;
//        for(bfs::directory_iterator entry(".") ; entry != end; entry++)
//        {
//            if (!bfs::is_directory(*entry))
//            {
//                if(boost::iequals(entry->path().leaf().generic_string(), DIABDAT_MPQ))
//                {
//                    return entry->path().leaf().generic_string();
//                }
//            }
//        }
//
//        writeln("Failed to find %s in current directory", DIABDAT_MPQ);
//
//        return "";
//    }
}