CoTweet Exporter
================

[CoTweet Standard Edition](http://standard.cotweet.com/), a Twitter client for businesses,
is being [shut down](http://pages.exacttarget.com/socialengagefaq) on 15 February 2012.

Irritatingly, CoTweet [are not providing](https://twitter.com/cotweet/status/165208168912261120)
a way to export the data from your account. (Not cool, if you ask me.) This little Ruby
application fills that gap.


Features
--------

* Download the entire contents of your inbox, sent folder and archived messages folder
  to JSON files on your disk.
* For every Twitter user you've communicated with, dumps the conversation history
  with that user. (This is CoTweet's best feature, because you can avoid getting
  embarrassed by saying the same thing again to the same person.)
* ROFLscale concurrency using asynchronous network I/O. (Not that it was needed, of
  course -- I just felt like writing it with
  [em-http-request](https://github.com/igrigorik/em-http-request) and
  [DG](https://github.com/samstokes/deferrable_gratification).)
* Automatic retry of failed requests, to cope with CoTweet's loltastic API.

The JSON files are in the schema used by CoTweet's internal API. They are not documented,
but the format is pretty self-explanatory.

To my knowledge, there aren't yet any tools to import this data (though of course you can
grep through it if you need to). Let me know if you write something that uses the data.


Usage
-----

    $ git clone https://github.com/ept/cotweet-export.git && cd cotweet-export
    $ gem install bundler && bundle install
    $ mkdir conversations
    $ bin/cotweet-export

Tested with Ruby 1.9.2.


License
-------

MIT License (see LICENSE).

Patches and pull requests welcome.
