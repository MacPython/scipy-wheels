###################################
Building and uploading scipy wheels
###################################

We automate wheel building using this custom github repository that builds on
Azure DevOps for Linux and macOS, on AppVeyor for Windows, and on TravisCI
for ``aarch64`` (64-bit ARM).

The travis-ci interface for the builds is
https://travis-ci.com/github/MacPython/scipy-wheels

Appveyor interface at
https://ci.appveyor.com/project/scipy/scipy-wheels

Azure interface at (not a typo, it got migrated to the NumPy org - we may
want to migrage it to the SciPy Azure DevOps org in the future):
https://dev.azure.com/numpy/numpy/_build?definitionId=9

The driving github repository is
https://github.com/MacPython/scipy-wheels

Using the repository
====================

The repository contains the branches:

* ``master`` - for development and daily builds;
* ``vx.y.z`` - for building releases.

Travis-CI and Appveyor builds the ``master`` regularly (daily/weekly),
merges to master. and Appveyor builds the ``master`` regularly (daily/weekly),
via `Travis-CI cron jobs
<https://docs.travis-ci.com/user/cron-jobs/>`_ and `Appveyor scheduled
builds
<https://www.appveyor.com/docs/build-configuration/#scheduled-builds>`.

At the time of writing, we currently only do weekly builds for Linux/MacOS
(Travis CI), and not for Windows (Appveyor).

Weekly wheel builds are uploaded to:
https://anaconda.org/scipy-wheels-nightly/scipy/files

When a PR is merged into ``master`` branch or one of the release feature
branches, the wheel artifacts are uploaded to a staging area:
https://anaconda.org/multibuild-wheels-staging/scipy/files

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
* uploads the built wheels to a Anaconda Cloud container - see "Using the
  repository" above.  The containers were kindly given expanded storage by
  the Anaconda team.

The resulting wheels are therefore self-contained and do not need any external
dynamic libraries apart from those provided as standard by OSX / Linux as
defined by the manylinux1 standard.

Both Appveyor and Travis CI are using secret/encrypted keys to provide
Anaconda Cloud upload credentials for merged PRs and weekly builds. The keys
are provided by Anaconda Cloud, and can be pasted direclty into the settings
for secret keys for Travis CI and Appveyor.

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

* all pre-release wheel assets are stored in the Anaconda Cloud staging area:
  https://anaconda.org/multibuild-wheels-staging/scipy/files

Note that some other wheels are also stored here--those from any merged PRs
to the wheels repo (``master`` or release feature branch).

When the wheels are updated, you can download them to your machine manually,
or use a ``download-wheels.py`` tool in the main SciPy repo, like this:

``python tools/download-wheels.py 1.5.0rc1 -w $REPO_ROOT/release/installers/``

and then upload them manually to pypi, or by using twine_.

Of course, you will need permissions to upload to PyPI, for this to work.

.. _manylinux1: https://www.python.org/dev/peps/pep-0513
.. _twine: https://pypi.python.org/pypi/twine
.. _delocate: https://pypi.python.org/pypi/delocate
.. _auditwheel: https://pypi.python.org/pypi/auditwheel
