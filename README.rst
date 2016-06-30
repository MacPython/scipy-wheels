###################################
Building and uploading scipy wheels
###################################

We automate wheel building using this custom github repository that builds on
the travis-ci OSX machines, travis-ci Linux machines, and the Appveyor VMs.

The travis-ci interface for the builds is
https://travis-ci.org/MacPython/scipy-wheels

The driving github repository is
https://github.com/MacPython/scipy-wheels

How it works
============

The wheel-building repository:

* does a fresh build of any required C / C++ libraries;
* builds a scipy wheel, linking against these fresh builds;
* processes the wheel using delocate_ (OSX) or auditwheel_ ``repair``
  (Manylinux1_).  ``delocate`` and ``auditwheel`` copy the required dynamic
  libraries into the wheel and relinks the extension modules against the
  copied libraries;
* uploads the built wheels to http://wheels.scipy.org (a Rackspace container
  kindly donated by Rackspace to scikit-learn).

The resulting wheels are therefore self-contained and do not need any external
dynamic libraries apart from those provided as standard by OSX / Linux as
defined by the manylinux standard.

The ``.travis.yml`` file in this repository has a line containing the API key
for the Rackspace container encrypted with an RSA key that is unique to the
repository - see http://docs.travis-ci.com/user/encryption-keys.  This
encrypted key gives the travis build permission to upload to the Rackspace
directory pointed to by http://wheels.scipy.org.

Triggering a build
==================

You will likely want to edit the ``.travis.yml`` file to specify the
``BUILD_COMMIT`` before triggering a build - see below.

You will need write permission to the github repository to trigger new builds
on the travis-ci interface.  Contact us on the mailing list if you need this.

You can trigger a build by:

* making a commit to the `scipy-wheels` repository (e.g. with `git
  commit --allow-empty`); or
* clicking on the circular arrow icon towards the top right of the travis-ci
  page, to rerun the previous build.

In general, it is better to trigger a build with a commit, because this makes
a new set of build products and logs, keeping the old ones for reference.
Keeping the old build logs helps us keep track of previous problems and
successful builds.

Which scipy commit does the repository build?
===============================================

The `scipy-wheels` repository will build the commit specified in the
``BUILD_COMMIT`` at the top of the ``.travis.yml`` file.  This can be any
naming of a commit, including branch name, tag name or commit hash.

Uploading the built wheels to pypi
==================================

Be careful, http://wheels.scipy.org points to a container on a distributed
content delivery network.  It can take up to 15 minutes for the new wheel file
to get updated into the container at http://wheels.scipy.org.

The same contents appear at
https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com;
you might prefer this address because it is https.

When the wheels are updated, you can download them to your machine manually,
and then upload them manually to pypi, or by using twine_.  You can also use a
script for doing this, housed at :
https://github.com/MacPython/terryfy/blob/master/wheel-uploader

For the ``wheel-uploader`` script, you'll need twine and `beautiful soup 4
<bs4>`_.

You will typically have a directory on your machine where you store wheels,
called a `wheelhouse`.   The typical call for `wheel-uploader` would then
be something like::

    CDN_URL=https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com
    wheel-uploader -r warehouse -v -w ~/wheelhouse -t macosx scipy 0.18.0
    wheel-uploader -r warehouse -v -w ~/wheelhouse -t manylinux1 scipy 0.18.0

where:

* ``-v`` means give verbose messages;
* ``-w ~/wheelhouse`` means download the wheels from https://wheels.scipy.org
  to the directory ``~/wheelhouse``;
* ``-r warehouse`` uses the upcoming Warehouse PyPI server (it is more
  reliable than the current PyPI service for uploads);
* `scipy` is the root name of the wheel(s) to download / upload;
* `0.18.0` is the version to download / upload.

In order to use the Warehouse PyPI server, you will need something like this
in your ``~/.pypirc`` file::

    [distutils]
    index-servers =
        pypi
        warehouse

    [pypi]
    username:your_user_name
    password:your_password

    [warehouse]
    repository: https://upload.pypi.io/legacy/
    username: your_user_name
    password: your_password

So, in this case, `wheel-uploader` will download all wheels starting with
`scipy-0.18.0-` from http://wheels.scipy.org to `~/wheelhouse`, then upload
them to pypi.

Of course, you will need permissions to upload to PyPI, for this to work.

.. _manylinux1: https://www.python.org/dev/peps/pep-0513
.. _twine: https://pypi.python.org/pypi/twine
.. _bs4: https://pypi.python.org/pypi/beautifulsoup4
.. _delocate: https://pypi.python.org/pypi/delocate
.. _auditwheel: https://pypi.python.org/pypi/auditwheel
