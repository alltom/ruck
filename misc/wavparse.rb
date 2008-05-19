# stolen from
# http://www.mokehehe.com/assari/index.php?WAV%A5%D5%A5%A1%A5%A4%A5%EB%C6%E2%A4%CE%A5%C1%A5%E3%A5%F3%A5%AF%A4%F2%CE%F3%B5%F3%A4%B9%A4%EB

if ARGV.length < 1
    print "usage: [input wav filename]\n"
    exit
end
 
inwavfn = ARGV[0]

File::open(inwavfn, "rb") {|f|
    riff = f.read(4)
    if riff != 'RIFF'
        STDERR.print "not RIFF\n"
        exit
    end
    totalsizestr = f.read(4)
    totalsize = totalsizestr.unpack("L")[0]
 
    wave = f.read(4)
    if wave != 'WAVE'
        STDERR.print "not WAVE\n"
        exit
    end
 
    while !f.eof
        chk = f.read(4)
        chksizestr = f.read(4)
        chksize = chksizestr.unpack("L")[0]
 
        print chk, ",#{chksize}\n"
 
        f.seek(chksize, IO::SEEK_CUR)
    end
}