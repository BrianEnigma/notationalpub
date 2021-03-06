#!/usr/bin/ruby
# vim:expandtab:shiftwidth=4:tabstop=4:smarttab:autoindent:smartindent
#
# notationalpub.rb, selectively publish Notational Velocity (et. al.) notes to the web.
#
# Copyright 2012 Brian Enigma <http://netninja.com>
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# 
# TODO: overview, usage info

##### Global variables for you to play with: #####

# Enable this to see what is happening.  Disable it to only print errors (which
# is useful/non-annoying if you have this running as a cron job).
$verbose=true

# This is where your notes reside.
$notes_folder       = File.expand_path("~/Dropbox/Elements/")

# This is where the HTML of your notes will get published
$html_folder        = File.expand_path("~/Sites/stackoverflow.org/notes/")

# Path to scp the files to.  Ideally, you'd have your public key set up
# on this server for passwordless uploading.  Leave blank to skip
# publishing and only write the notes to your html_folder.
$ssh_publish_path   = "briane@netninja.com:stackoverflow.org/notes/"

# Executable to call to convert markdown to HTML.  This script expects
# to pass the input filename as a parameter and get the HTML on stdout.
$markdown_app       = "multimarkdown"

##### No user-serviceable parts below this line #####

$dry_run            = false
$help               = false

class NotationalPub
    def initialize
        @note_list = Array.new
        @html_list = Array.new

        @private_note_list = Array.new
        @unknown_note_list = Array.new
    end

    def print_stats
        print "Found #{@note_list.count} public note#{@note_list.count == 1 ? '' : 's'}, "
        print "#{@private_note_list.count} private note#{@private_note_list.count == 1 ? '' : 's'}, "
        print "#{@unknown_note_list.count} unknown note#{@unknown_note_list.count == 1 ? '' : 's'}\n"
    end

    # Sanity-check the environment based on the settings we were given
    def validate_environment
        if !File.directory?($notes_folder)
            print "Unable to find notes folder #{$notes_folder}\n"
            return false
        end
        if !File.directory?($html_folder)
            print "Unable to find html folder #{$html_folder}\n"
            return false
        end
        md = `which #{$markdown_app}`
        if md.empty?
            print "Unable to find markdown app \"#{$markdown_app}\"\n"
            return false
        end
        if !$ssh_publish_path.empty?
            scp = `which scp`
            if scp.empty?
                print "SSH/SCP publish point given, but unable to find scp\n"
                return false
            end
        end
        return true
    end

    # Given a filename (fully-qualified path), check that it's a regular file
    # with a file extension and a "<public>" tag somewhere in there.
    def get_visibility(filename)
        # Filename must have a dot in it.  Fail otherwise.
        return false if filename.index('.') == nil
        # grep for "<public>"
        File.open(filename, "r").each_line { |line|
            return :public if line.index('<public>') != nil
            return :private if line.index('<private>') != nil
        }
        return :unknown
    end
    private :get_visibility

    # Locate note files with the "<public>" tag and store them in our
    # @note_list ivar.
    def find_notes
        begin
            print "Finding public notes...\n" if $verbose
            Dir.foreach($notes_folder) { |filename|
                full_filename = "#{$notes_folder}/#{filename}"
                next unless File.file?(full_filename)
                visibility = get_visibility(full_filename);
                @private_note_list << filename if :private == visibility
                @unknown_note_list << filename if :unknown == visibility
                next unless :public == visibility
                @note_list << full_filename
                print "  #{filename}\n" if $verbose
            }
        rescue
            print "Error reading folder #{$notes_folder}"
            return false
        end
        return true
    end

    def process_notes
        print "Generating HTML files...\n" if $verbose
        @note_list.each { |note|
            pos = note.rindex('.')
            # Based on is_public? rules, there MUST be an extension
            if pos == nil
                print "Error: file #{note} had no extension"
                return false
            end
            html = File.basename(note).sub(/\.[^\.]+/, ".html")
            html = "#{$html_folder}/" + html
            print "  #{File.basename(note)} => #{File.basename(html)}\n" if $verbose
            escaped1 = note.gsub(/'/, "\\'")
            escaped2 = html.gsub(/'/, "\\'")
            # Start out with some basic HTML5 front matter
            f = File.new(html, "w")
            f.print("<!DOCTYPE html>\n<html><head><title>#{File.basename(html)}</title></head><body>\n");
            f.close
            command = "#{$markdown_app} '#{escaped1}' | sed 's/<public>//g' >> '#{escaped2}'"
            #print "#{command}\n"
            if !system(command)
                print "Error running command: #{command}\n"
                return false
            end
            rc = $?
            if rc != 0
                print "Error running command (returned #{rc}): #{command}\n"
                return false
            end
            f = File.new(html, "a")
            # Close off the HTML5 opening tags
            f.print("</body></html>")
            f.close
        }
    end

    def print_unknown_notes
        return true if @unknown_note_list.empty?
        print "Notes with unknown visibility (assuming private):\n"
        @unknown_note_list.sort!
        @unknown_note_list.each { |item| print "  #{item}\n" }
        return true
    end

    def publish_notes
        return true if $ssh_publish_path.empty?
    end

end # class NotationalPub

# Keeping this simple and braindead to avoid pulling in gems and the getopt gem
ARGV.each { |arg|
    $dry_run = true if arg == "-d" #dry run
    $dry_run = true if arg == "-t" #test run
    $help = true if arg == '-h'
    $help = true if arg == '--help'
    $help = true if arg == '-v'
    $help = true if arg == '-V'
    $help = true if arg == '--version'
    $verbose = false if arg = '-q'
}

if true == $help
    print "./notationalpub.rb [-d][-t][-q]\n"
    print "\n"
    print "-d and -t do the same thing and stand for \"dry run\" and \"test\" respectively.\n"
    print "They scan your notes database and give you stats about public/private/untagged\n"
    print "without actually creating HTML or syncing.\n"
    print "\n"
    print "-q quiets the output. This is good to prevent spammy updates if running\n"
    print "frequently from a cron job.\n"
    exit 1
end

$verbose = false if $dry_run
np = NotationalPub.new
exit 1 unless np.validate_environment
exit 1 unless np.find_notes
$verbose = true if $dry_run
np.print_stats if true == $verbose
exit 1 unless np.print_unknown_notes
if (true != $dry_run)
    exit 1 unless np.process_notes
    exit 1 unless np.publish_notes
    print "Finished successfully!\n" if $verbose
end


