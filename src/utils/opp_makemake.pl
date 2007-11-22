eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}' && eval 'exec perl -S $0 $argv:q'
  if 0;

#!perl
#line 6
#
# opp_makemake.pl
#
#  Creates an MSVC makefile for a given OMNeT++/OMNEST model.  FIXME
#  Assumes that .ned, .msg, .cc and .h files are in one directory.
#  The name of the program defaults to the name of the directory ('myproject').
#
#  --VA
#

use Cwd;
use Config;

$ARG0 = $0;
$progname = $ARG0;

$arch = $Config{'archname'};
$isCygwin = ($arch =~ /cygwin/i);

$isWindows = ($ENV{OS} =~ /windows/i) ? 1 : 0;

if ($isWindows && $ENV{OS} ne "Windows_NT") {
    error("this program can only be used on Windows NT/2000/XP, but your OS environment variable says '$ENV{OS}'\n");
}

$isNMake = 1;

#
# process command line args
#
@args = @ARGV;
$makefile = "Makefile.vc";
$baseDir = "";
$type = "EXE";
$target = "";
$force = 0;
$linkWithObjects = 0;
$tstamp = 1;
$recursive = 0;
$userInterface = "ALL";
$ccExt = "";
$configFile = "";
$exportDefOpt = "";
$compileForDll = 0;
$ignoreNedFiles = 1;
@fragmentFiles = ();
@subdirs = ();
@exceptSubdirs = ();
@includeDirs = ();
@libDirs = ();
@libs = ();
@importLibs = ();
@extraArgs = ();


# process arg vector
while (@ARGV)
{
    $arg = shift @ARGV;
    if ($arg eq "-h" || $arg eq "--help") {
        usage();
        exit(1);
    }
    elsif ($arg eq "-f" || $arg eq "--force") {
        $force = 1;
    }
    elsif ($arg eq "-e" || $arg eq "--ext") {
        $ccExt = shift;
    }
    elsif ($arg eq "-o" || $arg eq "--outputfile") {
        $target = shift;
    }
    elsif ($arg eq "-N" || $arg eq "--ignore-ned") {
        error("obsolete option $arg, please remove (dynamic NED loading is now the default)");
    }
    elsif ($arg eq "-r" || $arg eq "--recurse") {
        $recursive = 1;
    }
    elsif ($arg eq "-X" || $arg eq "--except") {
        my $dir = shift;
        push(@exceptSubdirs, $dir);
    }
    elsif ($arg =~ /^-X/) {
        my $dir = substr($arg, 2);
        push(@exceptSubdirs, $dir);
    }
    elsif ($arg eq "-b" || $arg eq "--basedir") {
        $baseDir = shift;
    }
    elsif ($arg eq "-c" || $arg eq "--configfile") {
        $configFile = shift;
    }
    elsif ($arg eq "-n" || $arg eq "--nolink") {
        $type = "NOLINK";
    }
    elsif ($arg eq "-d" || $arg eq "--subdir") {
        push(@subdirs, $shift);
    }
    elsif ($arg =~ /^-d/) {
        $dir = substr($arg, 2);
        push(@subdirs, $dir);
    }
    elsif ($arg eq "-s" || $arg eq "--make-so") {
        $compileForDll = 1;
        $type = "SO";
    }
    elsif ($arg eq "-t" || $arg eq "--importlib") {
        my $importlib = shift;
        push(@importLibs, $importlib);
    }
    elsif ($arg eq "-S" || $arg eq "--fordll") {
        $compileForDll = 1;
    }
    elsif ($arg eq "-w" || $arg eq "--withobjects") {
        $linkWithObjects = 1;
    }
    elsif ($arg eq "-x" || $arg eq "--notstamp") {
        $tstamp = 1;
    }
    elsif ($arg eq "-u" || $arg eq "--userinterface") {
        my $userInterface = shift;
        $userInterface = uc($userInterface);
        if ($userInterface ne "ALL" && $userInterface ne "CMDENV" && $userInterface ne "TKENV") {
            error("$progname: -u: specify All, Cmdenv or Tkenv");
        }
    }
    elsif ($arg eq "-i" || $arg eq "--includefragment") {
        my $frag = shift;
        push(@fragmentFiles, $frag);
    }
    elsif ($arg eq "-I") {
        my $dir = shift;
        push(@includeDirs, $dir);
    }
    elsif ($arg =~ /^-I/) {
        my $dir = substr($arg, 2);
        push(@includeDirs, $dir);
    }
    elsif ($arg eq "-L") {
        my $dir = shift;
        push(@libDirs, $dir);
    }
    elsif ($arg =~ /^-L/) {
        my $dir = substr($arg, 2);
        push(@libDirs, $dir);
    }
    elsif ($arg =~ /^-l/) {
        my $lib = substr($arg, 2);
        push(@libs, $lib);
    }
    elsif ($arg eq "-P") {
        $exportDefOpt = shift;
    }
    elsif ($arg =~ /^-P/) {
        $exportDefOpt = substr($arg, 2);
    }
    else {
        # FIXME add support for "--" after which everything is extraArg
        if ($arg ne "--") {
            if ($arg =~ /^-/) {
                error("unrecognized option: $arg");
            }
            push(@extraArgs, $arg);
        }
    }
}

