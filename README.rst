###################################
Building and uploading scipy wheels
###################################

We automate wheel building using this custom github repository that builds on
the travis-ci OSX machines and the travis-ci Linux machines.

The travis-ci interface for the builds is
https://travis-ci.org/MacPython/scipy-wheels

Appveyor interface at
https://ci.appveyor.com/project/scipy/scipy-wheels

The driving github repository is
https://github.com/MacPython/scipy-wheels

Using the repository
====================

The repository contains the branches:

* ``master`` - for development and daily builds;
* ``vx.y.z`` - for building releases.

Travis-CI and Appveyor builds the ``master`` regularly (daily/weekly),
via `Travis-CI cron jobs
<https://docs.travis-ci.com/user/cron-jobs/>`_ and `Appveyor scheduled
builds
<https://www.appveyor.com/docs/build-configuration/#scheduled-builds>`.

Builds from the ``master`` branch upload to a Rackspace container for
pre-releases at
https://7933911d6844c6c53a7d-47bd50c35cd79bd838daf386af554a83.ssl.cf2.rackcdn.com

Builds from the release branches upload to a Rackspace container for releases
at
https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com

Pull requests should usually be submitted to the ``master`` branch.

How it works
============

The wheel-building repository:

* does a fresh build of any required C / C++ libraries;
* builds a scipy wheel, linking against these fresh builds;
* processes the wheel using delocate_ (OSX) or auditwheel_ ``repair``
  (Manylinux1_).  ``delocate`` and ``auditwheel`` copy the required dynamic
  libraries into the wheel and relinks the extension modules against the
  copied libraries;
* uploads the built wheels to a Rackspace container - see "Using the
  repository" above.  The containers were kindly donated by Rackspace to
  scikit-learn).

The resulting wheels are therefore self-contained and do not need any external
dynamic libraries apart from those provided as standard by OSX / Linux as
defined by the manylinux1 standard.

The ``.travis.yml`` file in this repository has a line containing the API key
for the Rackspace container encrypted with an RSA key that is unique to the
repository - see https://docs.travis-ci.com/user/encryption-keys.  This
encrypted key gives the travis build permission to upload to the Rackspace
containers we use to house the uploads.

Triggering a build
==================

You will likely want to edit the ``.travis.yml`` and ``appveyor.yml`` files to
specify the ``BUILD_COMMIT`` before triggering a build - see below.

For releases, use an existing release branch, or push a new release
branch to the repository.

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
``BUILD_COMMIT`` at the top of the ``.travis.yml`` file and ``appveyor.yml``
files.  This can be any naming of a commit, including branch name, tag name or
commit hash.

Note: when making a SciPy release, it's best to only push the commit (not the
tag) of the release to the ``scipy`` repo, then change ``BUILD_COMMIT`` to the
commit hash, and only after all wheel builds completed successfully push the
release tag to the repo.  This avoids having to move or delete the tag in case
of an unexpected build/test issue.

Uploading the built wheels to pypi
==================================

* pre-releases container visible at
  https://7933911d6844c6c53a7d-47bd50c35cd79bd838daf386af554a83.ssl.cf2.rackcdn.com
* release container visible at
  https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com

Be careful, these links point to containers on a distributed content delivery
network.  It can take up to 15 minutes for the new wheel file to get updated
into the containers at the links above.

When the wheels are updated, you can download them to your machine manually,
and then upload them manually to pypi, or by using twine_.  You can also use a
script for doing this, housed at :
https://github.com/MacPython/terryfy/blob/master/wheel-uploader

For the ``wheel-uploader`` script, you'll need twine and `beautiful soup 4
<bs4>`_.

You will typically have a directory on your machine where you store wheels,
called a `wheelhouse`.   The typical call for `wheel-uploader` would then
be something like::

    VERSION=0.18.0
    CDN_URL=https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com
    wheel-uploader -u $CDN_URL -s -v -w ~/wheelhouse -t all scipy $VERSION

where:

* ``-u`` gives the URL from which to fetch the wheels, here the https address,
  for some extra security;
* ``-s`` causes twine to sign the wheels with your GPG key;
* ``-v`` means give verbose messages;
* ``-w ~/wheelhouse`` means download the wheels from to the local directory
  ``~/wheelhouse``.

``scipy`` is the root name of the wheel(s) to download / upload, and
``0.18.0`` is the version to download / upload.

In order to upload the wheels, you will need something like this
in your ``~/.pypirc`` file::

    [distutils]
    index-servers =
        pypi

    [pypi]
    username:your_user_name
    password:your_password

So, in this case, `wheel-uploader` will download all wheels starting with
`scipy-0.18.0-` from the URL in ``$CDN_URL`` above to ``~/wheelhouse``, then
upload them to PyPI.

Of course, you will need permissions to upload to PyPI, for this to work.

.. _manylinux1: https://www.python.org/dev/peps/pep-0513
.. _twine: https://pypi.python.org/pypi/twine
.. _bs4: https://pypi.python.org/pypi/beautifulsoup4
.. _delocate: https://pypi.python.org/pypi/delocate
.. _auditwheel: https://pypi.python.org/pypi/auditwheel
