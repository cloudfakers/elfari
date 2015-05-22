# ElFari
## What is this?

Just what the world needs, an IRC bot. A quite clumsy one.

## What does?

Very little indeed. Mostly annoy people by playing music from youtube and shouting out loud crappy jokes (Spanish) in the office. Sometimes also annoy people on Twitter.

## Installation

[VLC](http://www.videolan.org) is the preferred player.

Look for installers in releases page. Then use those if you prefer an easy way to install this software. Bear in mind this disclaimer:

`This is just a pet project to provide some kind of "jukebox" to the office.`

Installers leave the app in `/opt/elfari`. If you choose `VLC` all you have to do is `sudo /opt/elfari/bin/elfari`. It currently needs `sudo privileges`.

```
sudo /opt/elfari/bin/elfari
```

It comes with sensible defaults for a `VLC` player integration and `*nix`.

```
git clone git@github.com:ssedano/elfari

cd elfari && bundle install

ruby elfari.rb
```

Tune `config/config.yml` file and run either the `run.sh` or `elfari.rb`.

## Configuration

Recommended line to launch `VLC`:

```
vlc -vvv --ignore-config -I lua --lua-intf cli --no-video --lua-config "rc={host='0.0.0.0:4000',flatplaylist=0}"
```

## Note on players

There are three supported players:

* MPlayer (does not support native streaming).
* VLC (When streaming, and duplicating the channel to local the volume is desactivated).
* MPD (Playing some flv from youtube a few songs won't start playing due to a bad choice of decoder plugin made by MPD. Even a fewer number MPD will try to format them to whatever the value is set in your config thus incurring in several <i>ALSA underrun on device </i> which outputs a very unpleasant noise).

## Commands

The most rewarding ones are:

* aluego some crappy song
- Queries youtube API for videos containing the terms "some crappy song". Then it simply adds to the playlist the first one.

* ponme er some crappy song
- Plays, if any, a song which title contains the terms "some crappy song".

* ponme argo
- Plays a random song from the database

* apunta http://youtu.be/video
- Adds that crappy song that you love to the song database

* genardo dice here comes a tweet
- Tweet using the credentials the status "here comes a tweet".

* genardo alecciona
- This command accepts parameters. Search for a tweet with the parameters (if no parameters, just any tweet), sends its words to [After the Deadline](http://www.afterthedeadline.com/api.slp) Spell Checker API, substitute all coincidences with the first correction, then sends the corrected tweet to its original author. Note that here I use the term "corrected" very lightly, most of the times it just fails miserably correcting it.

## Troubleshooting

Every now and then `youtube downloader` need to be updated. Do so by issuing this command (\*NIX):

```
sudo youtube-dl -U
```

`VLC` can also be launched in a console and `ElFari` will connect to it instead of starting an instance. This is useful to see the output of `VLC`.

If this amazing piece of software feels like hanged it is obviously your fault. You forgot, most likely, to kindly indicate the path to the `VLC` binary (in the `config/config.yml` file).

## License

The original project (which I owe a PR) was created by [rubiojr](https://github.com/rubiojr).

His work has his license. Mine is under the [Beerware License](http://en.wikipedia.org/wiki/Beerware).