$makefile = $isNMake ? "Makefile.vc" : "Makefile";

if (-f $makefile && $force ne 1)
{
    error("use -f to force overwriting existing $makefile");
}

$makecommand = $isNMake ? 'nmake /nologo /f Makefile.vc' : 'make';

#FIXME $configFile is nmake only!
if ($configFile eq "") {
    # try to find it
    $progdir = $0;
    $progdir =~ s|\\|/|g;
    $progdir =~ s|/?[^/:]*$||g;
    $progdir = "." if ($progdir eq "");
    $progparentdir = $progdir;
    $progparentdir =~ s|/?[^/:]*/?$||;
    foreach $f ("configuser.vc", "../configuser.vc", "../../configuser.vc",
                "../../../configuser.vc", "../../../../configuser.vc",
                "../../../../../configuser.vc", "$progparentdir/configuser.vc",
                "$progdir/configuser.vc")
    {
        if (-f $f) {
             $configFile = $f;
             last;
        }
    }
    if ($configFile eq "") {
        print STDERR "$progname: warning: configuser.vc file not found -- try -c option or edit generated makefile\n";
    }

}
else {
    if (! -f $configFile) {
        error("$progname: error: file $configFile not found");
    }
}


#
# Prepare the variables for the template
#
$folder = cwd;
$folderName = $folder;
$folderName  =~ s/[\/\\]$//;  # remove trailing slash/backslash
$folderName  =~ s/.*[\/\\]//; # keep only part after last slash/backslash

print "Creating $makefile in $folder...\n";

$makecommand = $isNMake ? "make" : "nmake /nologo /f Makefile.vc";

$target = $target eq "" ? $folderName : $target;

@externaldirobjs = ();
@externaldirtstamps = ();
@objs = ();
@generatedHeaders = ();
@linkDirs = ();
@externalObjects = ();
@tstampDirs = ();
@msgfiles = ();
@msgccandhfiles = ();

$target = abs2rel($target);

@includeDirs = ();
@libDirs = ();

foreach $i (@includeDirs) {
    push(@includeDirs, abs2rel($i));
}
foreach $i (@libDirs) {
    push(@libDirs, abs2rel($i));
}

if (-f $makefile && !$force) {
    error("use -f to force overwriting existing $makefile");
}

#if ($baseDir ne "") {
#    error("specifying the base directory (-b option) is not supported, it is always the project directory");
#}

