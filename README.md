#NotationalPub

##Status

NOTE THAT THIS PROJECT IS NOT YET FINISHED.  IT IS NOT EVEN BETA YET.  ITEMS
LEFT TO DO INCLUDE:

 - Finish scp publishing (or rsync syncing?).  Files get published to the
   local directory, but not to remote servers, regardless of the script
   configuration.
 - More/better/complete documentation.
 - Include a basic html (actually, PHP) file to show a catalog of notes and
   include a (Google?) searchbox.

[MultiMarkdown]: http://fletcherpenney.net/multimarkdown/

##Overview

notationalpub.rb: selectively publish Notational Velocity (et. al.) notes to
the web.

Do you store your notes as text files in a Dropbox folder?  Do you want to
selectively publish some of them to the web?  NotationalPub is a tool that 
lets you tag specific notes in your [Dropbox]/[Notational Velocity]/[nvAlt]/[Elements]
note taking app.  The tagged notes are converted, via [Markdown], to HTML and
stored in a local folder.  Optionally, they are then synced to a remote
web server.

[Dropbox]: https://www.dropbox.com/
[Elements]: http://www.secondgearsoftware.com/elements/
[nvAlt]: http://brettterpstra.com/project/nvalt/
[Notational Velocity]: http://notational.net/
[notes]: http://netninja.com/2011/05/03/trunk-notes-lookups-from-the-desktop/
[Markdown]: http://daringfireball.net/projects/markdown/

##Background

Last week on Twitter, stevenf of Panic [announced][tweet] a little project he
put together.  His [notes][noteswebapp] app lets him share all of the little
snippets of code,  shell scripts, and whatnot he kept finding himself needing
to refer back to.  He implemented this as a separate (public) note database
from the (private) one he typically uses for other notes.  This was mainly
because he never found a note-taking/searching/publishing tool he liked that
had a clear separation of public versus private.

[tweet]: http://twitter.com/stevenf/status/159776472557559808
[noteswebapp]: http://stevenf.com/notes/

I have been doing a similar thing for a few years.  I run wiki, for which I am
the only user, (<http://stackoverflow.org/wiki/>) for the public stuff.  I keep
the private stuff as text files on [Dropbox], accessed via [Elements], the
[nvAlt] variant of [Notational Velocity], and my own [notes] searching app for
Linux.  The problem here is that I never know where to find something.  Do I
search the wiki or the Dropbox note store?  When I write a new note, which tool
do I use?

What I found I really wanted was a way to just tag certain notes as "public"
and let those, and only those, get published.  There does not seem to be an
existing tool to do this, so I decided to write my own.  This is that tool.

##Usage

### Step 0

Configure NotaionalPub.  Edit notationalpub.rb in your favorite text editor
and set the paths to your Dropbox folder, your HTML folder, and optionally
a remote ssh/scp location.  Ideally, you would also [set up ssh keys][keys]
so that you would not have to type your password every time.

[keys]: https://www.google.com/search?q=how+to+set+up+ssh+keys

### Step 1

Write your notes.  These are a collection of text, preferably [Markdown],
files.

### Step 2

The notes you would like to make public, put the following literal text in
them:

    <public>

This is the same Markdown syntax as a "bare" URL, for example if I wanted to
link to my site, I would write \<http://netninja.com\>.  Think of this as a
URL stating that this note is public.  I tend to put this as the last line
in the file, but it will be found anywhere in the file.

### Step 3

Run notationalpub.rb

### Step Later

After you have run this manually a few times, you may consider [adding the
script to your crontab][crontab].

[crontab]: https://www.google.com/search?q=how+to+set+up+a+crontab

