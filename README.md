# Maven Artifact Version Bumper

A simple GitHub Actions to bump the version of Maven projects.

When triggered, this action will look at the commit message of HEAD~1 and determine if it contains one of `#major` or `#minor` (in that order of precedence).
If true, it will use Maven to bump your pom's version by the X.x.x major or x.X.x minor version respectively. All other commits will cause a bump in the x.x.X patch version.

For example, a `#minor` update to version `1.3.9` will result in the version changing to `1.4.0`.
The change will then be committed.

## New features provided by this fork
This action behaves very different from upstream forks!
This action preserves Pre-Release labels, such as -SNAPSHOT.
This action implements 2 different versioning strategies, one for services and another for dependencies.
It requires 'artifact-type' input param, which can be 'service' or 'dependency'. 
**Service**
Services are tagged with the old version.
Then their version is bumped in a new commit.
**Dependency**
Dependency versions are not bumped.
Tags are updated to point to the latest commit.

Finally. since unlabelled commits defaut to a patch version bump, 'read-only' option has been added, replacing 'BUMP_MODE' of 'none'.
The initial bump from the previous release is expected to have been done by the maven release:branch or manually by the developer. 
## Sample Usage

```yaml
name: Artifact Snapshot Build and Deploy to CodeArtifact
on:
  push:
    branches-ignore:
      - master
jobs:
  build-artifact:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout Repo
      uses: actions/checkout@v3
      with:
        set-safe-directory: /github/workspace
    - name: Get Latest in case of re-run
      run: git pull
    - name: Set up JDK 8
      uses: actions/setup-java@v3
      with:
        java-version: '8.0.232'
        distribution: 'adopt'
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    - name: aws-codeartifact-mvn-login
      uses: Fred78290/aws-codeartifact-mvn-login@v1.0.6
      with:
        repo-name: my-snapshots
        repo-domain: my-domain
        account-number: 123456789
    - name: Build and Deploy
      run: mvn --batch-mode --update-snapshots package deploy
    - name: Bump Version
      id: bump
      uses: cfedersp/maven-version-bump-action@master
      with:
        artifact-type: dependency
        github-token: ${{ secrets.github_token }}
    - name: Print Version
      run: "echo 'New Version: ${{steps.bump.outputs.version}}'"
```

## Supported Arguments

* 'read-only': Provides the current version as an output without changing the pom or tagging the repo.
* 'artifact-type': Required. Can be 'dependency' or 'service'. Dependencies have their latest commits tagged, but not bumped. Services are tagged with the old version and are bumped in a separate commit.
* `github-token`: Required. Can either be the default token, as seen above, or a personal access token with write access to the repository
* `git-email`: The email address each commit should be associated with. Defaults to a github provided noreply address
* `git-username`: The GitHub username each commit should be associated with. Defaults to `github-actions[bot]`
* `pom-path`: The path within your directory the pom.xml you intended to change is located.

## Outputs

* `version` - The after-bump version. Will return the old version if bump was not necessary.