if ($configFile eq "")
{
    # try to find it
    my $progdir = $0;
    $progdir =~ s|\\|/|g;
    $progdir =~ s|/?[^/:]*$||g;
    $progdir = "." if ($progdir eq "");
    $progparentdir = $progdir;
    $progparentdir =~ s|/?[^/:]*/?$||;
    foreach $f ("configuser.vc", "../configuser.vc", "../../configuser.vc",
                "../../../configuser.vc", "../../../../configuser.vc",
                "../../../../../configuser.vc", "$progparentdir/configuser.vc",
                "$progdir/configuser.vc")
    {
        if (-f $f) {
             $configFile = $f;
             last;
        }
    }
    if ($configFile eq "") {
        warning("configuser.vc file not found -- try -c option or edit generated makefile");
    }
}
else
{
    if (! -f $configFile) {
        error("file $configfile not found");
    }
}

$configFile = abs2rel($configFile);


# try to determine if .cc or .cpp files are used
@ccfiles = glob("*.cc");
@cppfiles = glob("*.cpp");
if ($ccExt eq "") {
    if (@ccfiles == () && !@cppfiles == ()) {
        $ccExt = "cpp";
    }
    elsif (!@ccfiles == () && @cppfiles == ()) {
        $ccExt = "cc";
    }
    elsif (!@ccfiles == () && !@cppfiles == ()) {
        error("you have both .cc and .cpp files -- specify -e cc or -e cpp option to select which set of files to use");
    }
    else {
        $ccExt = "cc";  # if no files, use .cc extension
    }
}
else {
    if ($ccExt eq "cc" && @ccfiles == () && @cppfiles != ()) {
        warning("you specified -e cc but you have only .cpp files in this directory!");
    }
    if ($ccExt eq "cpp" && @ccfiles != () && @cppfiles == ()) {
        warning("you specified -e cpp but you have only .cc files in this directory!");
    }
}

$ccSuffix = ".$ccExt";
$objSuffix = $isNMake ? ".obj" : ".o";

# prepare subdirs. First, check that all specified subdirs exist
foreach $subdir (@subdirs) {
    if (! -d $subdir) {
        error("subdirectory '$subdir' does not exist");
    }
}

if ($recursive) {
    foreach $f (glob("*")) {
        if (-d $f && !grep(/\Q$f\E/, @exceptSubdirs)) {  #XXX check IGNORABLE_DIRS
            push(@subdirs, $f);
        }
    }
}

@subdirTargets = ();
foreach $subdir (@subdirs) {
    push(@subdirTargets, $subdir . ($isNMake ? "_dir" : ""));  #XXX make sure none contains "_dir" as substring
}

foreach $arg (@extraArgs) {
    if (-d $arg) {
        $arg = abs2rel($arg);
        push(@linkDirs, $arg);
    }
    elsif (-f $arg) {
        $arg = abs2rel($arg);
        push(@externalObjects, $arg);
    }
    else {
        error("'$arg' is neither an existing file/dir nor a valid option");
    }
}

if ($linkWithObjects) {
    foreach $i (@includeDirs) {
        if ($i ne ".") {
            push(@externaldirobjs, "$i/*.$objSuffix");
        }
    }
}

foreach $i (@linkDirs) {
    push(@externaldirobjs, "$i/*.$objSuffix");
}

foreach $i (@includeDirs) {
    if ($tstamp && $i ne ".") {
        push(@tstampDirs, $i);
    }
}

foreach $i (@linkDirs) {
    if ($tstamp) {
        push(@tstampDirs, $i);
    }
}
foreach $i (@tstampDirs) {
    push(@externaldirtstamps, quote("$i/.tstamp"));
}

$objpatt = $ignoreNedFiles ? "*.msg *.$ccExt" : "*.ned *.msg *.$ccExt";
foreach $i (glob($objpatt))
{
    $i =~ s/\*[^ ]*//g;
    $i =~ s/[^ ]*_n\.$ccExt$//g;
    $i =~ s/[^ ]*_m\.$ccExt$//g;
    $i =~ s/\.ned$/_n.$objSuffix/g;
    $i =~ s/\.msg$/_m.$objSuffix/g;
    $i =~ s/\.$ccExt$/.$objSuffix/g;
    if ($i ne '') {
        push(@objs, $i);
    }
}

