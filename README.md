# NAME

Net::NodeTransformator - interface to node transformator

# VERSION

Version 0.100

# DESCRIPTION

This module is an interface to the transformator package of nodejs. See [https://www.npmjs.org/package/transformator](https://www.npmjs.org/package/transformator) for more information about the server.

When it's difficult for perl to interact with various nodejs packages, the transformator protocol allows everyone to interact with an nodejs service. transformator supports a vast range of libraries like jade-lang, sass-lang or coffeescript.

The other way is to invoke each command-line tool as a child process, but this may be very inefficient if such tool need to be called frequently.

# AUTHOR

David Zurborg, `<zurborg@cpan.org>`

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::NodeTransformator

You can also look for information at:

- GitHub: Public repository of this module

    [https://github.com/zurborg/libnet-nodetransformator-perl](https://github.com/zurborg/libnet-nodetransformator-perl)

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-NodeTransformator](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-NodeTransformator)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Net-NodeTransformator](http://annocpan.org/dist/Net-NodeTransformator)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Net-NodeTransformator](http://cpanratings.perl.org/d/Net-NodeTransformator)

- Search CPAN

    [http://search.cpan.org/dist/Net-NodeTransformator/](http://search.cpan.org/dist/Net-NodeTransformator/)

# COPYRIGHT & LICENSE

Copyright 2014 David Zurborg, all rights reserved.

This program is released under the ISC license.