@msgfiles = glob("*.msg");
foreach $i (@msgfiles) {
    $h = $i; $h =~ s/\.msg$/_m.h/;
    $cc = $i; $cc =~ s/\.msg$/_m$ccSuffix/;
    push(@generatedHeaders, $h);
    push(@msgccandhfiles, $h);
    push(@msgccandhfiles, $cc);
}

$makefrags = "";
if (@fragmentFiles != ()) {
    foreach $frag (@fragmentFiles) {
        $makefrags .= "# inserted from file '$frag':\n";
        $makefrags .= readTextFile($frag) . "\n";
    }
}
else {
    $makefragFilename = $isNMake ? "makefrag.vc" : "makefrag";
    if (-f $makefragFilename) {
        $makefrags .= "# inserted from file '$makefragFilename':\n";
        $makefrags .= readTextFile($makefragFilename) . "\n";
    }
}

#FIXME TODO: into deps:  join(generatedHeaders);
$deps = "";

%m = (
    "nmake" =>  $isNMake,
    "target" =>  $target,
    "progname" =>  $isNMake ? "opp_nmakemake" : "opp_makemake",
    "args" =>  prefixQuoteJoin(@args),
    "configfile" =>  $configFile,
    "-L" =>  $isNMake ? "/libdir:" : "-L",
    "-l" =>  $isNMake ? "" : "-l",
    ".lib" =>  $isNMake ? ".lib" : "",
    "-u" =>  $isNMake ? "/include:" : "-u",
    "_dir" =>  "_dir",
    "cc" =>  $ccExt,
    "deps" =>  $deps,
    "exe" =>  $type == "EXE",
    "so" =>  $type == "SO",
    "nolink" =>  $type == "NOLINK",
    "allenv" => ($userInterface =~ /^A/) ne "",
    "cmdenv" =>  ($userInterface =~ /^C/) ne "",
    "tkenv" =>  ($userInterface =~ /^T/) ne "",
    "extdirobjs" =>  prefixQuoteJoin(@externaldirobjs),
    "extdirtstamps" =>  prefixQuoteJoin(@externaldirtstamps),
    "extraobjs" =>  prefixQuoteJoin(@externalObjects),
    "includepath" =>  prefixQuoteJoin(@includeDirs, "-I"),
    "libpath" =>  prefixQuoteJoin(@libDirs, (isNMake ? "/libpath:" : "-L")),
    "libs" =>  prefixQuoteJoin(@libs),
    "importlibs" =>  prefixQuoteJoin(@importLibs),
    "link-o" =>  $isNMake ? "/out:" : "-o",
    "makecommand" =>  $makecommand,
    "makefile" =>  $isNMake ? "Makefile.vc" : "Makefile",
    "makefrags" =>  $makefrags,
    "msgccandhfiles" =>  prefixQuoteJoin(@msgccandhfiles),
    "msgfiles" =>  prefixQuoteJoin(@msgfiles),
    "objs" =>  prefixQuoteJoin(@objs),
    "hassubdir" =>  @subdirs != (),
    "subdirs" =>  prefixQuoteJoin(@subdirs),
    "subdirtargets" =>  prefixQuoteJoin(@subdirTargets),
    "fordllopt" =>  $compileForDll ? "/DWIN32_DLL" : "",
    "dllexportmacro" =>  $exportDefOpt==null ? "" : ("-P" + $exportDefOpt),
);

$content = substituteIntoTemplate(template(), \%m, "{", "}");

open(OUT, ">$makefile");
print OUT $content;
close OUT;

print "$makefile created.\n";
print "Please type `nmake -f $makefile depend' NOW to add dependencies!\n";


#=====================================================================


sub substituteIntoTemplate($;$)
{
    my ($template,$mapref) = @_;
    my $startTag = "{";
    my $endTag = "}";
    my %map = %$mapref;

    my $buf = "";
    my $startTagLen = length($startTag);
    my $endTagLen = length($endTag);

    my $current = 0;
    while (true) {
        my $start = index($template, $startTag, $current);
        if ($start == -1) {
            last;
        }
        else {
            my $end = index($template, $endTag, $start);
            if ($end != -1) {
                my $tag = substr2($template, $start, $end + $endTagLen);
                #print("processing $tag\n");
                my $key = substr2($template, $start+$startTagLen, $end);
                if (index($key, "\n") != -1) {
                    die("template error: newline inside \"$tag\" (misplaced start/end tag?)");
                }
                my $isLineStart = $start==0 || substr($template, $start-1, 1) eq "\n";
                my $isNegated = substr($key, 0, 1) eq "~";
                if ($isNegated) {
                    $key = substr($key, 1);  # drop "~"
                }
                my $colonPos = index($key, ":");
                my $substringAfterColon = $colonPos == -1 ? "" : substr($key, $colonPos+1);
                if ($colonPos != -1) {
                    $key = substr2($key, 0, $colonPos); # drop ":..."
                }

                # determine replacement string, and possibly adjust start/end
                my $replacement = "";
                if ($colonPos != -1) {
                    if ($isLineStart && $substringAfterColon eq "") {
                        # replacing a whole line
                        if (getFromMapAsBool(\%map, $key) != $isNegated) {
                            # put line in: all variables OK
                        }
                        else {
                            # omit line
                            my $endLine = index($template, "\n", $end);
                            if ($endLine == -1) {
                                $endLine = length($template);
                            }
                            $replacement = "";
                            $end = $endLine;
                        }
                    }
                    else {
                        # conditional
                        if ($substringAfterColon eq "") {
                            die("template error: found \"$tag\" mid-line, but whole-line conditions should begin at the start of the line");
                        }
                        $replacement = getFromMapAsBool(\%map, $key)!=$isNegated ? $substringAfterColon : "";
                    }
                }
                else {
                    # plain replacement
                    if ($isNegated) {
                        die("template error: wrong syntax \"$tag\" (missing \":\"?)");
                    }
                    $replacement = getFromMapAsString(\%map, $key);
                }

                # do it: replace substring(start, end) with replacement, unless replacement==null
                $buf .= substr2($template, $current, $start);  # template code up to the {...}
                $buf .= $replacement;
                $current = $end + $endTagLen;
            }
        }
    }
    $buf .= substr($template, $current);  # rest of the template
    return $buf;
}

sub substr2($;$;$)
{
    my($string, $startoffset, $endoffset) = @_;
    return substr($string, $startoffset, $endoffset - $startoffset);
}

sub prefixQuoteJoin($,$)
{
    my($listref,$prefix) = @_;
    @list = @$listref;
    $result = "";
    foreach $i (@list) {
        $result .= " " . $prefix . quote($i);
    }
    return $result eq "" ? "" : substr($result, 1); # chop off leading space
}

# for substituteIntoTemplate()
sub getFromMapAsString($;$)
{
    my($mapref,$key) = @_;
    my %map = %$mapref;
    die("template error: undefined template parameter '$key'") if (!defined($map{$key}));
    return $map{$key};
}

# for substituteIntoTemplate()
sub getFromMapAsBool($;$)
{
    my($mapref,$key) = @_;
    my %map = %$mapref;
    die("template error: undefined template parameter '$key'") if (!defined($map{$key}));
    $value = $map{$key};
    die("template error: template parameter '$key' was expected to be a boolean, but it is \"$value\"") if ($value ne '' && $value ne '0' && $value ne '1');
    return $value;
}

#
# Converts absolute path $abs to relative path (relative to the current
# directory $cur), provided that both $abs and $cur are under a
# "project base directory" $base. Otherwise it returns the original path.
# All "\" are converted to "/".
#
sub abs2rel($;$;$;)
{
    my($abs, $base, $cur) = @_;

    if ($base eq '') {
        return $abs;
    }
    if ($cur eq '') {
        $cur = cwd;
    }

    # some normalization
    $abs  =~ s|\\|/|g;
    $cur  =~ s|\\|/|g;
    $base =~ s|\\|/|g;

    $abs  =~ s|/\./|/|g;
    $cur  =~ s|/\./|/|g;
    $base =~ s|/\./|/|g;

    $abs  =~ s|//+|/|g;
    $cur  =~ s|//+|/|g;
    $base =~ s|//+|/|g;

    $cur  =~ s|/*$|/|;
    $base =~ s|/*$|/|;

    if (!($abs =~ /^\Q$base\E/i && $cur =~ /^\Q$base\E/i)) {
        return $abs;
    }

    while (1)
    {
       # keep cutting off common prefixes until we can
       $abs =~ m|^(.*?/)|;
       my $prefix = $1;
       last if ($prefix eq '');
       if ($cur =~ /^\Q$prefix\E/i) {
           $abs =~ s/^\Q$prefix\E//i;
           $cur =~ s/^\Q$prefix\E//i;
       } else {
           last;
       }
    }


    # assemble relative path: change every directory name in $cur to "..",
    # then add $abs to it.
    $cur =~ s|[^/]+|..|g;
    my $rel = $cur.$abs;

    return $rel;
}


sub quote($)
{
    my($dir) = @_;
    if ($dir =~ / /) {$dir = "\"$dir\"";}
    return $dir;
}

sub readTextFile($)
{
    my($file) = @_;
    open(INFILE, $file) || die "cannot open $file";
    read(INFILE, $content, 1000000000) || die "cannot read $file";
    return $content;
}

sub error($)
{
    my($text) = @_;
    print STDERR "$progname: error: $text\n";
    exit(1);
}

sub warning($)
{
    my($text) = @_;
    print STDERR "$progname: warning: $text\n";
}

sub usage()
{
    print <<END
FIXME merge help text and options!
$progname: create MSVC makefile for an OMNeT++/OMNEST model, based on
source files in current directory

$progname [-h] [-f] [-e ext] [-o make-target] [-n] [-u user-interface]
              [-w] [-x] [-M] [-Idir] [-Ldir] [-llibrary] [-c configdir]
              [-i makefile-fragment-file]
              [directories, library and object files]...
    -h, --help            This help text
    -f, --force           Force overwriting existing Makefile
    -e ext, --ext ext     C++ source file extension, usually "cc" or "cpp".
                          By default, this is determined by looking at
                          existing files in the directory.
    -o filename, --outputfile filename
                          Name of simulation executable/library
    -r, --recurse         Call make recursively in all subdirectories. If you
                          need to maintain a specific order, declare dependen-
                          cies in the makefrag.vc file.
    -X directory, -Xdirectory, --except directory
                          With -r (recurse) option: ignore the given directory
    -b directory, --basedir directory
                          Project base (root) directory; all absolute paths
                          (-I, -L, object file names, etc.) which point into
                          this directory will be converted to relative, to
                          ease compiling the project in a different directory.
    -n, --nolink          Produce object files but do not create executable or
                          library. Useful for models with parts in several
                          directories. With this option, -u and -l have
                          no effect.
    -s, --make-so         Build a DLL. Useful if you want to load the
                          model dynamically (via the load-libs= omnetpp.ini or
                          the -l Cmdenv/Tkenv command-line option).
    -t library, --importlib library
                          With -t (build DLL) option: specifies an import
                          library for the DLL.
    -d, --fordll          Compile C++ files for use in DLLs (i.e. with the
                          WIN32_DLL symbol defined). The -s (build DLL) option
                          implies this one.
    -w, --withobjects     Link with all object files found in -I directories,
                          or include them if library is created. Ignored when
                          -n option is present. Dependencies between directo-
                          ries have be handled in high Makefiles (see -r
                          option).
    -x, --notstamp        Do not require a .tstamp file to be present in the
                          link directories and (if -w option is present)
                          -I directories after this option.
    -u name, --userinterface name
                          Use all, Cmdenv or Tkenv. Defaults to all.
    -Idir                 Additional NED and C++ include directory
    -Ldir                 Add a directory to the library path
    -llibrary             Additional library to link against
                          (e.g. -lmylibrary.lib)
    -P symbol, -Psymbol   -P option to be passed to opp_msgc
    -c filename, --configfile filename
                          Included config file (default:"../../configuser.vc")
    -i filename, --includefragment filename
                          Append file to near end of Makefile. The file
                          makefrag.vc (if exists) is appended automatically
                          if no -i options are given. This option is useful
                          if a source file (.ned, .msg or .cc) is to be
                          generated from other files.
    directory             Link with all object files in that directory.
                          Dependencies between directories have to be added
                          manually. See also -w option.
    library or object     Link with that file

Default output is Makefile.vc, which you can invoke by typing
  nmake -f Makefile.vc
With the -n and -s options, -u and -l have no effect. makefrag.vc (and the
-i option) is useful when a source file (.ned, .msg or .cc) is to be generated
from other files, or when you want to add extra dependencies that opp_makemake
could not figure out.
END
}

sub template()
{
    # NOTE: the following template must be kept in sync with the
    # "Makefile.TEMPLATE" file in the org.omnetpp.cdt plug-in!
    return <<'ENDTEMPLATE'
#
# OMNeT++/OMNEST Makefile for {target}
#
# This file was generated with the command:
#  {progname} {args}
#


# Name of target to be created (-o option)
TARGET = {target}

# User interface (uncomment one) (-u option)
{~allenv:#}USERIF_LIBS = $(TKENV_LIBS) $(CMDENV_LIBS)
{~cmdenv:#}USERIF_LIBS = $(CMDENV_LIBS)
{~tkenv:#}USERIF_LIBS = $(TKENV_LIBS)

# C++ include paths (with -I)
INCLUDE_PATH = {includepath}

# misc additional object and library files to link with
EXTRA_OBJS = {extraobjs}

# object files from other directories to link with
EXT_DIR_OBJS = {extdirobjs}

# time stamps of other directories (used as dependency)
EXT_DIR_TSTAMPS = {extdirtstamps}

# Additional libraries (-L, -l, -t options)
LIBS = {libpath}{libs}{importlibs}

#------------------------------------------------------------------------------

!include {configfile}

# User interface libs
CMDENV_LIBS = {-u}_cmdenv_lib {-l}envir{.lib} {-l}cmdenv{.lib}
TKENV_LIBS = {-u}_tkenv_lib {-l}envir{.lib} {-l}tkenv{.lib} {-l}layout{.lib} $(TK_LIBS) $(ZLIB_LIBS)

# Simulation kernel
KERNEL_LIBS = {-l}common{.lib} {-l}sim_std{.lib}

{nmake:}!if "$(WITH_NETBUILDER)"=="yes"
{~nmake:}ifeq($(WITH_NETBUILDER),yes)
KERNEL_LIBS = $(KERNEL_LIBS) {-l}nedxml{.lib} $(XML_LIBS)
{nmake:!}endif

{nmake:}!if "$(WITH_PARSIM)"=="yes"
{~nmake:}ifeq($(WITH_PARSIM),yes)
KERNEL_LIBS = $(KERNEL_LIBS) $(MPI_LIBS)
{nmake:!}endif

# Simulation kernel and user interface libraries
OMNETPP_LIBS = {-L}$(OMNETPP_LIB_DIR) $(USERIF_LIBS) $(KERNEL_LIBS) $(SYS_LIBS)

COPTS = $(CFLAGS) {fordllopt} $(INCLUDE_PATH) -I$(OMNETPP_INCL_DIR)
NEDCOPTS = $(COPTS) $(NEDCFLAGS)
MSGCOPTS = $(INCLUDE_PATH) {dllexportmacro}

#------------------------------------------------------------------------------
# object files in this directory
OBJS = {objs}

# subdirectories to recurse into
SUBDIRS = {subdirs}
{nmake:}SUBDIR_TARGETS = {subdirtargets}

{makefrags}

{exe:}$(TARGET): $(OBJS) $(EXTRA_OBJS) $(EXT_DIR_TSTAMPS) {hassubdir:subdirs} {makefile}
{exe:}	$(LINK) $(LDFLAGS) $(OBJS) $(EXTRA_OBJS) $(EXT_DIR_OBJS) $(LIBS) $(OMNETPP_LIBS) {link-o}$(TARGET)
{exe:}	echo{nmake:.} >.tstamp
{so:}$(TARGET): $(OBJS) $(EXTRA_OBJS) $(EXT_DIR_TSTAMPS) {hassubdir:subdirs} {makefile}
{so:}	$(SHLIB_LD) -o $(TARGET) $(OBJS) $(EXTRA_OBJS) $(EXT_DIR_OBJS)
{so:}	echo{nmake:.} >.tstamp
{nolink:}$(TARGET): $(OBJS) {hassubdir:subdirs} {makefile} .tstamp
{nolink:}	@{nmake:rem}{~nmake:#} Do nothing
{nolink:}
{nolink:}.tstamp: $(OBJS)
{nolink:}	echo{nmake:.} >.tstamp

subdirs: $(SUBDIR_TARGETS)

{subdirtargets}:
{~nmake:}	cd $@ && {makecommand}
{nmake:}	cd $(@:{_dir}=) && echo [Entering $(@:{_dir}=)] && {makecommand} && echo [Leaving $(@:{_dir}=)]

{nmake:}{msgccandhfiles} :: {msgfiles}
{~nmake:}%_m.{cc} %_m.h: %.msg
	$(MSGC{nmake::/=\}) -s _m.{cc} $(MSGCOPTS) $**

.SUFFIXES: .{cc}

.{cc}.obj:
	$(CXX) -c $(COPTS) {nmake:/Tp} $<

generateheaders: $(GENERATEDHEADERS)
{nmake:}	@if not "$(SUBDIRS)"=="" for %%i in ( $(SUBDIRS) ) do @cd %%i && echo [opp_msgc in %%i] && nmake /nologo /f Makefile.vc generateheaders && cd .. || exit /b 1
{~nmake:}	for i in $(SUBDIRS); do (cd \$\$i && \$(MAKE) generateheaders) || exit 1; done

clean:
{nmake:}	-del *.obj .tstamp *.idb *.pdb *.ilk *.exp $(TARGET) $(TARGET:.exe=.lib) $(TARGET:.dll=.lib) 2>NUL
{nmake:}	-del *_n.{cc} *_n.h *_m.{cc} *_m.h 2>NUL
{nmake:}	-del *.vec *.sca 2>NUL
{nmake:}	-if not "$(SUBDIRS)"=="" for %%i in ( $(SUBDIRS) ) do cd %%i && echo [clean in %%i] && nmake /nologo /f Makefile.vc clean && cd .. || exit /b 1
{~nmake:}	rm -f *.o *_n.{cc} *_n.h *_m.{cc} *_m.h .tstamp
{~nmake:}	rm -f *.vec *.sca
{~nmake:}	for i in $(SUBDIRS); do (cd $$i && $(MAKE) clean); done

depend:
	$(MAKEDEPEND) $(INCLUDE_PATH) -f Makefile.vc -- *.{cc}
{nmake:}	if not "$(SUBDIRS)"=="" for %%i in ( $(SUBDIRS) ) do cd %%i && echo [depend in %%i] && nmake /nologo /f Makefile.vc depend && cd .. || exit /b 1
{~nmake:}	for i in $(SUBDIRS); do (cd $$i && $(MAKE) depend) || exit 1; done

makefiles:
	{progname} {args}
{nmake:}	if not "$(SUBDIRS)"=="" for %%i in ( $(SUBDIRS) ) do cd %%i && echo [makemake in %%i] && nmake /nologo /f Makefile.vc makefiles && cd .. || exit /b 1
{~nmake:}	for i in $(SUBDIRS); do (cd $$i && $(MAKE) makefiles) || exit 1; done

# DO NOT DELETE THIS LINE -- make depend depends on it.
{deps}
ENDTEMPLATE
}
